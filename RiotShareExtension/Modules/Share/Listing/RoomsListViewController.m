/*
 Copyright 2017 Aram Sargsyan
 
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

#import "RoomsListViewController.h"
#import "RecentRoomTableViewCell.h"
#import "NSBundle+MatrixKit.h"
#import "ShareExtensionManager.h"
#import "RecentCellData.h"
#import "RiotDesignValues.h"
#import <MatrixKit/MatrixKit.h>

@interface RoomsListViewController () <ShareExtensionManagerDelegate>

@property (nonatomic) MXKPieChartHUD *hudView;

// The fake search bar displayed at the top of the recents table. We switch on the actual search bar (self.recentsSearchBar)
// when the user selects it.
@property (nonatomic) UISearchBar *tableSearchBar;

@end

@implementation RoomsListViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomsListViewController class])
                          bundle:[NSBundle bundleForClass:[RoomsListViewController class]]];
}

+ (instancetype)recentListViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([RoomsListViewController class])
                                          bundle:[NSBundle bundleForClass:[RoomsListViewController class]]];
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.enableBarButtonSearch = NO;
    
    // Create the fake search bar
    _tableSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 600, 44)];
    _tableSearchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _tableSearchBar.showsCancelButton = NO;
    _tableSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    _tableSearchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);
    _tableSearchBar.delegate = self;
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.recentsTableView registerNib:[RecentRoomTableViewCell nib] forCellReuseIdentifier:[RecentRoomTableViewCell defaultReuseIdentifier]];
    
    [self configureSearchBar];
}

- (void)destroy
{
    // Release the room data source
    [self.dataSource destroy];
    
    [super destroy];
}

#pragma mark - Views

- (void)configureSearchBar
{
    self.recentsSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    self.recentsSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.recentsSearchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);
    self.recentsSearchBar.tintColor = kRiotColorGreen;
    
    _tableSearchBar.tintColor = self.recentsSearchBar.tintColor;
}

#pragma mark - Override MXKRecentListViewController

- (void)refreshRecentsTable
{
    [super refreshRecentsTable];
    
    // Check conditions to display the fake search bar into the table header
    if (self.recentsSearchBar.isHidden && self.recentsTableView.tableHeaderView == nil)
    {
        // Add the search bar by showing it by default.
        self.recentsTableView.tableHeaderView = _tableSearchBar;
    }
}

- (void)hideSearchBar:(BOOL)hidden
{
    [super hideSearchBar:hidden];
    
    if (!hidden)
    {
        // Remove the fake table header view if any
        self.recentsTableView.tableHeaderView = nil;
        self.recentsTableView.contentInset = UIEdgeInsetsZero;
    }
}

#pragma mark - Private

- (void)showShareAlertForRoomPath:(NSIndexPath *)indexPath
{
    MXKRecentCellData *recentCellData = [self.dataSource cellDataAtIndexPath:indexPath];
    NSString *roomName = recentCellData.roomSummary.displayname;
    if (!roomName.length)
    {
        roomName = NSLocalizedStringFromTable(@"room_displayname_no_title", @"Vector", nil);
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"send_to", @"Vector", nil), roomName] message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction *sendAction = [UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"send"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        // The selected room is instanciated here
        MXSession *session = [[MXSession alloc] initWithMatrixRestClient:[[MXRestClient alloc] initWithCredentials:[ShareExtensionManager sharedManager].userAccount.mxCredentials andOnUnrecognizedCertificateBlock:nil]];

        [MXFileStore setPreloadOptions:0];

        MXWeakify(session);
        [session setStore:[ShareExtensionManager sharedManager].fileStore success:^{
            MXStrongifyAndReturnIfNil(session);

            MXRoom *selectedRoom = [MXRoom loadRoomFromStore:[ShareExtensionManager sharedManager].fileStore withRoomId:recentCellData.roomSummary.roomId matrixSession:session];

            [ShareExtensionManager sharedManager].delegate = self;

            [[ShareExtensionManager sharedManager] sendContentToRoom:selectedRoom failureBlock:^(NSError* error) {

                NSString *title;
                if ([error.domain isEqualToString:MXEncryptingErrorDomain])
                {
                    title = NSLocalizedStringFromTable(@"share_extension_failed_to_encrypt", @"Vector", nil);
                }

                [self showFailureAlert:title];
            }];

        } failure:^(NSError *error) {

            NSLog(@"[RoomsListViewController] failed to prepare matrix session]");

        }];
    }];
    
    [alertController addAction:sendAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showFailureAlert:(NSString *)title
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title.length ? title : NSLocalizedStringFromTable(@"room_event_failed_to_send", @"Vector", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.failureBlock)
        {
            self.failureBlock();
        }
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [RecentRoomTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self showShareAlertForRoomPath:indexPath];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:[RecentCellData class]])
    {
        return [RecentRoomTableViewCell class];
    }
    return nil;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:[MXKRecentCellData class]])
    {
        return [RecentRoomTableViewCell defaultReuseIdentifier];
    }
    return nil;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSArray *patterns = nil;
    if (searchText.length)
    {
        patterns = @[searchText];
    }
    [self.dataSource searchWithPatterns:patterns];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if (searchBar == _tableSearchBar)
    {
        [self hideSearchBar:NO];
        [self.recentsSearchBar becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.recentsSearchBar setShowsCancelButton:YES animated:NO];
        
    });
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self.recentsSearchBar setShowsCancelButton:NO animated:NO];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    
    if (scrollView == self.recentsTableView)
    {
        if (!self.recentsSearchBar.isHidden)
        {
            if (!self.recentsSearchBar.text.length && (scrollView.contentOffset.y + scrollView.mxk_adjustedContentInset.top > self.recentsSearchBar.frame.size.height))
            {
                // Hide the search bar
                [self hideSearchBar:YES];
                
                // Refresh display
                [self refreshRecentsTable];
            }
        }
    }
}

#pragma mark - ShareExtensionManagerDelegate

- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager showImageCompressionPrompt:(UIAlertController *)compressionPrompt
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [compressionPrompt popoverPresentationController].sourceView = self.view;
        [compressionPrompt popoverPresentationController].sourceRect = self.view.frame;
        [self presentViewController:compressionPrompt animated:YES completion:nil];
    });
}

- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager didStartSendingContentToRoom:(MXRoom *)room
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.hudView)
        {
            self.parentViewController.view.userInteractionEnabled = NO;
            self.hudView = [MXKPieChartHUD showLoadingHudOnView:self.view WithMessage:NSLocalizedStringFromTable(@"sending", @"Vector", nil)];
            [self.hudView setProgress:0.0];
        }
    });
}

- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager mediaUploadProgress:(CGFloat)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.hudView setProgress:progress];
    });
}

@end
