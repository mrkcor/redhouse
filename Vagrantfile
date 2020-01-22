# -*- mode: ruby -*-
# vi: set ft=ruby :

base_dir = File.expand_path(File.dirname(__FILE__))

require 'yaml'
require base_dir + '/scripts/redhouse.rb';

config_yaml_path = base_dir + '/redhouse.yaml'

Vagrant.configure('2') do |config|
  if File.exists? config_yaml_path then
    settings = YAML::load(File.read(config_yaml_path))
  else
    abort "redhouse.yaml not found in #{base_dir}"
  end

  Redhouse.configure(config, settings)
end
