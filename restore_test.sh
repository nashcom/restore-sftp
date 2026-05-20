#!/bin/bash
############################################################################
# Copyright Nash!Com, Daniel Nashed 2026 - APACHE 2.0 see LICENSE
############################################################################

HOSTNAME=localhost
SSH_PORT=2222
HOST_KEY="restore_ssh_host_ed25519_key"
KNOWN_HOSTS=./restore_sftp_known_hosts

delim()
{
  echo "----------------------------------------"
}


echo "[$HOSTNAME]:$SSH_PORT $(ssh-keygen -y -f $HOST_KEY)" > "$KNOWN_HOSTS" 

sftp -o UserKnownHostsFile="$KNOWN_HOSTS" -P $SSH_PORT restore@localhost:/local/notesdata/notes.ini notes.ini.restore 

echo

if [ -e "notes.ini.restore" ]; then
   echo "[OK] Restore sftp operation worked"
   echo
   delim
   cat notes.ini.restore
   delim
   echo
   rm -f notes.ini.restore
else
  echo "[Error] Restore sftp operation failed!"  
fi

rm -f "$KNOWN_HOSTS"
rm -f "$HOST_KEY"
rm -f "$HOST_KEY.pub"

echo

