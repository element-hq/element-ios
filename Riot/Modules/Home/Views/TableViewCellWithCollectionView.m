/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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

