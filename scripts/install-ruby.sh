#!/usr/bin/env bash

if su -l -c "cd /home/vagrant && source /home/vagrant/.bash_rbenv && rbenv versions --bare " vagrant | grep "$1"; then
  echo "Ruby version $1 is already installed"
else
  echo "Installing Ruby version $1 using rbenv... "
  su -l -c "cd /home/vagrant && source /home/vagrant/.bash_rbenv && rbenv install $1" vagrant
fi
