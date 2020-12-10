#!/bin/bash
cd $(dirname "$0")
VS_CODE_SERVER_TESTS="${1:-true}"
USERNAME=${2:-"$(whoami)"}
LOG_PREFIX=${3:-"$(basename "$(cd .. && pwd)")-"}
RESULTS_LOG="${LOG_PREFIX}test-results.log"
OUTPUT_LOG="${LOG_PREFIX}test-output.log"

FAILED=()

run() {
    if exec "$@" 2>&1 | tee -a "${OUTPUT_LOG}"; then 
        FAILED+=("$1")
    fi
    echo "" | tee -a "${RESULTS_LOG}"
}

echo -e "** $(date) **\n" | tee "${OUTPUT_LOG}" > "${RESULTS_LOG}"

run ./test-common.sh "${VS_CODE_SERVER_TESTS}" "${USERNAME}" "${RESULTS_LOG}"
run ./test-kitchen-sink.sh "${VS_CODE_SERVER_TESTS}" "${USERNAME}" "${RESULTS_LOG}"

echo "See ${OUTPUT_LOG} for details." >> "${RESULTS_LOG}"

echo -e "\n** $(date) **" | tee -a "${OUTPUT_LOG}" >> "${RESULTS_LOG}"

# -- Report results --
if [ "${#FAILED[@]}" -ne "0" ]; then
    cat "${RESULTS_LOG}"
    echo -e "\n😭  Failed scripts: ${FAILED[@]}\n"
    exit 1
else 
    echo -e "\n💯  All passed!"
    exit 0
fi
