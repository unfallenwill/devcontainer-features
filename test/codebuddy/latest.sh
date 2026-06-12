#!/bin/bash
set -e

# Import test library
source dev-container-features-test-lib

# Feature-specific tests for the 'latest' scenario
check "codebuddy cli installed" command -v codebuddy
check "codebuddy version" codebuddy --version

# Report results
reportResults
