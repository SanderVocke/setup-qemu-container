#!/bin/sh

shell="/bin/sh -eo pipefail"
case "$1" in
	--shell) shell=$2; shift; shift;;
esac

if [ -f $2 ]; then
    podman cp $2 $__RUNNING_CONTAINER:$2
fi

cmd="$shell \"$@\""

echo "Running in container $__RUNNING_CONTAINER: $cmd"
podman exec $__RUNNING_CONTAINER $cmd