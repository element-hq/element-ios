/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKErrorViewModel.h"

@interface MXKErrorViewModel()

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *message;

@end

@implementation MXKErrorViewModel

- (id)initWithTitle:(NSString*)title message:(NSString*)message
{
    self = [super init];

    if (self)
    {
        _title = title;
        _message = message;
    }

    return self;
}

@end
