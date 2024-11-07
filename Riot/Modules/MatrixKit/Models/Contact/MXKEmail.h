/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>
#import "MXKContactField.h"

@interface MXKEmail : MXKContactField

// email info (the address is stored in lowercase)
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *emailAddress;

- (id)initWithEmailAddress:(NSString*)anEmailAddress type:(NSString*)aType contactID:(NSString*)aContactID matrixID:(NSString*)matrixID;

- (BOOL)matchedWithPatterns:(NSArray*)patterns;

@end
