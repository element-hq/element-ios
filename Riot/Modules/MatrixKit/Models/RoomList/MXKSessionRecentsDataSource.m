/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
