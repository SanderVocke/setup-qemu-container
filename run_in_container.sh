#!/bin/sh

shell="/bin/sh -eo pipefail"
case "$1" in
	--shell) shell=$2; shift; shift;;
esac

if [ -f $1 ]; then
    echo "Copying $1 to container"
	podman exec $__RUNNING_CONTAINER mkdir -p $(dirname $1)
    podman cp $1 $__RUNNING_CONTAINER:$1
fi

cmd="$shell \"$@\""

echo "Running in container $__RUNNING_CONTAINER: $cmd"
podman exec $__RUNNING_CONTAINER $cmd