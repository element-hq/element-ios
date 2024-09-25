/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKCollectionViewCell.h"

@implementation MXKCollectionViewCell

+ (UINib *)nib
{
    // Check whether a nib file is available
    NSBundle *mainBundle = [NSBundle bundleForClass:self.class];
    NSString *path = [mainBundle pathForResource:NSStringFromClass([self class]) ofType:@"nib"];
    if (path)
    {
        return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:mainBundle];
    }
    return nil;
}

+ (NSString*)defaultReuseIdentifier
{
    return NSStringFromClass([self class]);
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self customizeCollectionViewCellRendering];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self customizeCollectionViewCellRendering];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    // Check whether a xib is defined
    if ([[self class] nib])
    {
        self = [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
        self.frame = frame;
    }
    else
    {
        self = [super initWithFrame:frame];
        [self customizeCollectionViewCellRendering];
    }
    
    return self;
}

- (void)customizeCollectionViewCellRendering
{
    // Do nothing by default.
}

@end

