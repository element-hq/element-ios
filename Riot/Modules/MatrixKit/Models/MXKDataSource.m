/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MXKDataSource.h"

#import "MXKCellData.h"
#import "MXKCellRendering.h"

@interface MXKDataSource ()
{
    /**
     The mapping between cell identifiers and MXKCellData classes.
     */
    NSMutableDictionary *cellDataMap;
}
@end

@implementation MXKDataSource
@synthesize state;

#pragma mark - Life cycle

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        state = MXKDataSourceStateUnknown;
        cellDataMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithMatrixSession:(MXSession *)matrixSession
{
    self = [self init];
    if (self)
    {
        _mxSession = matrixSession;
        state = MXKDataSourceStatePreparing;
    }
    return self;
}

- (void)finalizeInitialization
{
    // Add an observer on matrix session state change (prevent multiple registrations).
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMXSessionStateChange:) name:kMXSessionStateDidChangeNotification object:nil];
    
    // Call the registered callback to finalize the initialisation step.
    [self didMXSessionStateChange];
}

- (void)destroy
{
    state = MXKDataSourceStateUnknown;
    if (_delegate && [_delegate respondsToSelector:@selector(dataSource:didStateChange:)])
    {
        [_delegate dataSource:self didStateChange:state];
    }
    
    _mxSession = nil;
    _delegate = nil;
    
    [self cancelAllRequests];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    cellDataMap = nil;
}

#pragma mark - MXSessionStateDidChangeNotification
- (void)didMXSessionStateChange:(NSNotification *)notif
{
    // Check this is our Matrix session that has changed
    if (notif.object == _mxSession)
    {
        [self didMXSessionStateChange];
    }
}

- (void)didMXSessionStateChange
{
    // The inherited class is highly invited to override this method for its business logic
}


#pragma mark - MXKCellData classes
- (void)registerCellDataClass:(Class)cellDataClass forCellIdentifier:(NSString *)identifier
{
    // Sanity check: accept only MXKCellData classes or sub-classes
    NSParameterAssert([cellDataClass isSubclassOfClass:MXKCellData.class]);
    
    cellDataMap[identifier] = cellDataClass;
}

- (Class)cellDataClassForCellIdentifier:(NSString *)identifier
{
    return cellDataMap[identifier];
}

#pragma mark - MXKCellRenderingDelegate
- (void)cell:(id<MXKCellRendering>)cell didRecognizeAction:(NSString*)actionIdentifier userInfo:(NSDictionary *)userInfo
{
    // The data source simply relays the information to its delegate
    if (_delegate && [_delegate respondsToSelector:@selector(dataSource:didRecognizeAction:inCell:userInfo:)])
    {
        [_delegate dataSource:self didRecognizeAction:actionIdentifier inCell:cell userInfo:userInfo];
    }
}

- (BOOL)cell:(id<MXKCellRendering>)cell shouldDoAction:(NSString *)actionIdentifier userInfo:(NSDictionary *)userInfo defaultValue:(BOOL)defaultValue
{
    BOOL shouldDoAction = defaultValue;

    // The data source simply relays the question to its delegate
    if (_delegate && [_delegate respondsToSelector:@selector(dataSource:shouldDoAction:inCell:userInfo:defaultValue:)])
    {
        shouldDoAction = [_delegate dataSource:self shouldDoAction:actionIdentifier inCell:cell userInfo:userInfo defaultValue:defaultValue];
    }

    return shouldDoAction;
}


#pragma mark - Pending HTTP requests
/**
 Cancel all registered requests.
 */
- (void)cancelAllRequests
{
    // The inherited class is invited to override this method
}

@end
