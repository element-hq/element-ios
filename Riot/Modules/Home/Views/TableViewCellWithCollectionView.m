/*
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

#import "TableViewCellWithCollectionView.h"
#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

static CGFloat const kEditionViewCornerRadius = 10.0;

@implementation TableViewCellWithCollectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.editionViewHeightConstraint.constant = 0;
    self.editionViewBottomConstraint.constant = 0;
    
    self.editionView.layer.masksToBounds = YES;
    
    // Hide both the cell and its collection view from voiceover.
    // Instead we expose the individual cells as accessibility elements.
    self.isAccessibilityElement = NO;
    self.collectionView.isAccessibilityElement = NO;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.collectionView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.editionView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.collectionView.tag = -1;
    self.collectionView.dataSource = nil;
    self.collectionView.delegate = nil;
    
    self.editionViewHeightConstraint.constant = 0;
    self.editionViewBottomConstraint.constant = 0;
    self.editionView.hidden = YES;
    
    self.collectionView.scrollEnabled = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.editionView.layer.cornerRadius = kEditionViewCornerRadius;
}

@end

