#!/bin/bash
echo "Test Passed" > test.txt
SSHNPD_COMMAND="~/.local/bin/sshnpd -a @sshnpdatsign -m @sshnpatsign -d deviceName -s -u -v"
echo "Running: $SSHNPD_COMMAND"
eval $SSHNPD_COMMAND
