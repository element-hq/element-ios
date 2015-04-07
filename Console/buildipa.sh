#!/bin/sh

set -e

builddir="build"
outdir="out"

sdk="iphoneos"
basecmd="xcodebuild -scheme matrixConsole -workspace matrixConsole.xcworkspace -configuration Release -sdk $sdk -derivedDataPath $builddir"
vars=""

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
	$basecmd clean
	rm -r "$builddir" "$outdir" || true
else
	if [ ! -d "matrixConsole.xcworkspace" ]
	then
		echo "Please run pod install first"
		exit 1
	fi
	$basecmd -archivePath "out/matrixConsole.xcarchive" archive GCC_PREPROCESSOR_DEFINITIONS="\$(GCC_PREPROCESSOR_DEFINITIONS) $vars" "$@"
	xcrun -sdk $sdk PackageApplication -v $outdir/matrixConsole.xcarchive/Products/Applications/matrixConsole.app -o `pwd`/out/matrixConsole.ipa
fi
