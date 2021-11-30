/*
 Copyright 2015 OpenMarket Ltd

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

@interface PublicRoomTableViewCell : MXKPublicRoomTableViewCell

/**
 Configure the cell in order to display the public room.

 @param publicRoom the public room to render.
 */
- (void)render:(MXPublicRoom*)publicRoom withMatrixSession:(MXSession*)mxSession;

@property (weak, nonatomic) IBOutlet MXKImageView *roomAvatar;

/**
 Get the cell height.
 
 @return the cell height.
 */
+ (CGFloat)cellHeight;

@end
