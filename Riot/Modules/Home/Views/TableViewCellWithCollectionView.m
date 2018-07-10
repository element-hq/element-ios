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
#import "RiotDesignValues.h"

@implementation TableViewCellWithCollectionView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.editionViewHeightConstraint.constant = 0;
    self.editionViewBottomConstraint.constant = 0;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.editionView.backgroundColor = kRiotSecondaryBgColor;
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

@end

