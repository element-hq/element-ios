Vector-ios
==========

Vector/iOS is an iOS Matrix client. 

It is based on MatrixKit (https://github.com/matrix-org/matrix-ios-kit) and MatrixSDK (https://github.com/matrix-org/matrix-ios-sdk).

You can build the app from source as per below:

Build instructions
==================

Before opening the Vector Xcode workspace, you need to build it with the
CocoaPods command::

        $ cd Vector
        $ pod install

This will load all dependencies for the Vector source code, including MatrixKit and MatrixSDK.

Then, open ``Vector.xcworkspace`` with Xcode

        $ open Vector.xcworkspace

