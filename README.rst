Vector-ios
==========

Vector/iOS is an iOS Matrix client. 

.. image:: https://linkmaker.itunes.apple.com/images/badges/en-us/badge_appstore-lrg.svg
   :target: https://itunes.apple.com/us/app/vector-open-source-collaboration/id1083446067?mt=8

It is based on MatrixKit (https://github.com/matrix-org/matrix-ios-kit) and MatrixSDK (https://github.com/matrix-org/matrix-ios-sdk).

You can build the app from source as per below:

Build instructions
==================

Before opening the Vector Xcode workspace, you need to build it with the
CocoaPods command::

        $ cd Vector
        $ pod install

This will load all dependencies for the Vector source code, including MatrixKit 
and MatrixSDK.  You will need an recent and updated (``pod update``) install of
CocoaPods.

Then, open ``Vector.xcworkspace`` with Xcode

        $ open Vector.xcworkspace

Developing
==========

Uncomment the right definitions of ``pod 'MatrixSDK'`` and ``pod 'MatrixKit'``
in ``Podfile`` for the versions you want to develop and build against, and
``pod install``.

Copyright & License
==================

Copyright (c) 2014-2016 OpenMarket Ltd

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
