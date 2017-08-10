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


@interface RoomsListViewController () <UITableViewDelegate>

@property (nonatomic) ShareRecentsDataSource *dataSource;
@property (copy) void (^failureBlock)();

@property (nonatomic) UITableView *mainTableView;

@end


@implementation RoomsListViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureTableView];
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
    widthConstraint.active = YES;
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    heightConstraint.active = YES;
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    centerXConstraint.active = YES;
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:self.mainTableView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    centerYConstraint.active = YES;
}

#pragma mark - Private

- (void)showFailureAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"room_event_failed_to_send", @"Vector", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.failureBlock)
        {
            self.failureBlock();
            [[ShareExtensionManager sharedManager] cancelSharing];
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
        [[ShareExtensionManager sharedManager] sendContentToRoom:selectedRoom failureBlock:^{
            [self showFailureAlert];
        }];
    }];
    [alertController addAction:sendAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
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
    if ([cellData isKindOfClass:[MXKRecentCellData class]])
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

@end
