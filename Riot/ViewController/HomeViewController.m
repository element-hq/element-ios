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

#import "HomeViewController.h"

#import "AppDelegate.h"

#import "RecentsDataSource.h"

@implementation HomeViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.screenName = @"Home";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.accessibilityIdentifier = @"HomeVCView";
    self.recentsTableView.accessibilityIdentifier = @"HomeVCTableView";
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_home", @"Vector", nil);
    
    // Add room creation button programatically
    [self addRoomCreationButton];
    
//    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
//    self.searchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        // Take the lead on the shared data source.
        RecentsDataSource *recentsDataSource = (RecentsDataSource*)self.dataSource;
        recentsDataSource.areSectionsShrinkable = YES;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeHome];
    }
}

- (void)dealloc
{
    
}

- (void)destroy
{
    [super destroy];
}

//#pragma mark - Search
//
//- (void)showSearch:(BOOL)animated
//{
//    [super showSearch:animated];
//    
//    // Reset searches
//    [recentsDataSource searchWithPatterns:nil];
//
//    createNewRoomImageView.hidden = YES;
//    tableViewMaskLayer.hidden = YES;
//
//    [self updateSearch];
//    
//    // Screen tracking (via Google Analytics)
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    if (tracker)
//    {
//        [tracker set:kGAIScreenName value:@"RoomsGlobalSearch"];
//        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
//    }
//}
//
//- (void)hideSearch:(BOOL)animated
//{
//    [super hideSearch:animated];
//
//    createNewRoomImageView.hidden = self.isHidden;
//    tableViewMaskLayer.hidden = NO;
//    self.backgroundImageView.hidden = YES;
//
//    [recentsDataSource searchWithPatterns:nil];
//
//    recentsDataSource.hideRecents = NO;
//    recentsDataSource.hidePublicRoomsDirectory = YES;
//    
//    // Screen tracking (via Google Analytics)
//    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
//    if (tracker)
//    {
//        NSString *currentScreenName = [tracker get:kGAIScreenName];
//        if (!currentScreenName || ![currentScreenName isEqualToString:@"RoomsList"])
//        {
//            [tracker set:kGAIScreenName value:@"RoomsList"];
//            [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
//        }
//    }
//}
//
//// Update search results under the currently selected tab
//- (void)updateSearch
//{
//    if (self.searchBar.text.length)
//    {
//        recentsDataSource.hideRecents = NO;
//        recentsDataSource.hidePublicRoomsDirectory = NO;
//        self.backgroundImageView.hidden = YES;
//
//        // Forward the search request to the data source
//        if (self.selectedViewController == recentsViewController)
//        {
//            // Do a AND search on words separated by a space
//            NSArray *patterns = [self.searchBar.text componentsSeparatedByString:@" "];
//
//            [recentsDataSource searchWithPatterns:patterns];
//            recentsViewController.shouldScrollToTopOnRefresh = YES;
//        }
//        else if (self.selectedViewController == messagesSearchViewController)
//        {
//            // Launch the search only if the keyboard is no more visible
//            if (!self.searchBar.isFirstResponder)
//            {
//                // Do it asynchronously to give time to messagesSearchViewController to be set up
//                // so that it can display its loading wheel
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [messagesSearchDataSource searchMessages:self.searchBar.text force:NO];
//                    messagesSearchViewController.shouldScrollToBottomOnRefresh = YES;
//                });
//            }
//        }
//        else if (self.selectedViewController == peopleSearchViewController)
//        {
//            [peopleSearchViewController searchWithPattern:self.searchBar.text forceReset:NO complete:^{
//                
//                [self checkAndShowBackgroundImage];
//                
//            }];
//        }
//        else if (self.selectedViewController == filesSearchViewController)
//        {
//            // Launch the search only if the keyboard is no more visible
//            if (!self.searchBar.isFirstResponder)
//            {
//                // Do it asynchronously to give time to filesSearchViewController to be set up
//                // so that it can display its loading wheel
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [filesSearchDataSource searchMessages:self.searchBar.text force:NO];
//                    filesSearchViewController.shouldScrollToBottomOnRefresh = YES;
//                });
//            }
//        }
//    }
//    else
//    {
//        // Nothing to search, show only the public dictionary
//        recentsDataSource.hideRecents = YES;
//        recentsDataSource.hidePublicRoomsDirectory = NO;
//        
//        // Reset search result (if any)
//        [recentsDataSource searchWithPatterns:nil];
//        if (messagesSearchDataSource.searchText.length)
//        {
//            [messagesSearchDataSource searchMessages:nil force:NO];
//        }
//        
//        [peopleSearchViewController searchWithPattern:nil forceReset:NO complete:^{
//            
//            [self checkAndShowBackgroundImage];
//            
//        }];
//        
//        if (filesSearchDataSource.searchText.length)
//        {
//            [filesSearchDataSource searchMessages:nil force:NO];
//        }
//    }
//    
//    [self checkAndShowBackgroundImage];
//}
//
//#pragma mark - UISearchBarDelegate
//
//- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
//{
//    if (self.selectedViewController == recentsViewController)
//    {
//        // As the public room search is local, it can be updated on each text change
//        [self updateSearch];
//    }
//    else if (self.selectedViewController == peopleSearchViewController)
//    {
//        // As the contact search is local, it can be updated on each text change
//        [self updateSearch];
//    }
//    else if (!self.searchBar.text.length)
//    {
//        // Reset message search if any
//        [self updateSearch];
//    }
//}
//
//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
//{
//    [searchBar resignFirstResponder];
//    
//    if (self.selectedViewController == messagesSearchViewController || self.selectedViewController == filesSearchViewController)
//    {
//        // As the messages/files search is done homeserver-side, launch it only on the "Search" button
//        [self updateSearch];
//    }
//}

#pragma mark - Actions

- (void)onRoomCreationButtonPressed
{
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismiss:NO];
    
    currentAlert = [[MXKAlert alloc] initWithTitle:nil message:nil style:MXKAlertStyleActionSheet];
    
    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_recents_start_chat_with", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;
        
        [strongSelf performSegueWithIdentifier:@"presentStartChat" sender:strongSelf];
    }];
    
    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_recents_create_empty_room", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;
        
        [strongSelf createAnEmptyRoom];
    }];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleCancel handler:^(MXKAlert *alert) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;
    }];
    
    currentAlert.sourceView = createNewRoomImageView;
    
    currentAlert.mxkAccessibilityIdentifier = @"HomeVCCreateRoomAlert";
    [currentAlert showInViewController:self];
}

@end
