#!/bin/bash

# Allow overriding with a custom shell inside the container
shell="/bin/sh"
case "$1" in
	--shell) shell=$2; shift; shift;;
esac

# Grant access to container user to workspace
sudo chmod -R o+rx "$GITHUB_WORKSPACE"

OUT_FILE=/tmp/_gha_output
ENV_FILE=/tmp/_gha_env

read -r -d '' unshare_script <<EOF
  set -o xtrace
  mnt=\$(podman mount $__RUNNING_CONTAINER)
  if [ -f $1 ]; then
    # Copy the shell script, if any, into the container at same path
    echo "Copying $1 to container"
    mkdir -p \$mnt/$(dirname $1)
    chmod a+rwx \$mnt/$(dirname $1)
    cp $1 \$mnt/$1
    chmod a+x \$mnt/$1
  fi
  # Delete past temporary files for GITHUB_OUTPUT and GITHUB_ENV
  if [ ! -z "\$mnt" ]; then
    rm -f \$mnt/$OUT_FILE && touch \$mnt/$OUT_FILE && chmod a+rw \$mnt/$OUT_FILE
    rm -f \$mnt/$ENV_FILE && touch \$mnt/$ENV_FILE && chmod a+rw \$mnt/$ENV_FILE
  fi
  podman unmount $__RUNNING_CONTAINER
EOF
podman unshare bash -c "$unshare_script"
STATUS=$?
if [ $STATUS -ne 0 ]; then
   echo "Unable to prepare the container filesystem (error code $STATUS)"
   exit 1
fi

# Run the command/script
cmd="$shell $@"
echo "Running in container $__RUNNING_CONTAINER: $cmd"
podman exec -e GITHUB_OUTPUT=$OUT_FILE -e GITHUB_ENV=$ENV_FILE -w $GITHUB_WORKSPACE $__RUNNING_CONTAINER $cmd
STATUS=$?
if [ $STATUS -ne 0 ]; then
   echo "Container command failed with code $STATUS"
   exit 1
fi

# Propagate GITHUB_OUTPUT and GITHUB_ENV back out
LOCAL_OUT=$(mktemp)
LOCAL_ENV=$(mktemp)
podman cp $__RUNNING_CONTAINER:$OUT_FILE $LOCAL_OUT
podman cp $__RUNNING_CONTAINER:$ENV_FILE $LOCAL_ENV
for line in $(cat $LOCAL_OUT); do
  echo "$line" >> $GITHUB_OUTPUT
done
for line in $(cat $LOCAL_ENV); do
  echo "$line" >> $GITHUB_ENV
done
