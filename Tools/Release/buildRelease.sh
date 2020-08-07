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


# Fastlane update
gem install bundler
bundle install
bundle update


# Checkout the source to build
mkdir -p $BUILD_DIR
cd $BUILD_DIR
REPO_URL=$(git ls-remote --get-url origin)
git clone $REPO_URL
REPO_NAME=$(basename -s .git $REPO_URL)
cd $REPO_NAME
git checkout $TAG $TAG


# Develop branch special case
if [ "$TAG" = "develop" ]; then 
    ./use-dev-pods.sh
fi


# Build
bundle exec fastlane app_store build_number:$BUILD_NUMBER

# Check ipa
./checkipa.sh out/Riot.ipa


if [ -e out/Riot.ipa ]; then
    # Here is the artefact
    cp out/Riot.ipa ../../../Riot-$TAG-$BUILD_NUMBER.ipa
    
    echo "Riot-$TAG-$BUILD_NUMBER.ipa has been successfully built"
fi
