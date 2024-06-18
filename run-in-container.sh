#!/bin/sh

# Allow overriding with a custom shell inside the container
shell="/bin/sh"
case "$1" in
	--shell) shell=$2; shift; shift;;
esac

# Prepare the container
podman unshare sh <<EOF
  mnt=\$(podman mount $__RUNNING_CONTAINER)
  if [ -f $1 ]; then
    # Copy the shell script, if any, into the container at same path
    echo "Copying $1 to container"
    mkdir -p \$mnt/$(dirname $1)
    cp $1 \$mnt/$1
    chmod a+x \$mnt/$1
  fi
  # Delete past temporary files for GITHUB_OUTPUT and GITHUB_ENV
  if [ ! -z "$mnt" ]; then
    rm -f $mnt/tmp/_gha_output && touch $mnt/tmp/_gha_output
    rm -f $mnt/tmp/_gha_env && touch $mnt/tmp/_gha_env
  fi
  podman unmount
EOF
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
