//
//  UIColor+Magic.m
//  VTMagic
//
//  Created by tianzhuo on 15/7/23.
//  Copyright (c) 2015年 tianzhuo. All rights reserved.
//

#import "UIColor+Magic.h"
#import "VTCommon.h"

@implementation UIColor (Magic)

- (VTColor)vtm_changeToVTColor
{
    VTColor color;
    if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [self getRed:&color.red green:&color.green blue:&color.blue alpha:&color.alph];
    } else {
        VTLog(@"change UIColor to VTColor error");
    }
    return color;
}

+ (UIColor *)vtm_colorWithVTColor:(VTColor)color
{
    return [UIColor colorWithRed:color.red green:color.green blue:color.blue alpha:color.alph];
}

+ (UIColor *)vtm_compositeColor:(VTColor)baseColor anoColor:(VTColor)anoColor scale:(CGFloat)scale
{
    VTColor diffColor = VTColorReduce(anoColor, baseColor);
    VTColor offsetColor = VTColorScale(diffColor, scale);
    return [self vtm_colorWithVTColor:VTColorAdd(baseColor, offsetColor)];
}

@end
