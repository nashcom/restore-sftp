#!/bin/bash
############################################################################
# Copyright Nash!Com, Daniel Nashed 2026 - APACHE 2.0 see LICENSE
############################################################################

CONTAINER_NAME=restore-sftp
CONTAINER_IMAGE=restore-sftp

docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME

HOST_KEY="restore_ssh_host_ed25519_key"
HOST_KEY_NAME="RestoreSFTP"

rm -f "$HOST_KEY"

if [ ! -e "$HOST_KEY" ]; then
  ssh-keygen -t ed25519 -N '' -C "$HOST_KEY_NAME" -f "$HOST_KEY" > /dev/null
  chmod 400 "$HOST_KEY"
fi

HOST_KEY_B64=$(base64 -w0 "$HOST_KEY")

docker run -d \
  --name $CONTAINER_NAME \
  -e AUTHORIZED_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
  -e HOST_KEY_B64="$HOST_KEY_B64" \
  -p 2222:2222 \
  -v $(pwd)/sftp/local/notesdata:/sftp/local/notesdata \
  -v $(pwd)/sftp/local/backup:/sftp/local/backup \
  $CONTAINER_IMAGE

sleep 1
docker logs $CONTAINER_NAME 
echo
