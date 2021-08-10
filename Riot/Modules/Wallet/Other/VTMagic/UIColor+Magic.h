//
//  UIColor+Magic.h
//  VTMagic
//
//  Created by tianzhuo on 15/7/23.
//  Copyright (c) 2015年 tianzhuo. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alph;
} VTColor;

static const VTColor VTColorZero;

CG_INLINE VTColor
VTColorMake(CGFloat red, CGFloat green, CGFloat blue, CGFloat alph)
{
    VTColor color;
    color.red = red; color.green = green;
    color.blue = blue; color.alph = alph;
    return color;
}

CG_INLINE VTColor
VTColorScale(VTColor color, CGFloat scale)
{
    VTColor scaleColor;
    scaleColor.red = color.red * scale;
    scaleColor.green = color.green * scale;
    scaleColor.blue = color.blue * scale;
    scaleColor.alph = color.alph * scale;
    return scaleColor;
}

CG_INLINE VTColor
VTColorAdd(VTColor aColor1, VTColor aColor2)
{
    VTColor finalColor;
    finalColor.red = aColor1.red + aColor2.red;
    finalColor.green = aColor1.green + aColor2.green;
    finalColor.blue = aColor1.blue + aColor2.blue;
    finalColor.alph = aColor1.alph + aColor2.alph;
    return finalColor;
}

CG_INLINE VTColor
VTColorReduce(VTColor aColor, VTColor reductionColor)
{
    VTColor finalColor;
    finalColor.red = aColor.red - reductionColor.red;
    finalColor.green = aColor.green - reductionColor.green;
    finalColor.blue = aColor.blue - reductionColor.blue;
    finalColor.alph = aColor.alph - reductionColor.alph;
    return finalColor;
}

CG_INLINE BOOL
VTColorIsEqual(VTColor aColor1, VTColor aColor2)
{
    if (aColor1.red != aColor2.red) return NO;
    if (aColor1.green != aColor2.green) return NO;
    if (aColor1.blue != aColor2.blue) return NO;
    if (aColor1.alph != aColor2.alph) return NO;
    return YES;
}

CG_INLINE BOOL
VTColorIsZero(VTColor aColor)
{
    return VTColorIsEqual(VTColorZero, aColor);
}

@interface UIColor (Magic)

/**
 *  将UIColor转成对应的RGBA色值
 *
 *  @return VTColor结构体
 */
- (VTColor)vtm_changeToVTColor;

/**
 *  将VTColor转成对应的UIColor
 *
 *  @param color VTColor
 *
 *  @return UIColor对象
 */
+ (UIColor *)vtm_colorWithVTColor:(VTColor)color;

/**
 *  按指定比例对给定的两种颜色进行合成，并返回对应的UIColor对象
 *
 *  @param baseColor 基础颜色
 *  @param anoColor  参考颜色
 *  @param scale     合成比例，scale为0时返回baseColor对应的颜色，scale为1时返回anoColor对应的颜色
 *
 *  @return 合成颜色UIColor对象
 */
+ (UIColor *)vtm_compositeColor:(VTColor)baseColor anoColor:(VTColor)anoColor scale:(CGFloat)scale;

@end
