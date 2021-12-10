/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
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

@interface MXKContactField : NSObject<NSCoding>

/**
 The identifier of the contact to whom the data belongs to.
 */
@property (nonatomic, readonly) NSString *contactID;
/**
 The linked matrix identifier if any
 */
@property (nonatomic, readwrite) NSString *matrixID;
/**
 The matrix avatar url (Matrix Content URI), nil by default.
 */
@property (nonatomic) NSString* matrixAvatarURL;
/**
 The current avatar downloaded by using the avatar url if any
 */
@property (nonatomic, readonly) UIImage  *avatarImage;

- (id)initWithContactID:(NSString*)contactID matrixID:(NSString*)matrixID;

- (void)loadAvatarWithSize:(CGSize)avatarSize;

/**
 Reset the current avatar. May be used in case of the matrix avatar url change.
 A new avatar will be automatically restored from the matrix data.
 */
- (void)resetMatrixAvatar;

@end
