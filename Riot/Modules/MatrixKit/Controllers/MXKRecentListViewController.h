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

#import <UIKit/UIKit.h>

#import "MXKViewController.h"
#import "MXKRecentsDataSource.h"

@class MXKRecentListViewController;

/**
 `MXKRecentListViewController` delegate.
 */
@protocol MXKRecentListViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user selected a room.

 @param recentListViewController the `MXKRecentListViewController` instance.
 @param roomId the id of the selected room.
 @param mxSession the matrix session in which the room is defined.
 */
- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectRoom:(NSString*)roomId inMatrixSession:(MXSession*)mxSession;

/**
 Tells the delegate that the user selected a suggested room.

 @param recentListViewController the `MXKRecentListViewController` instance.
 @param childInfo the `MXSpaceChildInfo` instance that describes the selected room.
 @param sourceView the view the modal has to be presented from.
 */
-(void)recentListViewController:(MXKRecentListViewController *)recentListViewController didSelectSuggestedRoom:(MXSpaceChildInfo *)childInfo from:(UIView* _Nullable)sourceView;

@end


/**
 This view controller displays a room list.
 */
@interface MXKRecentListViewController : MXKViewController <MXKDataSourceDelegate, UITableViewDelegate, UISearchBarDelegate>
{
@protected
    
    /**
     The fake top view displayed in case of vertical bounce.
     */
    __weak UIView *topview;
    
    /**
     `isRefreshNeeded` is set to `YES` if an update of the datasource has been triggered but the UI has not been updated.
     It's set to `NO` after a refresh of the UI.
     */
    BOOL isRefreshNeeded;
}

@property (weak, nonatomic) IBOutlet UISearchBar *recentsSearchBar;
@property (weak, nonatomic) IBOutlet UITableView *recentsTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recentsSearchBarTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recentsSearchBarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recentsTableViewBottomConstraint;

/**
 The current data source associated to the view controller.
 */
@property (nonatomic, readonly) MXKRecentsDataSource *dataSource;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MXKRecentListViewControllerDelegate> delegate;

/**
 Enable the search option by adding a navigation item in the navigation bar (YES by default).
 Set NO this property to disable this option and hide the related bar button.
 */
@property (nonatomic) BOOL enableBarButtonSearch;

/**
 Enabled or disabled the UI update after recents syncs. Default YES.
 */
@property (nonatomic, getter=isRecentsUpdateEnabled) BOOL recentsUpdateEnabled;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKRecentListViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `recentListViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKRecentListViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKRecentListViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)recentListViewController;

/**
 Display the recents described in the provided data source.
 
 Note1: The provided data source will replace the current data source if any. The caller
 should dispose properly this data source if it is not used anymore.
 
 Note2: You may provide here a MXKInterleavedRecentsDataSource instance to display interleaved recents.

 @param listDataSource the data source providing the recents list.
 */
- (void)displayList:(MXKRecentsDataSource*)listDataSource;

/**
 Refresh the recents table display.
 */
- (void)refreshRecentsTable;

/**
 Hide/show the search bar at the top of the recents table view.
 */
- (void)hideSearchBar:(BOOL)hidden;

@end
