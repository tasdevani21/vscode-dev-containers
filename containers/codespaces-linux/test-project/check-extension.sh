#!/bin/bash
cd $(dirname "$0")

set -e

USERNAME=${1:-"$(whoami)"}

if [ -z $HOME ]; then
    HOME="/root"
fi

checkMultiple() {
    PASSED=0
    MINIMUMPASSED=$1
    shift; EXPRESSION="$1"
    while [ "$EXPRESSION" != "" ]; do
        if $EXPRESSION; then ((PASSED++)); fi
        shift; EXPRESSION=$1
    done
    if [ $PASSED -ge $MINIMUMPASSED ]; then
        return 0
    else 
        return 1
    fi
}

NEXT_WAIT_TIME=0
until [ $NEXT_WAIT_TIME -eq 5 ] || checkMultiple 1 "[ -d ""$HOME/.vscode-server/extensions/$1*"" ]" "[ -d ""$HOME/.vscode-server-insiders/extensions/$1*"" ]" "[ -d ""$HOME/.vscode-test-server/extensions/$1*"" ]" "[ -d ""$HOME/.vscode-remote/extensions/$1*"" ]"; do   
    echo "Retrying..."
    sleep $(( NEXT_WAIT_TIME++ ))
done

if [ $NEXT_WAIT_TIME -lt 5 ]; then
    exit 0
else
    exit 1
fi
