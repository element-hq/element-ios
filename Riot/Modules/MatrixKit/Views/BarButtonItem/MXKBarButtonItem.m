/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
