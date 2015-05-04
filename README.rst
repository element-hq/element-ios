Console
=======

Console is an iOS Matrix client. 

It is also a sample that demonstrates how to use 
MatrixKit (https://github.com/matrix-org/matrix-ios-kit) and 
MatrixSDK (https://github.com/matrix-org/matrix-ios-sdk) in an iOS app.

The app can be installed from the App Store at
https://itunes.apple.com/gb/app/matrix-console/id970074271?mt=8
or you can build from source as per below:

Build instructions
==================

Before opening the Console Xcode workspace, you need to build it with the
CocoaPods command::

        $ cd Console
        $ pod install

This will load all dependencies for the Console source code, including MatrixKit and MatrixSDK.

Then, open ``matrixConsole.xcworkspace`` with Xcode

        $ open matrixConsole.xcworkspace

