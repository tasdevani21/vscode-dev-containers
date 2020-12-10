#!/bin/bash
set -e

cd $(dirname "$0")

if [ -z $HOME ]; then
    HOME="/root"
fi

FAILED=()

check() {
    LABEL=$1
    shift
    echo -e "\n🧪  Testing $LABEL: $@"
    if "$@"; then 
        echo "🏆  Passed!"
    else
        echo "💥  $LABEL check failed."
        FAILED+=("$LABEL")
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
check "sdkman" sdk --version
check "gradle" gradle --version
check "maven" mvn --version

# Check Ruby tools
check "ruby" ruby --version
check "rake" rake --version
check "rvm" bash -i -c 'rvm --version'
check "rbenv" bash -i -c 'rbenv --version'

# Node.js
check "node" node --version
check "nvm" bash -i -c 'nvm --version'
check "nvs" bash -i -c 'nvs --version'
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

# Check expected commands
check "git-ed" test "$(cat $(which git-ed.sh))" = "$(cat ./git-ed-expected.txt)"

# Check extensions
check "GitHub.vscode-pull-request-github" ./check-extension.sh "GitHub.vscode-pull-request-github"

# -- Report results --
if [ ${#FAILED[@]} -ne 0 ]; then
    echo "Failed in $(basename $0): ${FAILED[@]}" >> test_report.txt
    exit 1
else 
    exit 0
fi
