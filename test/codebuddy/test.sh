#!/bin/bash
set -e

# Import test library
source dev-container-features-test-lib

# Feature-specific tests
check "codebuddy installed" test -x "${_REMOTE_USER_HOME:-$HOME}/.codebuddy/bin/codebuddy"
check "codebuddy version" ${_REMOTE_USER_HOME:-$HOME}/.codebuddy/bin/codebuddy --version

# Report results
reportResults
