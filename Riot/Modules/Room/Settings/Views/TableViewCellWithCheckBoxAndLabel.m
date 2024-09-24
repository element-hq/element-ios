/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

#import "TableViewCellWithCheckBoxAndLabel.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation TableViewCellWithCheckBoxAndLabel

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    _label.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.checkBox.tintColor = ThemeService.shared.theme.tintColor;
}

- (void)setEnabled:(BOOL)enabled
{
    if (enabled)
    {
        _checkBox.image = AssetImages.selectionTick.image;
    }
    else
    {
        _checkBox.image = AssetImages.selectionUntick.image;
    }
    
    _enabled = enabled;
}

@end

