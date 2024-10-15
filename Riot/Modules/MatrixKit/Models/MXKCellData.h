/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

/**
 `MXKCellData` objects contain data that is displayed by objects implementing `MXKCellRendering`.
 
 The goal of `MXKCellData` is mainly to cache computed data in order to avoid to compute it each time
 a cell is displayed.
 */
@interface MXKCellData : NSObject

@end
