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

# Enable this flag to build the ipa from the current local source code. Not git clone
# LOCAL_SOURCE=true

if [ -e $BUILD_DIR ]; then
    echo "Error: Folder ${BUILD_DIR} already exists"
    exit 1
fi

# Checkout the source to build
mkdir -p $BUILD_DIR
cd $BUILD_DIR
REPO_URL=$(git ls-remote --get-url origin)
REPO_NAME=$(basename -s .git $REPO_URL)

if [ "$LOCAL_SOURCE" = true ]; then
echo "Reuse source code of the local copy..." 
rm -rf /tmp/$REPO_NAME
cp -R ../../../.. /tmp/$REPO_NAME
mv /tmp/$REPO_NAME .
else
echo "Git clone $REPO_URL with branch/tag $TAG..." 
git clone --recursive $REPO_URL --depth=1 --branch $TAG
fi

cd $REPO_NAME

# Fastlane update
gem install bundler
bundle install
bundle update

# Update fastlane plugins
bundle exec fastlane update_plugins

# Build
bundle exec fastlane app_store build_number:$BUILD_NUMBER git_tag:$TAG

if [ -e out/Riot.ipa ]; then
    # Here is the artefact
    cp out/Riot.ipa ../../../Riot-$TAG-$BUILD_NUMBER.ipa
    
    echo "Riot-$TAG-$BUILD_NUMBER.ipa has been successfully built"
fi
