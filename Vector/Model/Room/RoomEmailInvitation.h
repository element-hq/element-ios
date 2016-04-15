/*
 Copyright 2016 OpenMarket Ltd

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
 The `RoomEmailInvitation` represents the information extracted from the link in an
 invitation email.
 */
@interface RoomEmailInvitation : NSObject

/**
 The invitation parameters.
 Can be nil.
 */
@property (nonatomic, readonly) NSString *email;
@property (nonatomic, readonly) NSString *signUrl;
@property (nonatomic, readonly) NSString *roomName;
@property (nonatomic, readonly) NSString *roomAvatarUrl;
@property (nonatomic, readonly) NSString *inviterName;
@property (nonatomic, readonly) NSString *guestAccessToken;
@property (nonatomic, readonly) NSString *guestUserId;


/**
 Contructor and parser of the query params of the email link.

 @param params the query parameters extracted from the link.
 */
- (instancetype)initWithParams:(NSDictionary*)params;

@end
