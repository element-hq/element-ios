/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RecentsViewController.h"
#import "RecentsDataSource.h"

/**
 The `HomeViewController` screen is the main app screen.
 */
@interface HomeViewController : RecentsViewController <UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

+ (instancetype)instantiate;

@property (nonatomic, readonly) RecentsDataSourceMode recentsDataSourceMode;

@end
