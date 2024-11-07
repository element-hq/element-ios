/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
