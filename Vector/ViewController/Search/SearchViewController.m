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

#import "SearchViewController.h"

#import "RecentsViewController.h"
#import "RecentsDataSource.h"

@interface SearchViewController ()
{
    // The search bar 
    UISearchBar *searchBar;

    // The view controller used under the "rooms" tab.
    // This is a RecentsViewController which is used only for its search feature.
    // This means that the search is done locally
    RecentsViewController *roomsSearchViewController;
    RecentsDataSource *roomsSearchDataSource;
}

@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    searchBar = [[UISearchBar alloc] initWithFrame:self.navigationController.navigationBar.frame];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBar.showsCancelButton = YES;
    searchBar.returnKeyType = UIReturnKeyDone; // UIReturnKeySearch
    searchBar.delegate = self;

    self.navigationItem.leftBarButtonItem = [UIBarButtonItem new];
    self.navigationItem.titleView = searchBar;

    // This is a VC for searching. So, show the keyboard with the VC
    [searchBar becomeFirstResponder];
}

- (void)displayWithSession:(MXSession *)session
{
    NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
    NSMutableArray* titles = [[NSMutableArray alloc] init];

    [titles addObject: NSLocalizedStringFromTable(@"Rooms", @"Vector", nil)];
    roomsSearchViewController = [RecentsViewController recentListViewController];
    roomsSearchDataSource = [[RecentsDataSource alloc] initWithMatrixSession:session];
    [roomsSearchViewController displayList:roomsSearchDataSource];
    [viewControllers addObject:roomsSearchViewController];

    [titles addObject: NSLocalizedStringFromTable(@"Messages", @"Vector", nil)];
    RecentsViewController *recentsViewController = [RecentsViewController recentListViewController];
    RecentsDataSource *recentlistDataSource = [[RecentsDataSource alloc] initWithMatrixSession:session];
    [recentsViewController displayList:recentlistDataSource];
    [viewControllers addObject:recentsViewController];

    [titles addObject: NSLocalizedStringFromTable(@"People", @"Vector", nil)];
    /*RecentsViewController**/ recentsViewController = [RecentsViewController recentListViewController];
    /*RecentsDataSource **/recentlistDataSource = [[RecentsDataSource alloc] initWithMatrixSession:session];
    [recentsViewController displayList:recentlistDataSource];
    [viewControllers addObject:recentsViewController];

    //segmentedViewController.title = NSLocalizedStringFromTable(@"room_details_title", @"Vector", nil);
    [self initWithTitles:titles viewControllers:viewControllers defaultSelected:0];

    // to display a red navbar when the home server cannot be reached.
    [self addMatrixSession:session];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (self.displayedViewController == roomsSearchViewController)
    {
        // As the search is local, it can be updated on each text change
        if (searchText.length)
        {
            [roomsSearchDataSource searchWithPatterns:@[searchText]];
        }
        else
        {
            [roomsSearchDataSource searchWithPatterns:nil];
        }
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar2
{
    // "Done" key has been pressed
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar2
{
    // Leave search
    [searchBar resignFirstResponder];

    // Leave this VC
    [self.navigationController popViewControllerAnimated:YES];
}
@end
