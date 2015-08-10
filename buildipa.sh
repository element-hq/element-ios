#!/bin/sh

set -e

builddir="build"
outdir="out"

sdk="iphoneos"
basecmd="xcodebuild -scheme Vector -workspace Vector.xcworkspace -configuration Release -sdk $sdk -derivedDataPath $builddir"
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
	if [ -d "Vector.xcworkspace" ]
	then
		$basecmd clean
	fi
	rm -r "$builddir" "$outdir" || true
else
	if [ ! -d "Vector.xcworkspace" ]
	then
		echo "Please run pod install first"
		exit 1
	fi
	$basecmd -archivePath "out/Vector.xcarchive" archive GCC_PREPROCESSOR_DEFINITIONS="\$(GCC_PREPROCESSOR_DEFINITIONS) $vars" "$@"
	xcrun -sdk $sdk PackageApplication -v $outdir/Vector.xcarchive/Products/Applications/Vector.app -o `pwd`/out/Vector.ipa
fi
