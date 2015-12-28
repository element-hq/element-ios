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


#import "VectorViewController.h"

@interface VectorViewController ()
{
    // Backup of view when displaying search
    UIView *backupTitleView;
    UIBarButtonItem *backupLeftBarButtonItem;
    UIBarButtonItem *backupRightBarButtonItem;
}

@end

@implementation VectorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Search bar
    _searchBar = [[UISearchBar alloc] init];
    _searchBar.showsCancelButton = YES;
    _searchBar.delegate = self;
}

#pragma mark - Search

- (void)showSearch:(BOOL)animated
{
    // Backup screen header before displaying the search bar in it
    backupTitleView = self.navigationItem.titleView;
    backupLeftBarButtonItem = self.navigationItem.leftBarButtonItem;
    backupRightBarButtonItem = self.navigationItem.rightBarButtonItem;

    // Reset searches
    self.searchBar.text = @"";

    // Remove navigation buttons
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.leftBarButtonItem = nil;

    // Add the search bar and
    self.navigationItem.titleView = self.searchBar;
    [self.searchBar becomeFirstResponder];
}

- (void)hideSearch:(BOOL)animated
{
    // Restore the screen header
    if (backupLeftBarButtonItem)
    {
        self.navigationItem.titleView = backupTitleView;
        self.navigationItem.leftBarButtonItem = backupLeftBarButtonItem;
        self.navigationItem.rightBarButtonItem = backupRightBarButtonItem;
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar2
{
    // "Search" key has been pressed
    [self.searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar2
{
    [self hideSearch:YES];
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar2
{
    // Keep the search bar cancel button enabled even if the keyboard is not displayed
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *subView in self.searchBar.subviews)
        {
            for (UIView *view in subView.subviews)
            {
                if ([view isKindOfClass:[UIButton class]])
                {
                    [(UIButton *)view setEnabled:YES];
                }
            }
        }
    });
    return YES;
}

@end
