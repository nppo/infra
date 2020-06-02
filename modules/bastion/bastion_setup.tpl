#! /bin/bash

%{ for name, public_key in public_keys }
sudo adduser ${name}
usermod -aG sudo ${name}
mkdir -p /home/${name}/.ssh
echo "${public_key}" > /home/${name}/.ssh/authorized_keys
chmod -R go= /home/${name}/.ssh
chown -R ${name}:${name} /home/${name}/.ssh
echo "${name} ALL=(ALL)       NOPASSWD: ALL" | sudo tee -a /etc/sudoers >/dev/null
%{ endfor}
