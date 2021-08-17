#!/bin/bash

# This script is invoked by xcodegen for running post commands

# Move file header template in project shared data folder
cp IDETemplateMacros.plist Riot.xcodeproj/xcshareddata/
