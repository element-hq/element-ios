/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@class ShareDataSource;

@protocol ShareDataSourceDelegate <NSObject>

- (void)shareDataSourceDidChangeSelectedRoomIdentifiers:(ShareDataSource *)shareDataSource;

@end

@interface ShareDataSource : MXKRecentsDataSource

@property (nonatomic, weak) id<ShareDataSourceDelegate> shareDelegate;

@property (nonatomic, strong, readonly) NSSet<NSString *> *selectedRoomIdentifiers;

- (instancetype)initWithFileStore:(MXFileStore *)fileStore
                          session:(MXSession *)session;

- (void)selectRoomWithIdentifier:(NSString *)roomIdentifier animated:(BOOL)animated;

- (void)deselectRoomWithIdentifier:(NSString *)roomIdentifier animated:(BOOL)animated;

@end
