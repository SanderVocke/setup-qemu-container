#!/bin/sh

# Allow overriding with a custom shell inside the container
shell="/bin/sh -eo pipefail"
case "$1" in
	--shell) shell=$2; shift; shift;;
esac

# Copy the shell script, if any, into the container at same path
if [ -f $1 ]; then
    echo "Copying $1 to container"
	$__PODMAN_CMD exec $__PODMAN_ARGS $__RUNNING_CONTAINER mkdir -p $(dirname $1)
    $__PODMAN_CMD cp $__PODMAN_ARGS $1 $__RUNNING_CONTAINER:$1
fi

# Delete past temporary files for GITHUB_OUTPUT and GITHUB_ENV
OUT_FILE=/tmp/_gha_output
ENV_FILE=/tmp/_gha_env
$__PODMAN_CMD exec $__PODMAN_ARGS $__RUNNING_CONTAINER /bin/sh -c "rm -f $OUT_FILE $ENV_FILE && touch $OUT_FILE && touch $ENV_FILE"

# Run the command/script
cmd="$shell $@"
echo "Running in container $__RUNNING_CONTAINER: $cmd"
$__PODMAN_CMD exec $__PODMAN_ARGS -e GITHUB_OUTPUT=$OUT_FILE -e GITHUB_ENV=$ENV_FILE -w $GITHUB_WORKSPACE $__RUNNING_CONTAINER $cmd

# Propagate GITHUB_OUTPUT and GITHUB_ENV back out
LOCAL_OUT=$(mktemp)
LOCAL_ENV=$(mktemp)
$__PODMAN_CMD cp $__PODMAN_ARGS $__RUNNING_CONTAINER:$OUT_FILE $LOCAL_OUT
$__PODMAN_CMD cp $__PODMAN_ARGS $__RUNNING_CONTAINER:$ENV_FILE $LOCAL_ENV
for line in $(cat $LOCAL_OUT); do
  echo "$line" >> $GITHUB_OUTPUT
done
for line in $(cat $LOCAL_ENV); do
  echo "$line" >> $GITHUB_ENV
done