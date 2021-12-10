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

#import <UIKit/UIKit.h>

/**
 `AvatarGenerator` class generate an avatar image from objects
 */
@interface AvatarGenerator : NSObject

/**
 Create a squared UIImage with the text and the background color.
 @param text the text.
 @param color the background color.
 @return the avatar image.
 */
+ (UIImage *)imageFromText:(NSString*)text withBackgroundColor:(UIColor*)color;

/**
 Generate a squared avatar for a matrix item (room, room member...).
 @param itemId the matrix identifier of the item
 @param displayname the item displayname (if nil, the itemId is used by default).
 @return the avatar image
 */
+ (UIImage*)generateAvatarForMatrixItem:(NSString*)itemId withDisplayName:(NSString*)displayname;

/**
 Generate a squared avatar for a matrix item (room, room member...) with a preferred size
 @param itemId the matrix identifier of the item
 @param displayname the item displayname (if nil, the itemId is used by default).
 @param size the expected size of the returned image
 @param fontSize the expected font size
 @return the avatar image
 */
+ (UIImage*)generateAvatarForMatrixItem:(NSString*)itemId withDisplayName:(NSString*)displayname size:(CGFloat)size andFontSize:(CGFloat)fontSize;

/**
 Generate an avatar for a text.
 @param text the text.
 @return the avatar image
 */
+ (UIImage*)generateAvatarForText:(NSString*)text;

/**
 Clear all the resources stored in memory.
 */
+ (void)clear;

@end
