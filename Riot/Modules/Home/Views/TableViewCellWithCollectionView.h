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

#import "MatrixKit.h"

@interface TableViewCellWithCollectionView : MXKTableViewCell

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) IBOutlet UIView *editionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *editionViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *editionViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIButton *directChatButton;
@property (weak, nonatomic) IBOutlet UIImageView *directChatImageView;
@property (weak, nonatomic) IBOutlet UIButton *notificationsButton;
@property (weak, nonatomic) IBOutlet UIImageView *notificationsImageView;
@property (weak, nonatomic) IBOutlet UIButton *favouriteButton;
@property (weak, nonatomic) IBOutlet UIImageView *favouriteImageView;
@property (weak, nonatomic) IBOutlet UIButton *priorityButton;
@property (weak, nonatomic) IBOutlet UIImageView *priorityImageView;
@property (weak, nonatomic) IBOutlet UIButton *leaveButton;
@property (weak, nonatomic) IBOutlet UIImageView *leaveImageView;

@end
