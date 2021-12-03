/*
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
#import "MXKSessionGroupsDataSource.h"

@class MXKGroupListViewController;

/**
 `MXKGroupListViewController` delegate.
 */
@protocol MXKGroupListViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user selected a group.

 @param groupListViewController the `MXKGroupListViewController` instance.
 @param group the selected group.
 @param mxSession the matrix session in which the group is defined.
 */
- (void)groupListViewController:(MXKGroupListViewController *)groupListViewController didSelectGroup:(MXGroup*)group inMatrixSession:(MXSession*)mxSession;

@end


/**
 This view controller displays a group list.
 */
@interface MXKGroupListViewController : MXKViewController <MXKDataSourceDelegate, UITableViewDelegate, UISearchBarDelegate>
{
@protected
    
    /**
     The fake top view displayed in case of vertical bounce.
     */
    __weak UIView *topview;
}

@property (weak, nonatomic) IBOutlet UISearchBar *groupsSearchBar;
@property (weak, nonatomic) IBOutlet UITableView *groupsTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupsSearchBarTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupsSearchBarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupsTableViewBottomConstraint;

/**
 The current data source associated to the view controller.
 */
@property (nonatomic, readonly) MXKSessionGroupsDataSource *dataSource;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MXKGroupListViewControllerDelegate> delegate;

/**
 Enable the search option by adding a navigation item in the navigation bar (YES by default).
 Set NO this property to disable this option and hide the related bar button.
 */
@property (nonatomic) BOOL enableBarButtonSearch;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKGroupListViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `groupListViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKGroupListViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKGroupListViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)groupListViewController;

/**
 Display the groups described in the provided data source.
 
 Note: The provided data source will replace the current data source if any. The caller
 should dispose properly this data source if it is not used anymore.

 @param listDataSource the data source providing the groups list.
 */
- (void)displayList:(MXKSessionGroupsDataSource*)listDataSource;

/**
 Refresh the groups table display.
 */
- (void)refreshGroupsTable;

/**
 Hide/show the search bar at the top of the groups table view.
 */
- (void)hideSearchBar:(BOOL)hidden;

@end
