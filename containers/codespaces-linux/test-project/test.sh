#!/bin/bash
cd $(dirname "$0")

source test-utils.sh codespace

# Run common tests
checkCommon

# Check default extensions
checkExtension "gitHub.vscode-pull-request-github"

# Check Oryx
check "oryx" oryx --version

# Check .NET
check "dotnet" bash -c '[ "$(dotnet --list-sdks | wc -l)" = "$(ls ${DOTNET_ROOT}/sdk | wc -l)" ]'

# Check Python
check "python" python --version
check "pip" pip --version
check "pip2" pip2 --version
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
check "pip-global" bash -c 'pip install pytest && pytest --version && pip uninstall -y pytest'

# Check Java tools
check "java" java -version
check "sdkman" bash -c '. ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk --version'
check "gradle" gradle --version
check "maven" mvn --version

# Check Ruby tools
check "ruby" ruby --version
check "rvm" bash -c ". ${RVM_PATH}/scripts/rvm && rvm --version"
check "rbenv" bash -c 'eval "$(rbenv init -)" && rbenv --version'
check "rake" rake --version

# Check Node.js
check "node" node --version
check "npm" npm --version
check "yarn" yarn --version
check "npm-global-install" bash -c '\
    npm install -g vsce \
    && vsce --version \
    && npm uninstall -g vsce'
check "nvm" bash -c '\
    npm config delete prefix \
    && . ${NVM_DIR}/nvm.sh \
    && nvm install 8 \
    && [ "$(node --version | grep -o -e "v[^\.]*")" = "v8" ] \
    && nvm use system \
    && nvm alias default system \
    && nvm uninstall 8 \
    && npm config -g set prefix ${NPM_GLOBAL}'
check "nvs" bash -c '. ${NVS_ROOT}/nvs.sh && nvs --version'

# PHP
check "php" php --version

# Go
check "go" go version
check "go-global-install" bash -c "\
    go get github.com/golangci/gosec/cmd/gosec \
    && gosec --help > /dev/null 2>&1"



# Rust
check "cargo" cargo --version
check "rustup" rustup --version
check "rls" rls --version
check "rustfmt" rustfmt --version
check "clippy" cargo-clippy --version
check "lldb" which lldb

# Check utilities
checkOSPackages "additional-os-packages" vim xtail software-properties-common
check "az" az --version
check "gh" gh --version
check "git-lfs" git-lfs --version
check "docker" docker ps
check "kubectl" kubectl version --client
check "helm" helm version

# Check expected shells
check "bash" bash --version
check "fish" fish --version
check "zsh" zsh --version

# Check expected commands
check "git-ed" [ "$(cat /home/codespace/.local/bin/git-ed.sh)" = "$(cat ./git-ed-expected.txt)" ]

# Report result
reportResults
