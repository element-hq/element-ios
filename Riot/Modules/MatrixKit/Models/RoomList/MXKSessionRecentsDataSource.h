/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

#import "MXKConstants.h"
#import "MXKDataSource.h"
#import "MXKRecentCellData.h"

@class MXSpace;

/**
 Identifier to use for cells that display a room in the recents list.
 */
extern NSString *const kMXKRecentCellIdentifier;

/**
 The recents data source based on a unique matrix session.
 Deprecated: Please see MXSession.roomListDataManager
 */
@interface MXKSessionRecentsDataSource : MXKDataSource {

@protected

    /**
     The data for the cells served by `MXKSessionRecentsDataSource`.
     */
    NSMutableArray *cellDataArray;
    
    /**
     The filtered recents: sub-list of `cellDataArray` defined by `searchWithPatterns:` call.
     */
    NSMutableArray *filteredCellDataArray;
}

/**
 The current number of cells.
 */
@property (nonatomic, readonly) NSInteger numberOfCells;

/**
 Tell whether there are some unread messages.
 */
@property (nonatomic, readonly) BOOL hasUnread;

@property (nonatomic, strong, nullable) MXSpace *currentSpace;


#pragma mark - Life cycle

/**
 Filter the current recents list according to the provided patterns.
 When patterns are not empty, the search result is stored in `filteredCellDataArray`,
 this array provides then data for the cells served by `MXKRecentsDataSource`.
 
 @param patternsList the list of patterns (`NSString` instances) to match with. Set nil to cancel search.
 */
- (void)searchWithPatterns:(NSArray*)patternsList;

/**
 Get the data for the cell at the given index.

 @param index the index of the cell in the array
 @return the cell data
 */
- (id<MXKRecentCellDataStoring>)cellDataAtIndex:(NSInteger)index;

/**
 Get height of the cell at the given index.

 @param index the index of the cell in the array
 @return the cell height
 */
- (CGFloat)cellHeightAtIndex:(NSInteger)index;

@end
