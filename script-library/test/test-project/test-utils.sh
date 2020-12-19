#!/bin/bash
SCRIPT_FOLDER="$(cd "$(dirname $0)" && pwd)"
USERNAME=${1:-vscode}

if [ -z $HOME ]; then
    HOME="/root"
fi

if type apk > /dev/null 2>&1 && ! type apt-get > /dev/null 2>&1; then
    LINUX_DISTRO_ROOT="alpine"
else
    LINUX_DISTRO_ROOT="debian"
fi

FAILED=()

echoStderr()
{
    echo "$@" 1>&2
}

check() {
    LABEL=$1
    shift
    echo -e "\n🧪 Testing $LABEL"
    if "$@"; then 
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkMultiple() {
    PASSED=0
    LABEL="$1"
    echo -e "\n🧪 Testing $LABEL."
    shift; MINIMUMPASSED=$1
    shift; EXPRESSION="$1"
    while [ "$EXPRESSION" != "" ]; do
        if $EXPRESSION; then ((PASSED++)); fi
        shift; EXPRESSION=$1
    done
    if [ $PASSED -ge $MINIMUMPASSED ]; then
        echo "✅ Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkOSPackages() {
    if  [ "${LINUX_DISTRO_ROOT}" = "debian" ]; then
        CHECK_COMMAND="dpkg-query --show"
    else
        # Alpine
        CHECK_COMMAND="apk info"
    fi
    LABEL=$1
    shift
    echo -e "\n🧪 Testing $LABEL"
    if $CHECK_COMMAND "$@"; then 
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkExtension() {
    # Happens asynchronusly, so keep retrying 10 times with an increasing delay
    EXTN_ID="$1"
    TIMEOUT_SECONDS="${2:-10}"
    RETRY_COUNT=0
    echo -e -n "\n🧪 Looking for extension $1 for maximum of ${TIMEOUT_SECONDS}s"
    until [ "${RETRY_COUNT}" -eq "${TIMEOUT_SECONDS}" ] || \
        [ ! -e $HOME/.vscode-server/extensions/${EXTN_ID}* ] || \
        [ ! -e $HOME/.vscode-server-insiders/extensions/${EXTN_ID}* ] || \
        [ ! -e $HOME/.vscode-test-server/extensions/${EXTN_ID}* ] || \
        [ ! -e $HOME/.vscode-remote/extensions/${EXTN_ID}* ]
    do
        sleep 1s
        (( RETRY_COUNT++ ))
        echo -n "."
    done

    if [ ${RETRY_COUNT} -lt ${TIMEOUT_SECONDS} ]; then
        echo -e "\n✅ Passed!"
        return 0
    else
        echoStderr -e "\n❌ Extension $EXTN_ID not found."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkCommon()
{
    LOGIN_SHELL_CHECK="${1:-true}"
    ZSH_CHECKS="${2:-true}"
    VSCODE_CHECKS="${3:-true}"

    if [ "${LINUX_DISTRO_ROOT}" = "debian" ]; then
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
            libkrb5-3 \
            libgssapi-krb5-2 \
            libicu[0-9][0-9] \
            liblttng-ust0 \
            libstdc++6 \
            zlib1g \
            locales \
            sudo \
            ncdu \
            man-db \
            strace"
    else 
        # Alpine
        PACKAGE_LIST="\
            git \
            openssh-client \
            gnupg \
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
            vim \
            less \
            jq \
            libgcc \
            libstdc++ \
            krb5-libs \
            libintl \
            libssl1.1 \
            lttng-ust \
            tzdata \
            userspace-rcu \
            zlib \
            sudo \
            coreutils \
            sed \
            grep \
            which \
            ncdu \
            shadow \
            strace"
    fi

    # Actual tests
    checkOSPackages "common-os-packages" ${PACKAGE_LIST}
    check "non-root-user" id ${USERNAME}
    check "sudo" sudo echo "sudo works."
    if [ "${ZSH_CHECKS}" = "true" ]; then
        check "zsh" zsh --version
        check "oh-my-zsh" [ -d "$HOME/.oh-my-zsh" ]
    fi
    if [ "${VSCODE_CHECKS}" = "true" ]; then
        check "code" which code
        checkMultiple "vscode-server" 1 "[ -d $HOME/.vscode-server/bin ]" "[ -d $HOME/.vscode-server-insiders/bin ]" "[ -d $HOME/.vscode-test-server/bin ]" "[ -d $HOME/.vscode-remote/bin ]" "[ -d $HOME/.vscode-remote/bin ]"
    fi
    if [ "${LINUX_DISTRO_ROOT}" = "debian" ] || [ "${LINUX_DISTRO_ROOT}" = "redhat" ]; then
        check "locale" [ $(locale -a | grep en_US.utf8) ]
    fi
    if [ "${LOGIN_SHELL_CHECK}" = "true" ]; then
        check "login-shell-path" [ -f "/etc/profile.d/00-restore-env.sh" ]
    fi
}

reportResults() {
    if [ ${#FAILED[@]} -ne 0 ]; then
        echoStderr -e "\n💥  Failed tests: ${FAILED[@]}"
        exit 1
    else 
        echo -e "\n💯  All passed!"
        exit 0
    fi
}

# Useful for Docker Compose-based definitions where the server running  
# the test uses a non-root user whose UID/GID is not 1000
fixTestProjectFolderPrivs() {
    if [ "${USERNAME}" != "root" ]; then
        TEST_PROJECT_FOLDER="${1:-$SCRIPT_FOLDER}"
        FOLDER_USER="$(stat -c '%U' "${TEST_PROJECT_FOLDER}")"
        if [ "${FOLDER_USER}" != "${USERNAME}" ]; then
            echoStderr "WARNING: Test project folder is owned by ${FOLDER_USER}. Updating to ${USERNAME}."
            sudo chown -R ${USERNAME} "${TEST_PROJECT_FOLDER}"
        fi
    fi
}