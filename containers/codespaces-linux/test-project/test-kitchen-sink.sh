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

# Check Oryx
check "oryx" oryx platforms

# Check .NET
check "dotnet" dotnet --info

# Check Python
check "python" python --version
check "python3" python3 --version
check "python2" python2 --version
check "pip" pip --version
check "pip3" pip3 --version
check "pipx" pipx --version
check "pylint" pylint --version
check "flake8" flake8 --version
check "autopep8" autopep8 --version
check "yapf" yapf --version
check "mypy" mypy --version
check "pydocstyle" pydocstyle --version
check "bandit" bandit --version
check "virtualenv" virtualenv --version

# Check Java tools
check "java" java --version
check "sdkman" bash -li -c "sdk --version"
check "gradle" gradle --version
check "maven" mvn --version

# Check Ruby tools
check "ruby" ruby --version
check "rake" rake --version
check "rvm" bash -li -c "rvm --version"
check "rbenv" bash -li -c "rbenv --version"

# Node.js
check "node" node --version
check "nvm" bash -li -c "nvm --version"
check "nvs" bash -li -c "nvs --version"
check "yarn" yarn --version
check "npm" npm --version

# PHP
check "php" php --version

# Rust
check "cargo" cargo --version
check "rustup" rustup --version
check "rls" rls --version
check "rustfmt" rustfmt --version
check "clippy" cargo-clippy --version
check "lldb" which lldb

# Check utilities
check "additional-os-packages" ./check-os-packages.sh vim xtail software-properties-common libsecret-1-dev build-essential cmake cppcheck valgrind clang lldb llvm gdb 
check "az" az --version
check "gh" gh --version
check "git-lfs" git-lfs --version
check "docker" docker --version
check "kubectl" kubectl version --client
check "helm" helm version

# Check expected shells
check "bash" bash --version
check "fish" fish --version
check "zsh" zsh --version

# Check expected git editor command is available
check "git-ed" bash -li -c '[ -f "$(which git-ed.sh)" ] && [ "$(cat $(which git-ed.sh))" = "$(cat ./git-ed-expected.txt)" ]'

# Check extensions
check "gitHub.vscode-pull-request-github" ./check-extension.sh "gitHub.vscode-pull-request-github"

# Report result
if [ "${#FAILED[@]}" -ne "0" ]; then
    echo -e "(!) $(basename $0) - Failed: ${FAILED[@]}" >> "${RESULTS_LOG}"
    exit 1
else 
    echo -e "(*) $(basename $0) - All passed!" >> "${RESULTS_LOG}"
    exit 0
fi
