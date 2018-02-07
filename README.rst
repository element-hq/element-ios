Riot-ios
==========

Riot/iOS is an iOS Matrix client. 

.. image:: https://linkmaker.itunes.apple.com/images/badges/en-us/badge_appstore-lrg.svg
   :target: https://itunes.apple.com/us/app/riot-open-source-collaboration/id1083446067?mt=8

It is based on MatrixKit (https://github.com/matrix-org/matrix-ios-kit) and MatrixSDK (https://github.com/matrix-org/matrix-ios-sdk).

You can build the app from source as per below:

Build instructions
==================

Before opening the Riot Xcode workspace, you need to build it with the
CocoaPods command::

        $ cd Riot
        $ pod install

This will load all dependencies for the Riot source code, including MatrixKit 
and MatrixSDK.  You will need an recent and updated (``pod update``) install of
CocoaPods.

Then, open ``Riot.xcworkspace`` with Xcode

        $ open Riot.xcworkspace

Developing
==========

Uncomment the right definitions of ``$matrixKitVersion`` for the version you want to develop and build against. For example, if you are trying to build the develop branch, uncomment ``$matrixKitVersion = 'develop'`` and make sure the more specific MatrixKit version is commented out. Once you are done editing the ``Podfile``, run ``pod install``.

You may need to change the bundle identifier and app group identifier to be unique to get Xcode to build the app. Make sure to change the application group identifier everywhere by running a search for ``group.im.vector`` and changing every spot that identifier is used to your new identifier.

Copyright & License
==================

Copyright (c) 2014-2017 OpenMarket Ltd
Copyright (c) 2017 Vector Creations Ltd
Copyright (c) 2017-2018 New Vector Ltd

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
