jitsi-meet (https://github.com/jitsi/jitsi-meet) does not provide yet a pod for
iOS SDK (https://github.com/jitsi/jitsi-meet/issues/1854). So, the framework is
built as described below and it is temporarly added to the Xcode project.

jitsi doc to build JitsiMeet.framework:
- build jitsi-meet following instructions at https://github.com/jitsi/jitsi-meet#building-the-sources
- build it specifically for iOS using https://github.com/jitsi/jitsi-meet/blob/master/doc/mobile.md#ios

Step by step commands are (when you have all tools installed):
  git clone https://github.com/jitsi/jitsi-meet.git
  cd jitsi-meet
  npm install
  make
  cd ios
  pod install
  xcodebuild -workspace jitsi-meet.xcworkspace -scheme jitsi-meet  -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
  
Look for JitsiMeet.framework in the generated log. It will give you the full path
where Xcode has built the framework.
  
Then, copy the generated JitsiMeet.framework here.
