//
//  UIView+Extension.m
//
//  Created by 张磊 on 14-11-14.
//  Copyright (c) 2014年 com.zixue101.www. All rights reserved.
//

#import "UIView+ZLExtension.h"

@implementation UIView (Extension)

- (void)setZl_x:(CGFloat)x{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}
- (CGFloat)zl_x{
    return self.frame.origin.x;
}
- (void)setZl_y:(CGFloat)y{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}
- (CGFloat)zl_y{
    return self.frame.origin.y;
}
- (void)setZl_centerX:(CGFloat)centerX{
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}
- (CGFloat)zl_centerX{
    return self.center.x;
}

- (void)setZl_centerY:(CGFloat)centerY{
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}
- (CGFloat)zl_centerY{
    return self.center.y;
}

- (void)setZl_width:(CGFloat)width{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}
- (CGFloat)zl_width{
    return self.frame.size.width;
}

- (void)setZl_height:(CGFloat)height{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}
- (CGFloat)zl_height{
    return self.frame.size.height;
}

- (void)setZl_size:(CGSize)size{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}
- (CGSize)zl_size{
    return self.frame.size;
}

@end
