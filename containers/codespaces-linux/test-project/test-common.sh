#!/bin/bash
cd $(dirname "$0")
VS_CODE_SERVER_TESTS="${1:-true}"
USERNAME=${2:-"$(whoami)"}
RESULTS_LOG=${3:-"test-results.log"}

if [ -z $HOME ]; then
    HOME="/root"
fi

FAILED=()

check() {
    LABEL=$1
    shift
    echo -e "\n🧪  Testing $LABEL: $@"
    if "$@"; then 
        echo "✅  Passed!"
    else
        echo "❌  $LABEL check failed."
        FAILED+=("$LABEL")
    fi
}

ifVSCodeServerTestsEnabled() {
    if [ "${VS_CODE_SERVER_TESTS}" = "true" ]; then
        "$@"
    else
        shift
        LABEL=$1
        echo -e "\n🤷  Skipping test $LABEL - VS Code Server tests disabled."
    fi
}

checkMultiple() {
    PASSED=0
    LABEL="$1"
    shift; MINIMUMPASSED=$1
    shift; EXPRESSION="$1"
    while [ "$EXPRESSION" != "" ]; do
        if $EXPRESSION; then ((PASSED++)); fi
        shift; EXPRESSION=$1
    done
    check "$LABEL" [ $PASSED -ge $MINIMUMPASSED ]
}

# Settings
PACKAGE_LIST="apt-utils \
    git \
    openssh-client \
    gnupg2 \
    iproute2 \
    procps \
    lsof \
    htop \
    net-tools \
    psmisc \
    curl \
    wget \
    rsync \
    ca-certificates \
    unzip \
    zip \
    nano \
    vim-tiny \
    less \
    jq \
    lsb-release \
    apt-transport-https \
    dialog \
    libc6 \
    libgcc1 \
    libgssapi-krb5-2 \
    libicu[0-9][0-9] \
    liblttng-ust0 \
    libstdc++6 \
    zlib1g \
    locales \
    sudo \
    ncdu \
    man-db"

# Actual tests
check "common-os-packages" ./check-os-packages.sh ${PACKAGE_LIST}
ifVSCodeServerTestsEnabled checkMultiple "vscode-server" 1 "[ -d ""$HOME/.vscode-server/bin"" ]" "[ -d ""$HOME/.vscode-server-insiders/bin"" ]" "[ -d ""$HOME/.vscode-test-server/bin"" ]" "[ -d ""$HOME/.vscode-remote/bin"" ]" "[ -d ""$HOME/.vscode-remote/bin"" ]"
check "locale" [ $(locale -a | grep en_US.utf8) ]
check "sudo" sudo echo "sudo works."
check "oh-my-bash" [ -d "$HOME/.oh-my-bash" ]
check "oh-my-zsh" [ -d "$HOME/.oh-my-zsh" ]
check "zsh" zsh --version
ifVSCodeServerTestsEnabled check "code" bash -li -c "code --version"

# Report result
if [ "${#FAILED[@]}" -ne "0" ]; then
    echo -e "(!) $(basename $0) - Failed: ${FAILED[@]}" >> "${RESULTS_LOG}"
    exit 1
else 
    echo -e "(*) $(basename $0) - All passed!" >> "${RESULTS_LOG}"
    exit 0
fi
