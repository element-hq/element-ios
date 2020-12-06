#!/bin/bash

if [ $(gem list bundler -i) ]; then
	bundle install
	bundle exec pod install
else
	pod install
fi