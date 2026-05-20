#!/bin/sh

set -e
USER=restore
GROUP=restore

apk update
apk upgrade
apk add --no-cache openssh
rm -rf /var/cache/apk/*

addgroup -g 1000 $USER 
adduser -D -u 1000 -G $GROUP -s /sbin/nologin $USER 
passwd -d $USER

mkdir -p /var/run/sshd /home/$USER/.ssh /sftp
chown root:root /sftp

chmod 755 /sftp

chown -R $USER:$GROUP /home/$USER
chmod 750 /home/$USER
chmod 700 /home/$USER/.ssh

mv /install/entrypoint.sh /entrypoint.sh
mv /install/sshd_config /etc/ssh/sshd_config

chmod 755 /entrypoint.sh

rm -rf /install

