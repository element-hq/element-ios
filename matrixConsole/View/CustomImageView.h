/*
 Copyright 2014 OpenMarket Ltd
 
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

// Customize UIImageView in order to let UIImageView handle automatically remote url
@interface CustomImageView : UIView<UIScrollViewDelegate>

typedef void (^blockCustomImageView_onClick)(CustomImageView *imageView, NSString* title);

@property (strong, nonatomic) NSString *placeholder;
@property (strong, nonatomic) NSString *imageURL;

// Use this boolean to hide activity indicator during image downloading
@property (nonatomic) BOOL hideActivityIndicator;

// Information about the media represented by this image (image, video...)
@property (strong, nonatomic) NSDictionary *mediaInfo;

@property (strong, nonatomic) UIImage *image;
@property (nonatomic) BOOL canBeZoomed;

// Let the user defines some custom buttons over the tabbar
- (void)setLeftButtonTitle :leftButtonTitle handler:(blockCustomImageView_onClick)handler;
- (void)setRightButtonTitle:rightButtonTitle handler:(blockCustomImageView_onClick)handler;

- (void)dismissSelection;

@end

