#!/bin/bash
set -e
dpkg-query --show -f='${Package}: ${Version}\n' "$@"
