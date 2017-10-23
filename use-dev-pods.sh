#!/bin/sh

# This script modifies Podfile in order to use Matrix pods on their develop branch.
# It is intended to be used by Jenkins to build the develop version of the app.

echo Moving Podfile to develop Matrix pods

# Podfile.lock will be obsolete reset it 
rm -f Podfile.lock

# Enable the develop one
sed -i '' -E "s!^(#)(.*'develop')!\2!g" Podfile