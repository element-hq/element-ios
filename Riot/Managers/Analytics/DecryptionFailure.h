/*
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

#import <Foundation/Foundation.h>

/**
 Failure reasons as defined in https://docs.google.com/document/d/1es7cTCeJEXXfRCTRgZerAM2Wg5ZerHjvlpfTW-gsOfI.
 */
typedef NS_ENUM(NSInteger, DecryptionFailureReason) {
    DecryptionFailureReasonUnspecified,
    DecryptionFailureReasonOlmKeysNotSent,
    DecryptionFailureReasonOlmIndexError,
    DecryptionFailureReasonUnexpected
};

/**
 `DecryptionFailure` represents a decryption failure.
 */
@interface DecryptionFailure : NSObject

/**
 The id of the event that was unabled to decrypt.
 */
@property (nonatomic) NSString *failedEventId;

/**
 The time the failure has been reported.
 */
@property (nonatomic, readonly) NSTimeInterval ts;

/**
 Decryption failure reason.
 */
@property (nonatomic) DecryptionFailureReason reason;

@end
