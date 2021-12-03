/*
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd

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

#import "MXKDirectoryServersDataSource.h"

#import "MXKDirectoryServerCellData.h"

NSString *const kMXKDirectorServerCellIdentifier = @"kMXKDirectorServerCellIdentifier";

#pragma mark - DirectoryServersDataSource

@interface MXKDirectoryServersDataSource ()
{
    // The pending request to load third-party protocols.
    MXHTTPOperation *request;
}

@end

@implementation MXKDirectoryServersDataSource

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        cellDataArray = [NSMutableArray array];
        filteredCellDataArray = nil;

        // Set default data w classes
        [self registerCellDataClass:MXKDirectoryServerCellData.class forCellIdentifier:kMXKDirectorServerCellIdentifier];
    }
    return self;
}

- (void)destroy
{
    cellDataArray = nil;
    filteredCellDataArray = nil;
}

- (void)cancelAllRequests
{
    [super cancelAllRequests];

    [request cancel];
    request = nil;
}

- (void)loadData
{
    // Cancel the previous request
    if (request)
    {
        [request cancel];
    }

    // Reset all vars
    [cellDataArray removeAllObjects];

    [self setState:MXKDataSourceStatePreparing];

    Class class = [self cellDataClassForCellIdentifier:kMXKDirectorServerCellIdentifier];

    // Add user's HS
    NSString *userHomeserver = self.mxSession.matrixRestClient.credentials.homeServerName;
    id<MXKDirectoryServerCellDataStoring> cellData = [[class alloc] initWithHomeserver:userHomeserver includeAllNetworks:YES];
    [cellDataArray addObject:cellData];

    // Add user's HS but for Matrix public rooms only
    cellData = [[class alloc] initWithHomeserver:userHomeserver includeAllNetworks:NO];
    [cellDataArray addObject:cellData];

    // Add custom directory servers
    for (NSString *homeserver in _roomDirectoryServers)
    {
        if (![homeserver isEqualToString:userHomeserver])
        {
            cellData = [[class alloc] initWithHomeserver:homeserver includeAllNetworks:YES];
            [cellDataArray addObject:cellData];
        }
    }

    MXWeakify(self);
    request = [self.mxSession.matrixRestClient thirdpartyProtocols:^(MXThirdpartyProtocolsResponse *thirdpartyProtocolsResponse) {

        MXStrongifyAndReturnIfNil(self);
        for (NSString *protocolName in thirdpartyProtocolsResponse.protocols)
        {
            MXThirdPartyProtocol *protocol = thirdpartyProtocolsResponse.protocols[protocolName];
            
            for (MXThirdPartyProtocolInstance *instance in protocol.instances)
            {
                id<MXKDirectoryServerCellDataStoring> cellData = [[class alloc] initWithProtocolInstance:instance protocol:protocol];
                cellData.mediaManager = self.mxSession.mediaManager;
                [self->cellDataArray addObject:cellData];
            }
        }
        
        [self setState:MXKDataSourceStateReady];

    } failure:^(NSError *error) {

        MXStrongifyAndReturnIfNil(self);
        if (!self->request || self->request.isCancelled)
        {
            // Do not take into account error coming from a cancellation
            return;
        }
        
        self->request = nil;
        
        MXLogDebug(@"[MXKDirectoryServersDataSource] Failed to fecth third-party protocols. The HS may be too old to support third party networks");
        
        [self setState:MXKDataSourceStateReady];
    }];
}

- (void)searchWithPatterns:(NSArray*)patternsList
{
    if (patternsList.count)
    {
        if (filteredCellDataArray)
        {
            [filteredCellDataArray removeAllObjects];
        }
        else
        {
            filteredCellDataArray = [NSMutableArray arrayWithCapacity:cellDataArray.count];
        }

        for (id<MXKDirectoryServerCellDataStoring> cellData in cellDataArray)
        {
            for (NSString* pattern in patternsList)
            {
                if ([cellData.desc rangeOfString:pattern options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    [filteredCellDataArray addObject:cellData];
                    break;
                }
            }
        }
    }
    else
    {
        filteredCellDataArray = nil;
    }

    if (self.delegate)
    {
        [self.delegate dataSource:self didCellChange:nil];
    }
}

/**
 Get the data for the cell at the given index path.

 @param indexPath the index of the cell.
 @return the cell data.
 */
- (id<MXKDirectoryServerCellDataStoring>)cellDataAtIndexPath:(NSIndexPath*)indexPath;
{
    if (filteredCellDataArray)
    {
        return filteredCellDataArray[indexPath.row];
    }
    return cellDataArray[indexPath.row];
}


#pragma mark - Private methods

// Update the MXKDataSource state and the delegate
- (void)setState:(MXKDataSourceState)newState
{
    state = newState;
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:didStateChange:)])
    {
        [self.delegate dataSource:self didStateChange:state];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (filteredCellDataArray)
    {
        return filteredCellDataArray.count;
    }
    return cellDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKDirectoryServerCellDataStoring> cellData = [self cellDataAtIndexPath:indexPath];

    if (cellData && self.delegate)
    {
        NSString *identifier = [self.delegate cellReuseIdentifierForCellData:cellData];
        if (identifier)
        {
            UITableViewCell<MXKCellRendering> *cell  = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];

            // Make the cell display the data
            [cell render:cellData];

            return cell;
        }
    }

    // Return a fake cell to prevent app from crashing.
    return [[UITableViewCell alloc] init];
}

@end
