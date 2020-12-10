#!/bin/bash
cd $(dirname "$0")

FAILED=()

run() {
    if exec "$@"; then 
        FAILED+=("$1")
    fi
}

echo "$(date)" > test_report.txt

bash ./test-common.sh
bash ./test-kitchen-sink.sh

echo "$(date)" > test_report.txt

# -- Report results --
if [ ${#FAILED[@]} -ne 0 ]; then
    echo -e "\n💥  Failed: ${FAILED[@]}\n Summary:"
    cat test_report.txt
    exit 1
else 
    echo -e "\n💯  All passed!"
    exit 0
fi
