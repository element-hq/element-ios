#!/bin/sh

set -e

if [ ! -d "matrixConsole.xcworkspace" ]
then
	echo "Please run pod install first"
	exit 1
fi

builddir="build"
outdir="out"

sdk="iphoneos"
basecmd="xcodebuild -scheme matrixConsole -workspace matrixConsole.xcworkspace -configuration Release -sdk $sdk -derivedDataPath $builddir"
vars=""

if [ -n "$GIT_BRANCH" ]
then
	vars="$vars GIT_BRANCH=`echo $GIT_BRANCH | sed -e '#origin\/##'`"
fi
if [ -n "$BUILD_NUMBER" ]
then
	vars="$vars BUILD_NUMBER=$BUILD_NUMBER"
fi

if [ $# == 0 ]
then
	$basecmd -archivePath "out/matrixConsole.xcarchive" archive $vars
	xcrun -sdk $sdk PackageApplication -v $outdir/matrixConsole.xcarchive/Products/Applications/matrixConsole.app -o `pwd`/out/matrixConsole.ipa
elif [ $1 == 'clean' ]
then
	$basecmd clean
	rm -r "$builddir" "$outdir" || true
fi
