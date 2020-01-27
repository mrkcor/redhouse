#!/usr/bin/env bash

if [ ! -f /home/vagrant/.bashxt ]
then
  echo 'PS1="\[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\[\033[1;32m\]\$(__git_ps1) \[\033[0m\]$ "' > /home/vagrant/.bashxt
  chown vagrant:vagrant /home/vagrant/.bashxt
  echo 'source ~/.bashxt' >> /home/vagrant/.bashrc
fi
