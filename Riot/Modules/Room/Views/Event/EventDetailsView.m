/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "EventDetailsView.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation EventDetailsView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    self.textView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.textView.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.redactButton.tintColor = ThemeService.shared.theme.tintColor;
    self.closeButton.tintColor = ThemeService.shared.theme.tintColor;
}

@end
