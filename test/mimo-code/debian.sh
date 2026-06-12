#!/bin/bash
set -e

# Import test library
source dev-container-features-test-lib

# Feature-specific tests for the 'debian' scenario
check "mimo cli installed" command -v mimo
check "mimo version" mimo --version

# Report results
reportResults
