readonly SCRIPT_PATH=$(readlink -f "$0")
readonly SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
install -Dv -m755 "$SCRIPT_DIR"/run_in_container.sh abin/run_in_container.sh