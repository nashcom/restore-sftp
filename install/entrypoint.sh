#!/bin/sh
set -e

HOME_DIR=/home/restore
RESTORE_USER=restore
RESTORE_GROUP=restore

mkdir -p $HOME_DIR/.ssh

chmod 700 $HOME_DIR/.ssh

if [ -n "$AUTHORIZED_KEY" ]; then
    echo "$AUTHORIZED_KEY" > $HOME_DIR/.ssh/authorized_keys
elif [ -f /run/secrets/authorized_key ]; then
    cp /run/secrets/authorized_key $HOME_DIR/.ssh/authorized_keys
fi

chmod 400 $HOME_DIR/.ssh/authorized_keys
chown -R $RESTORE_USER:$RESTORE_GROUP $HOME_DIR/.ssh

rm -f /etc/ssh/ssh_host_ed25519_key.pub

if [ -n "$HOST_KEY_B64" ]; then
    echo "$HOST_KEY_B64" | base64 -d > /etc/ssh/ssh_host_ed25519_key
    chmod 400 /etc/ssh/ssh_host_ed25519_key

elif [ -f /run/secrets/ssh_host_ed25519_key ]; then
  cp /run/secrets/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key

elif [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key
fi

chmod 400 /etc/ssh/ssh_host_ed25519_key

HOST_PUBKEY=$(ssh-keygen -y -f /etc/ssh/ssh_host_ed25519_key)
AUTHORIZED_KEYS=$(cat $HOME_DIR/.ssh/authorized_keys)
. /etc/os-release

echo
echo "----------------------------------------"
echo "Restore SFTP Server"
echo "----------------------------------------"
echo
echo "$PRETTY_NAME ($VERSION_ID)"
echo
echo "Host Public Key :  $HOST_PUBKEY"
echo "Authorized  Key :  $AUTHORIZED_KEYS"
echo

exec /usr/sbin/sshd -D -e
