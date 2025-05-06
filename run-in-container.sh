#!/bin/bash

# Allow overriding with a custom shell inside the container
shell="/bin/sh"
case "$1" in
	--shell) shell=$2; shift; shift;;
esac

# Grant access to container user to workspace
sudo find "$GITHUB_WORKSPACE" -type d -exec chmod -R o+rwx {} \;

OUT_FILE=/tmp/_gha_output
ENV_FILE=/tmp/_gha_env
RUNTIME_ENV_FILE=/tmp/_gha_run_env

# Propagate our own env by making an env file.
env | grep -v "HOME=" | grep -v "TERM=" > $RUNTIME_ENV_FILE

read -r -d '' unshare_script <<EOF
  mnt=\$(podman mount $__RUNNING_CONTAINER)
  if [ -f $1 ]; then
    # Copy the shell script, if any, into the container at same path
    if [ ! -z "$__SETUP_EMU_CONTAINER_VERBOSE" ]; then
      echo "setup-qemu-container: Copying $1 to container"
    fi
    mkdir -p \$mnt/$(dirname $1)
    chmod a+rwx \$mnt/$(dirname $1)
    cp $1 \$mnt/$1
    chmod a+x \$mnt/$1
  fi
  # Delete past temporary files for GITHUB_OUTPUT and GITHUB_ENV
  if [ ! -z "\$mnt" ]; then
    if [ ! -z "$__SETUP_EMU_CONTAINER_VERBOSE" ]; then
      echo "setup-qemu-container: Refreshing output and env files"
    fi
    rm -f \$mnt/$OUT_FILE && touch \$mnt/$OUT_FILE && chmod a+rw \$mnt/$OUT_FILE
    rm -f \$mnt/$ENV_FILE && touch \$mnt/$ENV_FILE && chmod a+rw \$mnt/$ENV_FILE
  fi
  podman unmount $__RUNNING_CONTAINER
EOF
if [ ! -z "$__SETUP_EMU_CONTAINER_VERBOSE" ]; then
  echo "setup-qemu-container: Running podman unshare script:"
  echo "$unshare_script"
fi
podman unshare bash -c "$unshare_script"
STATUS=$?
if [ $STATUS -ne 0 ]; then
   echo "setup-qemu-container: Unable to prepare the container filesystem (error code $STATUS)"
   exit 1
fi

# Run the command/script
cmd="$shell $@"
if [ ! -z "$__SETUP_EMU_CONTAINER_VERBOSE" ]; then
  echo "setup-qemu-container: Running in container $__RUNNING_CONTAINER: $cmd"
fi
podman exec --env-file=$RUNTIME_ENV_FILE -e GITHUB_OUTPUT=$OUT_FILE -e GITHUB_ENV=$ENV_FILE -w $GITHUB_WORKSPACE $__RUNNING_CONTAINER $cmd
STATUS=$?
if [ $STATUS -ne 0 ]; then
   echo "setup-qemu-container: Container command failed with code $STATUS"
   exit 1
fi

# Propagate GITHUB_OUTPUT and GITHUB_ENV back out
LOCAL_OUT=$(mktemp)
LOCAL_ENV=$(mktemp)
podman cp $__RUNNING_CONTAINER:$OUT_FILE $LOCAL_OUT
podman cp $__RUNNING_CONTAINER:$ENV_FILE $LOCAL_ENV
while IFS="" read -r line; do
  echo "$line" | tee -a $GITHUB_OUTPUT
done < $LOCAL_OUT
while IFS="" read -r line; do
  echo "$line" | tee -a $GITHUB_ENV
done < $LOCAL_ENV
