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

#import <Foundation/Foundation.h>

#import <MatrixSDK/MatrixSDK.h>
#import "MXKCellRendering.h"

/**
 List data source states.
 */
typedef enum : NSUInteger {
    /**
     Default value (used when all resources have been disposed).
     The instance cannot be used anymore.
     */
    MXKDataSourceStateUnknown,
    
    /**
     Initialisation is in progress.
     */
    MXKDataSourceStatePreparing,
    
    /**
     Something wrong happens during initialisation.
     */
    MXKDataSourceStateFailed,
    
    /**
     Data source is ready to be used.
     */
    MXKDataSourceStateReady
    
} MXKDataSourceState;

@protocol MXKDataSourceDelegate;

/**
 `MXKDataSource` is the base class for data sources managed by MatrixKit.
 
 Inherited 'MXKDataSource' instances are used to handle table or collection data.
 They may conform to UITableViewDataSource or UICollectionViewDataSource protocol to be used as data source delegate
 for a UITableView or a UICollectionView instance.
 */
@interface MXKDataSource : NSObject <MXKCellRenderingDelegate>
{
@protected
    MXKDataSourceState state;
}

/**
 The matrix session.
 */
@property (nonatomic, weak, readonly) MXSession *mxSession;

/**
 The data source state
 */
@property (nonatomic, readonly) MXKDataSourceState state;

/**
 The delegate notified when the data has been updated.
 */
@property (weak, nonatomic) id<MXKDataSourceDelegate> delegate;


#pragma mark - Life cycle
/**
 Base constructor of data source.
 
 Customization like class registrations must be done before loading data (see '[MXKDataSource registerCellDataClass: forCellIdentifier:]') .
 That is why 3 steps should be considered during 'MXKDataSource' initialization:
 1- call [MXKDataSource initWithMatrixSession:] to initialize a new allocated object.
 2- customize classes and others...
 3- call [MXKDataSource finalizeInitialization] to finalize the initialization.

 @param mxSession the Matrix session to get data from.
 @return the newly created instance.
 */
- (instancetype)initWithMatrixSession:(MXSession*)mxSession;

/**
 Finalize the initialization by adding an observer on matrix session state change.
 */
- (void)finalizeInitialization;

/**
 Dispose all resources.
 */
- (void)destroy;

/**
 This method is called when the state of the attached Matrix session has changed.
 */
- (void)didMXSessionStateChange;


#pragma mark - MXKCellData classes
/**
 Register the MXKCellData class that will be used to process and store data for cells
 with the designated identifier.

 @param cellDataClass a MXKCellData-inherited class that will handle data for cells.
 @param identifier the identifier of targeted cell.
 */
- (void)registerCellDataClass:(Class)cellDataClass forCellIdentifier:(NSString *)identifier;

/**
 Return the MXKCellData class that handles data for cells with the designated identifier.

 @param identifier the cell identifier.
 @return the associated MXKCellData-inherited class.
 */
- (Class)cellDataClassForCellIdentifier:(NSString *)identifier;

#pragma mark - Pending HTTP requests 

/**
 Cancel all registered requests.
 */
- (void)cancelAllRequests;

@end

@protocol MXKDataSourceDelegate <NSObject>

/**
 Ask the delegate which MXKCellRendering-compliant class must be used to render this cell data.
 
 This method is called when MXKDataSource instance is used as the data source delegate of a table or a collection.
 CAUTION: The table or the collection MUST have registered the returned class with the same identifier than the one returned by [cellReuseIdentifierForCellData:].
 
 @param cellData the cell data to display.
 @return a MXKCellRendering-compliant class which inherits UITableViewCell or UICollectionViewCell class (nil if the cellData is not supported).
 */
- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData;

/**
 Ask the delegate which identifier must be used to dequeue reusable cell for this cell data.
 
 This method is called when MXKDataSource instance is used as the data source delegate of a table or a collection.
 CAUTION: The table or the collection MUST have registered the right class with the returned identifier (see [cellViewClassForCellData:]).
 
 @param cellData the cell data to display.
 @return the reuse identifier for the cell (nil if the cellData is not supported).
 */
- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData;

/**
 Tells the delegate that some cell data/views have been changed.

 @param dataSource the involved data source.
 @param changes contains the index paths of objects that changed.
 */
- (void)dataSource:(MXKDataSource*)dataSource didCellChange:(id /* @TODO*/)changes;

@optional

/**
 Tells the delegate that data source state changed
 
 @param dataSource the involved data source.
 @param state the new data source state.
 */
- (void)dataSource:(MXKDataSource*)dataSource didStateChange:(MXKDataSourceState)state;

/**
 Relevant only for data source which support multi-sessions.
 Tells the delegate that a matrix session has been added.
 
 @param dataSource the involved data source.
 @param mxSession the new added session.
 */
- (void)dataSource:(MXKDataSource*)dataSource didAddMatrixSession:(MXSession*)mxSession;

/**
 Relevant only for data source which support multi-sessions.
 Tells the delegate that a matrix session has been removed.
 
 @param dataSource the involved data source.
 @param mxSession the removed session.
 */
- (void)dataSource:(MXKDataSource*)dataSource didRemoveMatrixSession:(MXSession*)mxSession;

/**
 Tells the delegate when a user action is observed inside a cell.
 
 @see `MXKCellRenderingDelegate` for more details.
 
 @param dataSource the involved data source.
 @param actionIdentifier an identifier indicating the action type (tap, long press...) and which part of the cell is concerned.
 @param cell the cell in which action has been observed.
 @param userInfo a dict containing additional information. It depends on actionIdentifier. May be nil.
 */
- (void)dataSource:(MXKDataSource*)dataSource didRecognizeAction:(NSString*)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary*)userInfo;

/**
 Asks the delegate if a user action (click on a link) can be done.

 @see `MXKCellRenderingDelegate` for more details.

 @param dataSource the involved data source.
 @param actionIdentifier an identifier indicating the action type (link click) and which part of the cell is concerned.
 @param cell the cell in which action has been observed.
 @param userInfo a dict containing additional information. It depends on actionIdentifier. May be nil.
 @param defaultValue the value to return by default if the action is not handled.
 @return a boolean value which depends on actionIdentifier.
 */
- (BOOL)dataSource:(MXKDataSource*)dataSource shouldDoAction:(NSString *)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary *)userInfo defaultValue:(BOOL)defaultValue;

/**
 Notify the delegate that invites count did change

 @see `MXKCellRenderingDelegate` for more details.

 @param dataSource the involved data source.
 @param invitesCount number of rooms in the invites section.
  */
- (void)dataSource:(MXKDataSource*)dataSource didUpdateInvitesCount:(NSUInteger)invitesCount;

@end

