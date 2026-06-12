#!/bin/bash
set -e

# Import test library
source dev-container-features-test-lib

# Feature-specific tests for Alpine
check "cc-switch installed" test -x "${_REMOTE_USER_HOME:-$HOME}/.local/bin/cc-switch"
check "cc-switch version" ${_REMOTE_USER_HOME:-$HOME}/.local/bin/cc-switch --version

# Report results
reportResults
