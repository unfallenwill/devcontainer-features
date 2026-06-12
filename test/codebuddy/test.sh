#!/bin/bash
set -e

# Import test library
source dev-container-features-test-lib

# Feature-specific tests
check "codebuddy cli installed" command -v codebuddy
check "codebuddy version" codebuddy --version
check "codebuddy symlink exists" test -L /usr/local/bin/codebuddy

# Report results
reportResults
