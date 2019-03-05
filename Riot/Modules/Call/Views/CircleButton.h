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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CircleButton : UIButton

/**
 Background color that is used for highlighted state
 
 By default the same as borderColor
 */
@property (nonatomic) UIColor *highlightBackgroundColor;

/**
 Background color that is used for normal state
 
 By default white
 */
@property (nonatomic) UIColor *defaultBackgroundColor;

/**
 Tint color that is used for highlighted state
 
 By default is white
 */
@property (nonatomic) UIColor *highlightTintColor;

/**
 Tint color that is used for normal state
 
 By default is the same as borderColor
 */
@property (nonatomic) UIColor *defaultTintColor;

- (instancetype)initWithImage:(UIImage *)image borderColor:(UIColor *)borderColor;

@end

NS_ASSUME_NONNULL_END
