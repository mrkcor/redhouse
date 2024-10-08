# Archived Repository

This repository has been **archived** and is no longer actively maintained. The prebuilt Vagrant box is no longer 
available, if you are interested in using a solution like Redhouse you can use this repository and the 
redhouse-packer repository as a basis to build your own.

# Introduction

This repository contains the [Vagrant](https://www.vagrantup.com/) setup for the Redhouse 
box. 

The Redhouse box is a Vagrant box setup to develop Ruby projects based on the 
[Laravel Homestead](https://github.com/laravel/homestead) project which fulfills that 
role for PHP projects.

The base box for this project is built with https://github.com/mrkcor/redhouse-packer, you
can use that project to build your own modified version of the basebox. Theoretically all you
have to is override config.vm.box after the Redhouse.configure call inside the Vagrantfile.

Many thanks to everyone who has contributed to Vagrant, Homestead and the related 
projects to make the lives of many developers a great deal easier!

## Getting started

To get started simply copy the redhouse.yaml.sample file to redhouse.yaml and modify 
it to your liking. Once you're done editing run 'vagrant up' and wait for the 
provisioning to complete.

Once the provisioning is complete there will be a .pem file in the redhouse directory 
(generated through scripts/create-root-certificate.sh), if you install this in your 
browser as a trusted root certificate you will not get warnings for the certificates
generated for the sites that you specified in redhouse.yaml.

PostgreSQL 14 is installed, any databases mentioned in the 'databases' section of the 
redhouse.yaml file will be created within it for you. 

To connect to PostgreSQL no password is needed as long as you are connecting through the
unix socket or localhost. The roles 'vagrant' and 'root' exist for you to connect through.

## What's installed in the default box?

Here's a list of things:

* PostgreSQL 14
* NodeJS 12
* rbenv + ruby-build and Ruby 2.7.4
* nginx
* SQLite
* InfluxDB
* wkhtmltopdf
* rsvg-convert
* ripgrep

If you want to know exactly what's inside you should look inside https://github.com/mrkcor/redhouse-packer

## Running Rails projects

Define the shared folder, site and databases in redhouse.yaml:

``` yaml
folders:
  - map: ~/code/redhouse
    to: /home/vagrant/code/redhouse

sites:
  - map: redhouse.dev
    to: /home/vagrant/code/redhouse/public
    port: 3001
    ruby: 2.7.2

databases:
  - redhouse_development
  - redhouse_test
```

If you have already have a running box you can re-provision it with 'vagrant reload --provision'.

Once the vagrant box is up and running again you can ssh into it with 'vagrant ssh' and go 
to the directory to run the Rails project with 'bin/rails s -p 3001'. Provided that you 
added the domain in your local hosts file to point to the IP address of the vagrant box (also
specified in redhouse.yaml) you can visit https://redhouse.dev to access your Rails project.

If you specify a ruby version that is not yet installed with any of the sites it will get installed
using ruby-build during the provision step.

## Q&A

### Why the name Redhouse?

Rubies are red, Laravel named its Vagrant setup project Homestead which made me think of a house 
and that made me think of Jimi Hendrix's song "Red house"... which led to Redhouse. I guess I am
just special like that :)

### Watchers on file changes are not picking changes on the shared folders. What gives?

Shared filesystems such as VirtualBox's shared folders only trigger filesystem events in the box when the files are changed there. I recently found https://github.com/mhallin/vagrant-notify-forwarder, that's a vagrant plugin that forwards filesystem events from the host to the guest and it works pretty well (although sometimes it can be a bit quirky).

Another way around this is to edit the files from within the VM which is how I work most of the 
time, there are various ways to do this (vim or emacs from the shell inside the box or editing over SFTP or something like that).

### How can I contribute?

Feel free to put an issue on GitHub issues and/or offer a pull request.

