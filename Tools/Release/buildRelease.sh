#!/bin/sh

# Use sudo less Ruby
export GEM_HOME=$HOME/.gem
export PATH=$GEM_HOME/bin:$PATH


if [ ! $# -eq 1 ]; then
    echo "Usage: ./buildRelease.sh [tag or branch]"
    exit 1
fi 

if [ ! -n "$APPLE_ID" ]; then
    echo "You must set the APPLE_ID env var before calling this script"
    echo 'export APPLE_ID="foo.bar@apple.com"'
    exit 1
fi 


TAG=$1
BUILD_DIR="build"/$TAG
BUILD_NUMBER=$( date +%Y%m%d%H%M%S )


if [ -e $BUILD_DIR ]; then
    echo "Error: Folder ${BUILD_DIR} already exists"
    exit 1
fi

# Checkout the source to build
mkdir -p $BUILD_DIR
cd $BUILD_DIR
REPO_URL=$(git ls-remote --get-url origin)
REPO_NAME=$(basename -s .git $REPO_URL)
git clone $REPO_URL --depth=1 --branch $TAG
cd $REPO_NAME

# Fastlane update
gem install bundler
bundle install
bundle update

# Update fastlane plugins
bundle exec fastlane update_plugins

# Use appropriated dependencies according to the current branch
bundle exec fastlane point_dependencies_to_same_feature

# Build
bundle exec fastlane app_store build_number:$BUILD_NUMBER git_tag:$TAG

if [ -e out/Riot.ipa ]; then
    # Here is the artefact
    cp out/Riot.ipa ../../../Riot-$TAG-$BUILD_NUMBER.ipa
    
    echo "Riot-$TAG-$BUILD_NUMBER.ipa has been successfully built"
fi
