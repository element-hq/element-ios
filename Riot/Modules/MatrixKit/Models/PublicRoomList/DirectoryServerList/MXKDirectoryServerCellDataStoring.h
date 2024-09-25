/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>
#import <MatrixSDK/MatrixSDK.h>

#import "MXKCellData.h"

/**
 `MXKDirectoryServerCellDataStoring` defines a protocol a class must conform in order to
 store directory cell data managed by `MXKDirectoryServersDataSource`.
 */
@protocol MXKDirectoryServerCellDataStoring <NSObject>

#pragma mark - Data displayed by a server cell

/**
 The name of the directory server.
 */
@property (nonatomic) NSString *desc;

/**
 The icon of the server.
 */
@property (nonatomic) UIImage *icon;

/**
 The optional media manager used to download the icon of the server.
 */
@property (nonatomic) MXMediaManager *mediaManager;

/**
 In case the cell data represents a homeserver, its description.
 */
@property (nonatomic, readonly) NSString *homeserver;
@property (nonatomic, readonly) BOOL includeAllNetworks;

/**
 In case the cell data represents a third-party protocol instance, its description.
 */
@property (nonatomic, readonly) MXThirdPartyProtocolInstance *thirdPartyProtocolInstance;
@property (nonatomic, readonly) MXThirdPartyProtocol *thirdPartyProtocol;

/**
 Define a MXKDirectoryServerCellData that will store a homeserver.

 @param homeserver the homeserver name (ex: "matrix.org).
 @param includeAllNetworks YES to list all public rooms on the homeserver whatever their protocol.
                           NO to list only matrix rooms.
 */
- (id)initWithHomeserver:(NSString*)homeserver includeAllNetworks:(BOOL)includeAllNetworks;

/**
 Define a MXKDirectoryServerCellData that will store a third-party protocol instance.
 
 @param instance the instance of the protocol.
 @param protocol the protocol description.
 */
- (id)initWithProtocolInstance:(MXThirdPartyProtocolInstance*)instance protocol:(MXThirdPartyProtocol*)protocol;

@end
