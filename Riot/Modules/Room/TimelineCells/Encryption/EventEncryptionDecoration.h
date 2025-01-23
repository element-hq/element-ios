// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#ifndef EventEncryptionDecoration_h
#define EventEncryptionDecoration_h

/**
 Decoration used alongside encrypted events
 */
typedef NS_ENUM(NSUInteger, EventEncryptionDecoration)
{
    EventEncryptionDecorationNone,
    EventEncryptionDecorationGrey,
    EventEncryptionDecorationRed
};

#endif /* EventEncryptionDecoration_h */
