class Redhouse
  def self.configure(config, settings)
    config.vm.box = 'mrkcor/redhouse'
    config.vm.hostname = settings['hostname'] || 'redhouse'
    config.ssh.forward_agent = true
    config.vm.network :private_network, ip: settings['ip'] ||= '192.168.10.42'

    # Configure Local Variable To Access Scripts From Remote Location
    script_dir = File.dirname(__FILE__)

    config.vm.provider 'virtualbox' do |vb|
      vb.customize ['modifyvm', :id, '--memory', settings['memory'] ||= '2048']
      vb.customize ['modifyvm', :id, '--cpus', settings['cpus'] ||= '2']
      vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
      vb.customize ['modifyvm', :id, '--natdnshostresolver1', settings['natdnshostresolver'] ||= 'on']
      vb.customize ['modifyvm', :id, '--ostype', 'Ubuntu_64']
      vb.customize ['guestproperty', 'set', :id, '--timesync-threshold', 5000]
    end

    if settings.include? 'authorize'
      if File.exist? File.expand_path(settings['authorize'])
        config.vm.provision 'shell' do |s|
          s.inline = "echo $1 | grep -xq \"$1\" /home/vagrant/.ssh/authorized_keys || echo \"\n$1\" | tee -a /home/vagrant/.ssh/authorized_keys"
          s.args = [File.read(File.expand_path(settings['authorize']))]
        end
      end
    end

    if settings.include? 'ssh_port_forwards'
      ssh_extra_args = []

      settings['ssh_port_forwards'].each do |ssh_port_forward|
        ssh_port_forward_type = ssh_port_forward['direction'] || 'host'
        guest_port            = ssh_port_forward['guest_port'] || ssh_port_forward['port']
        host_hostname         = ssh_port_forward['host_name'] || 'localhost'
        host_port             = ssh_port_forward['host_port'] || ssh_port_forward['port']

        ssh_extra_args << '-R' if ssh_port_forward_type == 'host'
        ssh_extra_args << '-L' if ssh_port_forward_type != 'host'
        ssh_extra_args << "#{guest_port}:#{host_hostname}:#{host_port}"
      end

      config.ssh.extra_args = ssh_extra_args
    end

    if settings.include? 'key_scan'
      settings['key_scan'].each do |hostname|
        config.vm.provision 'shell' do |s|
          s.inline = "su -c 'ssh-keyscan #{hostname} >> ~/.ssh/known_hosts' vagrant"
        end
      end
    end

    if settings.include? 'projects'
      projects_root = nil
      if settings.include? 'projects_root'
        projects_root = settings['projects_root']
        projects_root = "#{projects_root}/" unless projects_root.end_with?('/')
      end

      sources = settings['sources'] || {}

      settings['projects'].each do |project|
        source, _ = sources.find { |name, source| project.keys.include?(name) }
        git = project['git']
        git = "#{sources[source]}:#{project[source]}" if source
        project_folder = project['folder']
        project_folder = "#{projects_root}#{project_folder}" unless project_folder.nil? || project_folder.start_with?('/')
        project_folder ||= "#{projects_root}#{project[source]}" if source
        next unless project_folder

        config.vm.provision 'shell' do |s|
          s.inline = "mkdir -p $(dirname #{project_folder}) && chown -R vagrant:vagrant $(dirname #{project_folder}) && cd $(dirname #{project_folder}) && if [ ! -d #{project_folder} ]; then su -c 'git clone #{git}' vagrant; else su -c 'cd #{project_folder} && git pull' vagrant ;fi"
        end
      end
    end

    default_folder_options = settings['folder_defaults'] || {}

    # Register All Of The Configured Shared Folders
    if settings.include? 'folders'
      settings['folders'].each do |folder|
        folder = default_folder_options.merge(folder)
        if File.exist? File.expand_path(folder['map'])
          mount_opts = []

          if folder['type'] == 'nfs'
            mount_opts = folder['mount_options'] ? folder['mount_options'] : ['actimeo=1', 'nolock']
          elsif folder['type'] == 'smb'
            mount_opts = folder['mount_options'] ? folder['mount_options'] : ['vers=3.02', 'mfsymlinks']

            smb_creds = {smb_host: folder['smb_host'], smb_username: folder['smb_username'], smb_password: folder['smb_password']}
          end

          # For b/w compatibility keep separate 'mount_opts', but merge with options
          options = (folder['options'] || {}).merge({mount_options: mount_opts}).merge(smb_creds || {})

          # Double-splat (**) operator only works with symbol keys, so convert
          options.keys.each { |k| options[k.to_sym] = options.delete(k) }

          config.vm.synced_folder folder['map'], folder['to'], type: folder['type'] ||= nil, **options

          # Bindfs support to fix shared folder (NFS) permission issue on Mac
          if folder['type'] == 'nfs' && Vagrant.has_plugin?('vagrant-bindfs')
            config.bindfs.bind_folder folder['to'], folder['to']
          end
        else
          config.vm.provision 'shell' do |s|
            s.inline = ">&2 echo \"Unable to mount one of your folders. Please check your folders in redhouse.yaml\""
          end
        end
      end
    end

    # Configure shell
    config.vm.provision 'shell' do |s|
      s.path = script_dir + '/shell.sh'
    end

    # Clear any redhouse sites and insert markers in /etc/hosts
    config.vm.provision 'shell' do |s|
      s.path = script_dir + '/hosts-reset.sh'
    end

    # Create the virtual machine's root certificate and copy it to the /vagrant directory so you can import it later on
    config.vm.provision 'shell', path: script_dir + '/create-root-certificate.sh'

    # Install All The Configured Nginx Sites
    if settings.include? 'sites'
      domains = []

      sites_root = nil
      if settings.include? 'sites_root'
        sites_root = settings['sites_root']
        sites_root = "#{sites_root}/" unless sites_root.end_with?('/')
      end

      settings['sites'].each do |site|
        domains.push(site['map'])

        # Create SSL certificate
        config.vm.provision 'shell' do |s|
          s.name = 'Creating Certificate: ' + site['map']
          s.path = script_dir + '/create-certificate.sh'
          s.args = [site['map']]
        end

        type = site['type'] ||= 'rails'
        port = '3000'

        config.vm.provision 'shell' do |s|
          s.name = 'Creating Site: ' + site['map']

          # Convert the site & any options to an array of arguments passed to the
          # specific site type script (defaults to rails)
          s.path = script_dir + "/site-types/#{type}.sh"
          s.args = [
              site['map'], # $1
              "#{sites_root}#{site['to']}", # $2
              site['port'] ||= port, # $3
          ]
        end

        site['ruby'] ||= '2.7.2'
        config.vm.provision 'shell', path: script_dir + '/install-ruby.sh', args: [site['ruby']]

        config.vm.provision 'shell' do |s|
          s.path = script_dir + "/hosts-add.sh"
          s.args = ['127.0.0.1', site['map']]
        end

        # Configure The Cron Schedule
        if site.has_key?('schedule')
          config.vm.provision 'shell' do |s|
            s.name = 'Creating Schedule'

            if site['schedule']
              s.path = script_dir + '/cron-schedule.sh'
              s.args = [site['map'].tr('^A-Za-z0-9', ''), site['to']]
            else
              s.inline = "rm -f /etc/cron.d/$1"
              s.args = [site['map'].tr('^A-Za-z0-9', '')]
            end
          end
        else
          config.vm.provision 'shell' do |s|
            s.name = 'Checking for old Schedule'
            s.inline = "rm -f /etc/cron.d/$1"
            s.args = [site['map'].tr('^A-Za-z0-9', '')]
          end
        end
      end
    end

    config.vm.provision 'shell' do |s|
      s.name = 'Restarting Cron'
      s.inline = 'sudo service cron restart'
    end

    config.vm.provision 'shell' do |s|
      s.name = 'Restarting Nginx'
      s.inline = 'sudo service nginx restart'
    end

    # Configure All Of The Configured Databases
    if settings.has_key?('databases')
      # Check which databases are enabled
      settings['databases'].each do |db|
        config.vm.provision 'shell' do |s|
          s.name = 'Creating Postgres Database: ' + db
          s.path = script_dir + '/create-postgres.sh'
          s.args = [db]
        end
      end
    end
  end
end
