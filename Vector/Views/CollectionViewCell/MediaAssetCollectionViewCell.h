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
 'MediaAssetCollectionViewCell' class is used to display assets from user's photo library.
 */
@interface MediaAssetCollectionViewCell : UICollectionViewCell

/**
 Returns the `UINib` object initialized for the cell.
 
 @return The initialized `UINib` object or `nil` if there were errors during
 initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 The default reuseIdentifier of the 'MediaAssetCollectionViewCell' class.
 */
+ (NSString*)defaultReuseIdentifier;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *selectionImageView;

@end
