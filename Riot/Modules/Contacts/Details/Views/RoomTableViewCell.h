/*
 Copyright 2016 OpenMarket Ltd

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

/**
 The `RoomTableViewCell` cell displays a room (avatar and displayname).
 */
@interface RoomTableViewCell : MXKTableViewCell

@property (weak, nonatomic) IBOutlet MXKImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *encryptedRoomIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

/**
 Update the information displayed by the cell.
 
 @param room the room to render.
 */
- (void)render:(MXRoom *)room;

/**
 Get the cell height.

 @return the cell height.
 */
+ (CGFloat)cellHeight;

@end
