#!/bin/sh

readonly SCRIPT_PATH=$(readlink -f "$0")
readonly SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
install -Dv -m755 "$SCRIPT_DIR"/run-in-container.sh $pwd/abin/run-in-container.sh
echo "$pwd/abin" >> $GITHUB_PATH

# make workspace writeable for all
chmod a+x $GIHUB_WORKSPACE