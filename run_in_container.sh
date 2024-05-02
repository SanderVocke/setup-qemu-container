shell="/bin/sh -eo pipefail"
case "$1" in
	--shell) shell=$2; shift; shift;;
esac

cmd="$shell \"$@\""

echo "Running in container $__RUNNING_CONTAINER: $cmd"
podman exec $__RUNNING_CONTAINER $cmd