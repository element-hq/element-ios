/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"
#import <MatrixSDK/MatrixSDK.h>

@interface Contact : MXKContact

@property (nonatomic) MXRoomMember* mxMember;

@property (nonatomic) MXRoomThirdPartyInvite* mxThirdPartyInvite;

@property (nonatomic) MXGroupUser* mxGroupUser;

@end
