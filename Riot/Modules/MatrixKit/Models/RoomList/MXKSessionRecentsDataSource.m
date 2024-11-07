/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKSessionRecentsDataSource.h"

@import MatrixSDK;

#import "MXKRoomDataSourceManager.h"

#import "MXKSwiftHeader.h"

#pragma mark - Constant definitions
NSString *const kMXKRecentCellIdentifier = @"kMXKRecentCellIdentifier";

@implementation MXKSessionRecentsDataSource

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithMatrixSession:matrixSession];
    if (self)
    {
        // Update here data source state
        if (state != MXKDataSourceStateReady)
        {
            state = MXKDataSourceStateReady;
            if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:didStateChange:)])
            {
                [self.delegate dataSource:self didStateChange:state];
            }
        }
        
        // And inform the delegate about the update
        [self.delegate dataSource:self didCellChange:nil];
    }
    return self;
}

#pragma mark -

- (NSInteger)numberOfCells
{
    return 0;
}

- (BOOL)hasUnread
{
    return NO;
}

- (void)searchWithPatterns:(NSArray*)patternsList
{
}

- (id<MXKRecentCellDataStoring>)cellDataAtIndex:(NSInteger)index
{
    return nil;
}

- (CGFloat)cellHeightAtIndex:(NSInteger)index
{
    return 0;
}

// Find the cell data that stores information about the given room id
- (id<MXKRecentCellDataStoring>)cellDataWithRoomId:(NSString*)roomId
{
    return nil;
}

@end
