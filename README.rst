Console
=======

Console is an iOS Matrix client. 

It is also a sample that demonstrates how to use MatrixSDK (https://github.com/matrix-org/matrix-ios-sdk) in an iOS app.

Build instructions
==================

Before opening the Console Xcode workspace, you need to build it with the CocoaPods command::

        $ cd Console
        $ pod install

This will load all dependencies for the Console source code, including MatrixSDK.

Then, open ``matrixConsole.xcworkspace`` with Xcode

        $ open matrixConsole.xcworkspace

