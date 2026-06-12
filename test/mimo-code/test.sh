#!/bin/bash
set -e

# Import test library
source dev-container-features-test-lib

# Feature-specific tests
check "mimo cli installed" command -v mimo
check "mimo version" mimo --version
check "mimo symlink exists" test -L /usr/local/bin/mimo

# Report results
reportResults
