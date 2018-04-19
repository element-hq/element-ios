#!/bin/sh

# From experimentation, the way I recommend building IPA files (as of Xcode 6 / iOS 8) is:
#   xcodebuild -archivePath foo.xcarchive archive
#   xcrun -sdk iphoneos PackageApplication -v foo.xcarchive/Products/Applications/foo.app -o `pwd`/foo.ipa
# See the accomanying buildipa.sh for a complete example in context.
# The purpose of this script is to check for the myriad symptoms of broken IPA files produced by other
# tools, as discussed further below.

if [ $# == 0 ]
then
    echo "Usage: $0 <ipa file>"
    exit 10
fi

tmp=`mktemp -d ipacheck.XXXX`
unzip -d "$tmp" $1 > /dev/null
cd "$tmp"
apsenv=`codesign -d --entitlements - Payload/*.app 2> /dev/null | grep aps-environment -a -A 1 | tail -n 1 | sed -e 's/.*>\(.*\)<.*/\1/'`
xcent=`ls Payload/*.app/archived-expanded-entitlements.xcent 2> /dev/null`
cd ..
rm -r "$tmp"

# Check for archived-expanded-entitlements.xcent
# The absence of this file apparently can cause issues submitting to the iTunes store.
# Its absence does not appear to cause problem installing enterprise builds (unless it's listed in
# the code signature and absent, which can be caused by exporting IPA files using xcodebuild -exportArchive).
# Note that in all cases I have tested, its contents does not match the entitlements embedded in the binary.
# We assert that it at least exists.
if [ -z "$xcent" ]
then
    echo "$1 has no archived-expanded-entitlements.xcent."
    
    # It seems that since Xcode 9.3, this file is no more present (https://forums.developer.apple.com/thread/99923)
    #exit 2
fi

# Check the aps-environment embedded in the binary.
# If this is incorrect or absent, you have a build with broken push.
# Using xcodebuild -exportArchive -exportWithOriginalSigningIdentity is known to
# strip the aps-environment string out of the binary's embedded entitlements.
# Also, make sure ther 'push notifications' switch is on in Xcode's project
# capabilities editor. This became necessary of of Xcode 8.
if [ "$apsenv" == 'production' ]
then
    echo "$1's aps-environment is $apsenv: looks good"
elif [ -z "$apsenv" ]
then
    echo "$1 has no aps-environment: push will not work with this build!"
    exit 1
else
    echo "$1's aps-environment is $apsenv. Is that what you wanted?"
    exit 1
fi
