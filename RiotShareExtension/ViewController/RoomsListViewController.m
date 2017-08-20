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
#import "RoomTableViewCell.h"
#import "NSBundle+MatrixKit.h"
#import "ShareExtensionManager.h"
#import "RecentCellData.h"
#import "RiotDesignValues.h"
#import "MXKPieChartView.h"
#import "MXKPieChartHUD.h"



@interface RoomsListViewController () <UITableViewDelegate, UISearchBarDelegate, ShareExtensionManagerDelegate>

@property (nonatomic) ShareRecentsDataSource *dataSource;
@property (copy) void (^failureBlock)();

@property (nonatomic) UITableView *mainTableView;
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) MXKPieChartHUD *hudView;

@end


@implementation RoomsListViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureTableView];
    [self configureSearchBar];
}

#pragma mark - Public

+ (instancetype)listViewControllerWithDataSource:(ShareRecentsDataSource *)dataSource failureBlock:(void(^)())failureBlock
{
    RoomsListViewController *listViewController = [[self class] new];
    listViewController.dataSource = dataSource;
    listViewController.failureBlock = failureBlock;
    return listViewController;
}

#pragma mark - Views

- (void)configureTableView
{
    self.mainTableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    self.mainTableView.dataSource = self.dataSource;
    self.mainTableView.delegate = self;
    [self.mainTableView registerNib:[RoomTableViewCell nib] forCellReuseIdentifier:[RoomTableViewCell defaultReuseIdentifier]];
    
    [self.view addSubview:self.mainTableView];
    self.mainTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    
    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, centerXConstraint, centerYConstraint]];
}

- (void)configureSearchBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.placeholder = NSLocalizedStringFromTable(@"search_default_placeholder", @"Vector", nil);
    self.searchBar.tintColor = kRiotColorGreen;
    self.searchBar.showsCancelButton = YES;
    
    self.searchBar.delegate = self;
    
    self.mainTableView.tableHeaderView = self.searchBar;
}

#pragma mark - Private

- (void)showShareAlertForRoomPath:(NSIndexPath *)indexPath
{
    NSString *receipantName = [self.dataSource getRoomAtIndexPath:indexPath].riotDisplayname;
    if (!receipantName.length)
    {
        receipantName = NSLocalizedStringFromTable(@"room_displayname_no_title", @"Vector", nil);
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"send_to", @"Vector", nil), receipantName] message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction *sendAction = [UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"send"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        MXRoom *selectedRoom = [self.dataSource getRoomAtIndexPath:indexPath];
        
        [ShareExtensionManager sharedManager].delegate = self;
        
        [[ShareExtensionManager sharedManager] sendContentToRoom:selectedRoom failureBlock:^{
            [self showFailureAlert];
        }];
    }];
    [alertController addAction:sendAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showFailureAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_event_failed_to_send", @"Vector", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
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
    return [RoomTableViewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self showShareAlertForRoomPath:indexPath];
}

#pragma mark - MXKDataSourceDelegate

- (void)dataSource:(MXKDataSource*)dataSource didCellChange:(id)changes
{
    if (dataSource == self.dataSource)
    {
        [self.mainTableView reloadData];
    }
}

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:[RecentCellData class]])
    {
        return [RoomTableViewCell class];
    }
    return nil;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:[MXKRecentCellData class]])
    {
        return [RoomTableViewCell defaultReuseIdentifier];
    }
    return nil;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length)
    {
        [self.dataSource searchWithPatterns:@[searchText]];
    }
    else
    {
        [self.dataSource searchWithPatterns:nil];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self.dataSource searchWithPatterns:nil];
}

#pragma mark - ShareExtensionManagerDelegate

- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager showImageCompressionPrompt:(UIAlertController *)compressionPrompt
{
    [compressionPrompt popoverPresentationController].sourceView = self.view;
    [compressionPrompt popoverPresentationController].sourceRect = self.view.frame;
    [self presentViewController:compressionPrompt animated:YES completion:nil];
}

- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager didStartSendingContentToRoom:(MXRoom *)room
{
    self.parentViewController.view.userInteractionEnabled = NO;
    self.hudView = [MXKPieChartHUD showLoadingHudOnView:self.view WithMessage:NSLocalizedStringFromTable(@"sending", @"Vector", nil)];
    [self.hudView setProgress:0.0];
}

- (void)shareExtensionManager:(ShareExtensionManager *)extensionManager mediaUploadProgress:(CGFloat)progress
{
    [self.hudView setProgress:progress];
}

@end
