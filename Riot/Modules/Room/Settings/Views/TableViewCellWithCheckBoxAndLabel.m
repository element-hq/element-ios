/*
 Copyright 2016 OpenMarket Ltd
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

