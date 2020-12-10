#!/bin/sh
set -e
cd $(dirname "$0")
find . -path './*.sh' -not -name 'test.sh' | xargs -n 1 sh -i -c '$0 || exit 255'
