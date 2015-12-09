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

#import "HomeViewController.h"

#import "RecentsDataSource.h"
#import "RecentsViewController.h"

@interface HomeViewController ()
{
    // The search bar
    UISearchBar *searchBar;

    RecentsViewController *recentsViewController;
    RecentsDataSource *recentsDataSource;

    // Backup of view when displaying search
    UIView *backupTitleView;
    UIBarButtonItem *backupLeftBarButtonItem;
    UIBarButtonItem *backupRightBarButtonItem;
}

@end

@implementation HomeViewController

- (void)viewDidLoad
{
    // Set up the SegmentedVC tabs before calling [super viewDidLoad]
    MXSession *session = self.mxSessions[0];

    NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
    NSMutableArray* titles = [[NSMutableArray alloc] init];

    [titles addObject: NSLocalizedStringFromTable(@"Rooms", @"Vector", nil)];
    recentsViewController = [RecentsViewController recentListViewController];
    recentsDataSource = [[RecentsDataSource alloc] initWithMatrixSession:session];
    [recentsViewController displayList:recentsDataSource];
    [viewControllers addObject:recentsViewController];

    [titles addObject: NSLocalizedStringFromTable(@"Messages", @"Vector", nil)];
    MXKViewController *tempMessagesVC = [[MXKViewController alloc] init];
    [viewControllers addObject:tempMessagesVC];

    [titles addObject: NSLocalizedStringFromTable(@"People", @"Vector", nil)];
    MXKViewController *tempPeopleVC = [[MXKViewController alloc] init];
    [viewControllers addObject:tempPeopleVC];

    [self initWithTitles:titles viewControllers:viewControllers defaultSelected:0];

    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedStringFromTable(@"recents", @"Vector", nil);

    // Search bar
    searchBar = [[UISearchBar alloc] init];
    searchBar.showsCancelButton = YES;
    searchBar.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Let's child display the loading not the home view controller
    [self.activityIndicator stopAnimating];
    self.activityIndicator = nil;

    [self hideSearch:NO];

    // TODO: a dedicated segmented viewWillAppear may be more appropriate
    [self.displayedViewController viewWillAppear:animated];
}

- (void)displayWithSession:(MXSession *)session
{
    // to display a red navbar when the home server cannot be reached.
    [self addMatrixSession:session];
}


- (void)showSearch:(BOOL)animated
{
    backupTitleView = self.navigationItem.titleView;
    backupLeftBarButtonItem = self.navigationItem.leftBarButtonItem;
    backupRightBarButtonItem = self.navigationItem.rightBarButtonItem;

    // Remove navigation buttons
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.leftBarButtonItem = nil;

    // Add the search bar and
    self.navigationItem.titleView = searchBar;
    [searchBar becomeFirstResponder];

    // Show the tabs header
    if (animated)
    {
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{

                             self.selectionContainerHeightConstraint.constant = 44;
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                             
                         }];
    }
    else
    {
        self.selectionContainerHeightConstraint.constant = 44;
        [self.view layoutIfNeeded];
    }
}

- (void)hideSearch:(BOOL)animated
{
    if (backupLeftBarButtonItem)
    {
        self.navigationItem.titleView = backupTitleView;
        self.navigationItem.leftBarButtonItem = backupLeftBarButtonItem;
        self.navigationItem.rightBarButtonItem = backupRightBarButtonItem;
    }

    // Hide the tabs header
    if (animated)
    {
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{

                             self.selectionContainerHeightConstraint.constant = 0;
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished){

                             // Go back under the recents tab
                             // TODO: Open the feature in SegmentedVC
                         }];
    }
    else
    {
        self.selectionContainerHeightConstraint.constant = 0;
        [self.view layoutIfNeeded];

        // Go back under the recents tab
        // TODO: Open the feature in SegmentedVC
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - User's actions

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == _searchBarButtonIem)
    {
        [self showSearch:YES];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self hideSearch:YES];
}

@end
