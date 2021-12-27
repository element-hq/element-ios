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

#import "MXKBarButtonItem.h"

#pragma mark - Private Interface

@interface MXKBarButtonItem ()

#pragma mark - Private Properties

@property (nonatomic, copy) MXKBarButtonItemAction actionBlock;

@end

#pragma mark - Implementation

@implementation MXKBarButtonItem

#pragma mark - Public methods

- (instancetype)initWithImage:(UIImage *)image style:(UIBarButtonItemStyle)style action:(MXKBarButtonItemAction)action
{
    self = [self initWithImage:image style:style target:self action:@selector(executeAction:)];
    if (self)
    {
        self.actionBlock = action;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style action:(MXKBarButtonItemAction)action
{
    self = [self initWithTitle:title style:style target:self action:@selector(executeAction:)];
    if (self)
    {
        self.actionBlock = action;
    }
    return self;
}

#pragma mark - Private methods

- (void)executeAction:(id)sender
{
    if (self.actionBlock)
    {
        self.actionBlock();
    }
}

@end
