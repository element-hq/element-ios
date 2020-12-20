#!/bin/bash
cp IDETemplateMacros.plist Riot.xcodeproj/xcshareddata/
if [ $(gem list bundler -i) ]; then
	bundle install
	bundle exec pod install
else
	pod install
fi
