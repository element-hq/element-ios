/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "StickerPickerViewController.h"

#import "IntegrationManagerViewController.h"

#import "GeneratedInterface-Swift.h"

@interface StickerPickerViewController ()

@end

@implementation StickerPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [VectorL10n roomActionSendSticker];

    // Hide back button title
    [self.parentViewController vc_removeBackTitle];

    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditButtonPressed)];
    [self.navigationItem setRightBarButtonItem: editButton animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Make sure the content is up-to-date when we come back from the sticker picker settings screen
    [webView reload];
}

- (void)onEditButtonPressed
{
    // Show the sticker picker settings screen
    IntegrationManagerViewController *modularVC = [[IntegrationManagerViewController alloc]
                                                   initForMXSession:self.roomDataSource.mxSession
                                                   inRoom:self.roomDataSource.roomId
                                                   screen:[IntegrationManagerViewController screenForWidget:kWidgetTypeStickerPicker]
                                                   widgetId:self.widget.widgetId];

    [self presentViewController:modularVC animated:NO completion:nil];
}

@end
