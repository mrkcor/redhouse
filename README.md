# Introduction

This repository contains the [Vagrant](https://www.vagrantup.com/) setup for the Redhouse 
box. 

The Redhouse box is a Vagrant box setup to develop Ruby projects based on the 
[Laravel Homestead](https://github.com/laravel/homestead) project which fulfills that 
role for PHP projects.

The base box for this project is built with https://github.com/mrkcor/redhouse-packer

Many thanks to everyone who has contributed to Vagrant, Homestead and the related 
projects to make the lives of many developers a great deal easier!

## Getting started

To get started simply copy the readhouse.yaml.sample file to readhouse.yaml and modify 
it to your liking. Once you're done editing run 'vagrant up' and wait for the 
provisioning to complete.

Once the provisioning is complete there will be a .pem file in the redhouse directory 
(generated through scripts/create-root-certificate.sh), if you install this in your 
browser as a trusted root certificate you will not get warnings for the certificates
generated for the sites that you specified in redhouse.yaml.

MariaDB 10.4 and PostgreSQL 12 are installed, any databases mentioned in the 'databases' 
section of the redhouse.yaml file will be created for you in both of those. 

To connect to PostgreSQL no password is needed as long as you are connecting through the
unix socket or localhost. The roles 'vagrant', 'redhouse' and 'root' exist for you
to connect through.

To connect to MariaDB you need to use the username 'redhouse' and the password 'overyonder'. 

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
    ruby: 2.6.5

databases:
  - redhouse_development
  - redhouse_test
```

If you have already have a running box you can re-provision it with 'vagrant reload --provision'.

Once the vagrant box is up and running again you can ssh into it with 'vagrant ssh' and go 
to the directory to run the Rails project with 'bin/rails s -p 3001'. Provided that you 
added the domain in your local hosts file to point to the IP address of the vagrant box (also
specified in redhouse.yaml) you can visit https://redhouse.dev to access your Rails project.

## Q&A

### Why the name Redhouse?

Rubies are red, Laravel named its Vagrant setup project Homestead which made me think of a house 
and that made me think of Jimi Hendrix's song "Red house"... which led to Redhouse.

### How can I contribute?

Feel free to put an issue on GitHub issues and/or offer a pull request.

