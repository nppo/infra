#! /bin/bash

# Useful for testing: https://sed.js.org/

# Update machine & install packages
apt-get update
apt-get upgrade -y
apt-get install -y unattended-upgrades ufw

# Enable automatic updates
sed -i -e 's#//\t"\$${distro_id}:\$${distro_codename}-updates"#\t"\$${distro_id}:\$${distro_codename}-updates"#' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i -e 's#//Unattended-Upgrade::Remove-Unused-Kernel-Packages "false"#Unattended-Upgrade::Remove-Unused-Kernel-Packages "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i -e 's#//Unattended-Upgrade::Remove-Unused-Dependencies "false"#Unattended-Upgrade::Remove-Unused-Dependencies "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i -e 's#//Unattended-Upgrade::Automatic-Reboot "false"#Unattended-Upgrade::Automatic-Reboot "true"#' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i -e 's#//Unattended-Upgrade::Automatic-Reboot-Time#Unattended-Upgrade::Automatic-Reboot-Time#' /etc/apt/apt.conf.d/50unattended-upgrades

# Configure ufw firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable

# SSH hardening
sed -i -e '/^# Ciphers and keying/a Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)Ciphers/s/^.*$/Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)StrictModes/s/^.*$/StrictModes yes/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)HostbasedAuthentication/s/^.*$/HostbasedAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)IgnoreUserKnownHosts/s/^.*$/IgnoreUserKnownHosts yes/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)PermitEmptyPasswords/s/^.*$/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries 2/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh/authorized_keys/' /etc/ssh/sshd_config
sed -i -e '/^\(#\|\)LogLevel/s/^.*$/LogLevel VERBOSE/' /etc/ssh/sshd_config

# Add SSH public keys
%{ for name, public_key in public_keys }
sudo adduser ${name}
usermod -aG sudo ${name}
mkdir -p /home/${name}/.ssh
echo "${public_key}" > /home/${name}/.ssh/authorized_keys
chmod -R go= /home/${name}/.ssh
chown -R ${name}:${name} /home/${name}/.ssh
echo "${name} ALL=(ALL)       NOPASSWD: ALL" | sudo tee -a /etc/sudoers >/dev/null
%{ endfor}
