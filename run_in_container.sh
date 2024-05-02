echo "Running in container $__RUNNING_CONTAINER: $@"
podman exec $__RUNNING_CONTAINER /bin/sh -eo pipefail "$@"