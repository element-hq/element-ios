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

#import "DecryptionFailure.h"

const struct DecryptionFailureReasonStruct DecryptionFailureReason = {
    .unspecified = @"unspecified_error",
    .olmKeysNotSent = @"olm_keys_not_sent_error",
    .olmIndexError = @"olm_index_error",
    .unexpected = @"unexpected_error"
};

@implementation DecryptionFailure

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _ts = [NSDate date].timeIntervalSince1970;
    }
    return self;
}

@end
