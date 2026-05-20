#!/bin/bash
############################################################################
# Copyright Nash!Com, Daniel Nashed 2026 - APACHE 2.0 see LICENSE
############################################################################

set -e

CONTAINER_CMD=docker
BASE_IMAGE=alpine
IMAGE_VARIANT=Alpine
CONTAINER_IMAGE=restore-sftp

print_delim()
{
  echo "--------------------------------------------------------------------------------"
}

header()
{
  echo
  print_delim
  echo "$1"
  print_delim
  echo
}

runtime()
{
  local h m s

  h=$((SECONDS / 3600))
  m=$(((SECONDS % 3600) / 60))
  s=$((SECONDS % 60))

  printf "Completed in %02d:%02d:%02d\n\n" "$h" "$m" "$s"
}

usage()
{
  echo
  echo "Usage: $(basename "$0")"
  echo
  echo "Options"
  echo "-------"
  echo
  echo "-wolfi    Build Wolfi image"
  echo
}

CONTAINER_IMAGE_NAME=$CONTAINER_IMAGE:latest

for a in "$@"; do

  p=$(echo "$a" | awk '{print tolower($0)}')

  case "$p" in

    -wolfi)
      BASE_IMAGE=cgr.dev/chainguard/wolfi-base
      CONTAINER_IMAGE_NAME=$CONTAINER_IMAGE:wolfi
      IMAGE_VARIANT=Wolfi
      ;;

    -h|--help|help)
      usage
      exit 0
      ;;

    *)
      echo
      echo "Invalid parameter [$a]"
      echo
      exit 1
      ;;
  esac
done

header "Building Restore SFTP image [$IMAGE_VARIANT]"

"$CONTAINER_CMD" build \
  --no-cache \
  --progress=plain \
  --build-arg BASE_IMAGE="$BASE_IMAGE" \
  -t "$CONTAINER_IMAGE_NAME" \
  .

echo
runtime
