/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "LanguagePickerViewController.h"

#import "GeneratedInterface-Swift.h"

@interface LanguagePickerViewController ()
{
    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    /**
     The fake top view displayed in case of vertical bounce.
     */
    UIView *topview;
}

@end

@implementation LanguagePickerViewController

- (void)finalizeInit
{
    [super finalizeInit];

    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self vc_setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeNever];
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // Add a top view which will be displayed in case of vertical bounce.
    CGFloat height = self.tableView.frame.size.height;
    topview = [[UIView alloc] initWithFrame:CGRectMake(0,-height,self.tableView.frame.size.width,height)];
    topview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.tableView addSubview:topview];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    [ThemeService.shared.theme applyStyleOnSearchBar:self.searchBar];
    
    // Use the primary bg color for the table view in plain style.
    self.tableView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.tableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    topview.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    if (self.tableView.dataSource)
    {
        [self.tableView reloadData];
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)destroy
{
    [super destroy];
    
    [topview removeFromSuperview];
    topview = nil;
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    cell.detailTextLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

@end
