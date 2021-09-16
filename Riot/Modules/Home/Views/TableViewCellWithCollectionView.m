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
#import "Riot-Swift.h"

static CGFloat const kEditionViewCornerRadius = 10.0;
static CGFloat const kCollectionViewContentLeadingInset = 20.0;

@interface TableViewCellWithCollectionView ()

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *collectionViewLeadingConstraint;

@end

@implementation TableViewCellWithCollectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.editionViewHeightConstraint.constant = 0;
    self.editionViewBottomConstraint.constant = 0;
    
    self.editionView.layer.masksToBounds = YES;
    
    // Prevent the horizontal scrolling from clashing with the UISplitViewController pan gesture
    self.collectionView.clipsToBounds = NO;
    self.collectionViewLeadingConstraint.constant = kCollectionViewContentLeadingInset;
    self.collectionView.contentInset = UIEdgeInsetsMake(0.0, -kCollectionViewContentLeadingInset, 0.0, 0.0);
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
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

