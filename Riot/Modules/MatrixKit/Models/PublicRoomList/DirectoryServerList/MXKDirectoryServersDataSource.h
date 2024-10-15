/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import "MXKDataSource.h"
#import "MXKDirectoryServerCellDataStoring.h"

/**
 Identifier to use for cells that display a server in the servers list.
 */
FOUNDATION_EXPORT NSString *const kMXKDirectorServerCellIdentifier;

/**
 `DirectoryServersDataSource` is a base class to list servers and third-party protocols
 instances available on the user homeserver.
 
 We can then list public rooms from the directory of these servers. This is done 
 with `PublicRoomsDirectoryDataSource`.

 As a `MXKDataSource` child class, the class has a state where values have the following meanings:
     - MXKDataSourceStatePreparing: the data source is not yet ready or it is fetching data from the homeserver.
     - MXKDataSourceStateReady: the data source data is ready.
     - MXKDataSourceStateFailed: the data source failed to fetch data.
 
 There is no way in Matrix to be notified when there is a change.
 */
@interface MXKDirectoryServersDataSource : MXKDataSource <UITableViewDataSource>
{
@protected
    /**
     The data for the cells served by `DirectoryServersDataSource`.
     */
    NSMutableArray<id<MXKDirectoryServerCellDataStoring>> *cellDataArray;

    /**
     The filtered servers: sub-list of `cellDataArray` defined by `searchWithPatterns:`.
     */
    NSMutableArray<id<MXKDirectoryServerCellDataStoring>> *filteredCellDataArray;
}

/**
 Additional room directory servers the datasource will list.
 */
@property (nonatomic) NSArray<NSString*> *roomDirectoryServers;

/**
 Fetch the data source data.
 */
- (void)loadData;

/**
 Filter the current recents list according to the provided patterns.
 When patterns are not empty, the search result is stored in `filteredCellDataArray`,
 this array provides then data for the cells served by `MXKDirectoryServersDataSource`.

 @param patternsList the list of patterns to match with. Set nil to cancel search.
 */
- (void)searchWithPatterns:(NSArray<NSString*> *)patternsList;

/**
 Get the data for the cell at the given index path.

 @param indexPath the index of the cell.
 @return the cell data.
 */
- (id<MXKDirectoryServerCellDataStoring>)cellDataAtIndexPath:(NSIndexPath*)indexPath;

@end
