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


#import "MXKSendReplyEventStringLocalizer.h"
#import "MXKSwiftHeader.h"

@implementation MXKSendReplyEventStringLocalizer

- (NSString *)senderSentAnImage
{
    return [MatrixKitL10n messageReplyToSenderSentAnImage];
}

- (NSString *)senderSentAVideo
{
    return [MatrixKitL10n messageReplyToSenderSentAVideo];
}

- (NSString *)senderSentAnAudioFile
{
    return [MatrixKitL10n messageReplyToSenderSentAnAudioFile];
}

- (NSString *)senderSentAVoiceMessage
{
    return [MatrixKitL10n messageReplyToSenderSentAVoiceMessage];
}

- (NSString *)senderSentAFile
{
    return [MatrixKitL10n messageReplyToSenderSentAFile];
}

- (NSString *)senderSentTheirLocation
{
    return [MatrixKitL10n messageReplyToSenderSentTheirLocation];
}

- (NSString *)messageToReplyToPrefix
{
    return [MatrixKitL10n messageReplyToMessageToReplyToPrefix];
}

@end
