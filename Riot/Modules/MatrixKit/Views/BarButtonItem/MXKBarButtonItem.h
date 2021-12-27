/*
 Copyright 2018 New Vector Ltd
 
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

#pragma mark - Imports

@import Foundation;
@import UIKit;

#pragma mark - Types

typedef void (^MXKBarButtonItemAction)(void);

#pragma mark - Interface

/**
 `MXKBarButtonItem` is a subclass of UIBarButtonItem allowing to use convenient action block instead of action selector.
 */
@interface MXKBarButtonItem : UIBarButtonItem

#pragma mark - Instance Methods

- (instancetype)initWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style action:(MXKBarButtonItemAction)action;
- (instancetype)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style action:(MXKBarButtonItemAction)action;

@end
