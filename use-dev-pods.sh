#!/bin/sh

# This script modifies Podfile in order to use Matrix pods on their develop branch.
# It is intended to be used by Jenkins to build the develop version of the app.

echo Moving Podfile to develop Matrix pods

# Podfile.lock will be obsolete reset it 
rm -f Podfile.lock

# Disable the active pods
sed -i '' -E "s!^(pod)(.*MatrixSDK)!#\1\2!g" Podfile
sed -i '' -E "s!^(pod)(.*MatrixKit)!#\1\2!g" Podfile
# And enable the develop ones
sed -i '' -E "s!^(#pod)(.*MatrixSDK)(.*develop)!pod\2\3!g" Podfile
sed -i '' -E "s!^(#pod)(.*MatrixKit)(.*develop)!pod\2\3!g" Podfile
