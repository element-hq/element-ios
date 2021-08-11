#!/bin/bash

# Use this script to setup the Xcode project

# Remove existing project file if any
rm -r Riot.xcodeproj

# Create the xcodeproj with all project source files
xcodegen

# Use appropriated dependencies

# Check if Podfile changed in unstaged
git diff --exit-code --quiet --name-only Podfile
PODFILE_HAS_CHANGED_UNSTAGED=$?
# Check if Podfile changed in staged
git diff --staged --exit-code --quiet --name-only Podfile
PODFILE_HAS_CHANGED_STAGED=$?

# If Podfile has changed locally do not modify it
# otherwise use the appropriated dependencies according to the current branch
if [[ "$PODFILE_HAS_CHANGED_UNSTAGED" -eq 1 || "$PODFILE_HAS_CHANGED_STAGED" -eq 1 ]]; then
    echo "Podfile has been changed locally do not modify it"
else
    echo "Podfile has not been changed locally, use appropriated dependencies according to the current branch"
    bundle exec fastlane point_dependencies_to_same_feature
fi

# Create the xcworkspace with all project dependencies
pod install
