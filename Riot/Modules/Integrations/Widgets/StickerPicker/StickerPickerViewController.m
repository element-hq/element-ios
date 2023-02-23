/*
 Copyright 2018 New Vector Ltd

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
