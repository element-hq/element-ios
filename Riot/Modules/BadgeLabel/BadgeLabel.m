// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "BadgeLabel.h"

@implementation BadgeLabel

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.height / 2;
}

- (CGSize)intrinsicContentSize
{
    CGSize intrinsicSize = [super intrinsicContentSize];
    intrinsicSize.height = MAX(intrinsicSize.height + self.padding.height, intrinsicSize.height) + self.borderWidth / 2;
    intrinsicSize.width = MAX(intrinsicSize.width + self.padding.width, intrinsicSize.height);
    return intrinsicSize;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGRect backgroundRect = CGRectInset(self.bounds, self.borderWidth / 2, self.borderWidth / 2);
    CGFloat cornerRadius = backgroundRect.size.height / 2;
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:backgroundRect cornerRadius:cornerRadius];
    CGContextAddPath(context, [path CGPath]);
    CGContextSetLineWidth(context, self.borderWidth);
    CGContextSetStrokeColorWithColor(context, [self.borderColor CGColor]);
    CGContextSetFillColorWithColor(context, [self.badgeColor CGColor]);
    
    if (self.borderWidth > 0)
    {
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    else
    {
        CGContextDrawPath(context, kCGPathFill);
    }
    
    CGContextRestoreGState(context);
    
    [super drawRect:rect];
}

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    [self setupView];
}

- (void)setupView
{
    self.badgeColor = UIColor.redColor;
    self.borderWidth = 0;
    self.borderColor = UIColor.whiteColor;
    self.padding = CGSizeMake(10, 2);
    self.textAlignment = NSTextAlignmentCenter;
    self.textColor = UIColor.whiteColor;
}

@end
