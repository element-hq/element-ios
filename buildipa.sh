#!/bin/sh

set -e

builddir="build"
outdir="out"

sdk="iphoneos"
basecmd="xcodebuild -scheme Riot -workspace Riot.xcworkspace -configuration Release -sdk $sdk -derivedDataPath $builddir"
vars=""

# Clean the Xcode build folder to avoid caching issues that happens sometimes
rm -rf ~/Library/Developer/Xcode/DerivedData/*

if [ -n "$GIT_BRANCH" ]
then
	vars="$vars GIT_BRANCH=`echo $GIT_BRANCH | sed -e 's#origin\/##'`"
fi
if [ -n "$BUILD_NUMBER" ]
then
	vars="$vars BUILD_NUMBER=$BUILD_NUMBER"
fi

if [ "$1" == 'clean' ]
then
	if [ -d "Riot.xcworkspace" ]
	then
		$basecmd clean
	fi
	rm -r "$builddir" "$outdir" || true
else
	method=$1
	if [ ! -d "Riot.xcworkspace" ]
	then
		echo "Please run pod install first"
		exit 1
	fi
	$basecmd -archivePath "out/Riot.xcarchive" archive GCC_PREPROCESSOR_DEFINITIONS="\$(GCC_PREPROCESSOR_DEFINITIONS) $vars"
	exportOptionsPlist=`mktemp`
	cat > $exportOptionsPlist <<EOD
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>$method</string>
</dict>
</plist>
EOD
	xcodebuild -exportArchive -archivePath "out/Riot.xcarchive" -exportPath out -exportOptionsPlist "$exportOptionsPlist"
	rm "$exportOptionsPlist"
fi
