/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2018 New Vector Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <UIKit/UIKit.h>

/**
 The Matrix iOS Kit version.
 */
FOUNDATION_EXPORT NSString *const MatrixKitVersion;

/**
 Posted when an error is observed at Matrix Kit level.
 This notification may be used to inform user by showing the error as an alert.
 The notification object is the NSError instance.
 
 The passed userInfo dictionary may contain:
 - `kMXKErrorUserIdKey` the matrix identifier of the account concerned by this error.
 */
FOUNDATION_EXPORT NSString *const kMXKErrorNotification;

/**
 The key in notification userInfo dictionary representating the account userId.
 */
FOUNDATION_EXPORT NSString *const kMXKErrorUserIdKey;
