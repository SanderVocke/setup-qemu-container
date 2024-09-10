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
export -p | grep -v "HOME=" | grep -v "TERM=" > $RUNTIME_ENV_FILE
echo "declare -x GITHUB_ENV=\"$ENV_FILE\"" >> $RUNTIME_ENV_FILE
echo "declare -x GITHUB_OUTPUT=\"$OUT_FILE\"" >> $RUNTIME_ENV_FILE

read -r -d '' unshare_script <<EOF
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
    echo "Refreshing output and env files"
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
podman exec --env-file=$RUNTIME_ENV_FILE -w $GITHUB_WORKSPACE $__RUNNING_CONTAINER $cmd
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
while IFS="" read -r line; do
  echo "$line" | tee -a $GITHUB_OUTPUT
done < $LOCAL_OUT
while IFS="" read -r line; do
  echo "$line" | tee -a $GITHUB_ENV
done < $LOCAL_ENV
