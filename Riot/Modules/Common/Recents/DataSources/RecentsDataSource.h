/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

#import "PublicRoomsDirectoryDataSource.h"

@protocol RecentsListServiceProtocol;
@class DiscussionsCount;
@class MXSpace;
@class RecentsDataSourceSections;

/**
 List the different modes used to prepare the recents data source.
 Each mode corresponds to an application tab: Home, Favourites, People and Rooms.
 Used as the tag of UITableView, starting from 1 in order to avoid collision with default tag of UIView.
 */
typedef NS_ENUM(NSInteger, RecentsDataSourceMode)
{
    RecentsDataSourceModeHome = 1,
    RecentsDataSourceModeFavourites,
    RecentsDataSourceModePeople,
    RecentsDataSourceModeRooms,
    RecentsDataSourceModeRoomInvites,
    RecentsDataSourceModeAllChats
};

/**
 List the different secure backup banners that could be displayed.
 */
typedef NS_ENUM(NSInteger, SecureBackupBannerDisplay)
{
    SecureBackupBannerDisplayNone,
    SecureBackupBannerDisplaySetup    
};

/**
 List the different cross-signing banners that could be displayed.
 */
typedef NS_ENUM(NSInteger, CrossSigningBannerDisplay)
{
    CrossSigningBannerDisplayNone,
    CrossSigningBannerDisplaySetup
};

/**
 Action identifier used when the user tapped on the directory change button.

 The `userInfo` is nil.
 */
extern NSString *const kRecentsDataSourceTapOnDirectoryServerChange;

/**
 'RecentsDataSource' class inherits from 'MXKInterleavedRecentsDataSource' to define the Riot recents source
 shared between all the applications tabs.
 */
@interface RecentsDataSource : MXKInterleavedRecentsDataSource

/**
 A set of sections visible in the current table view and associated with their semantic meaning (e.g. "favorites" = 2)
 */
@property (nonatomic, strong, readonly) RecentsDataSourceSections *sections;

@property (nonatomic, readonly) NSInteger totalVisibleItemCount;

/**
 Counts for favorited rooms.
 */
@property (nonatomic, readonly) DiscussionsCount *favoriteMissedDiscussionsCount;

/**
 Counts for direct rooms.
 */
@property (nonatomic, readonly) DiscussionsCount *directMissedDiscussionsCount;

/**
 Counts for group rooms.
 */
@property (nonatomic, readonly) DiscussionsCount *groupMissedDiscussionsCount;

@property (nonatomic, readonly) SecureBackupBannerDisplay secureBackupBannerDisplay;
@property (nonatomic, readonly) CrossSigningBannerDisplay crossSigningBannerDisplay;

@property (nonatomic, readonly) id<RecentsListServiceProtocol> recentsListService;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMatrixSession:(MXSession*)mxSession NS_UNAVAILABLE;

/**
 Initializer
 @param mxSession session instance
 @param recentsListService service instance
 */
- (instancetype)initWithMatrixSession:(MXSession*)mxSession
                   recentsListService:(id<RecentsListServiceProtocol>)recentsListService;

/**
 Set the delegate by specifying the selected display mode.
 */
- (void)setDelegate:(id<MXKDataSourceDelegate>)delegate andRecentsDataSourceMode:(RecentsDataSourceMode)recentsDataSourceMode;

/**
 The current mode (RecentsDataSourceModeHome by default).
 */
@property (nonatomic, readonly) RecentsDataSourceMode recentsDataSourceMode;

/**
 The data source used to manage the rooms from directory.
 */
@property (nonatomic) PublicRoomsDirectoryDataSource *publicRoomsDirectoryDataSource;

/**
 Make a new sections object that reflects the latest state of the data sources
 */
- (RecentsDataSourceSections *)makeDataSourceSections;

/**
 Refresh the recents data source and notify its delegate.
 */
- (void)forceRefresh;

/**
 Tell whether the sections are shrinkable. YES by default.
 */
@property (nonatomic) BOOL areSectionsShrinkable;

/**
 Return true if the given section is currently shrinked.
 */
- (BOOL)isSectionShrinkedAt:(NSInteger)section;

/**
 Get the sticky header view for the specified section.
 
 @param section the section  index
 @param frame the drawing area for the header of the specified section.
 @param tableView the table view
 @return the sticky header view.
 */
- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withFrame:(CGRect)frame inTableView:(UITableView*)tableView;

/**
 Get the height of the section header view.

 @param section the section  index
 @return the header height.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section;

#pragma mark - Drag & Drop handling
/**
 Return true of the cell can be moved from a section to another one.
 */
- (BOOL)isDraggableCellAt:(NSIndexPath*)path;

/**
 Return true of the cell can be moved from a section to another one.
 */
- (BOOL)canCellMoveFrom:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath;

/**
 There is a pending drag and drop cell.
 It defines its path of the source cell.
 */
@property (nonatomic) NSIndexPath* hiddenCellIndexPath;

/**
 There is a pending drag and drop cell.
 It defines its path of the destination cell.
 */
@property (nonatomic) NSIndexPath* droppingCellIndexPath;

/**
 The movingCellBackgroundImage.
 */
@property (nonatomic) UIImageView* droppingCellBackGroundView;

/**
 Paginate in the given section. Results will be notified from delegate methods.
 
 @param section section index to be paginated
 */
- (void)paginateInSection:(NSInteger)section;

/**
 Move a cell from a path to another one.
 It is based on room Tag.
 */
- (void)moveRoomCell:(MXRoom*)room from:(NSIndexPath*)oldPath to:(NSIndexPath*)newPath success:(void (^)(void))moveSuccess failure:(void (^)(NSError *error))moveFailure;

@end
