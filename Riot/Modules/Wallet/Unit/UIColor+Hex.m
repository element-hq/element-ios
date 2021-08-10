//
//  UIColor+Hex.m
//  LCCar
//
//  Created by 夏桂峰 on 15/12/22.
//  Copyright (c) 2015年 夏桂峰. All rights reserved.
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)


+ (UIColor *)colorWithHex:(NSUInteger)hex {
    float b=(hex&0xFF)/255.f;
    float g=((hex>>8) & 0xFF)/255.f;
    float r=((hex >> 16) & 0xFF)/255.f;
    float a=hex> 0xFFFFFF ? ((hex>>24)& 0xFF)/255.f : 1.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

+ (UIColor *)colorWithHex:(NSUInteger)hex alpha:(CGFloat)alpha {
    float b=(hex&0xFF)/255.f;
    float g=((hex>>8) & 0xFF)/255.f;
    float r=((hex >> 16) & 0xFF)/255.f;
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

+ (UIColor *)colorWithHexString:(NSString *)string {
    if (nil == string || 0 == string.length) {
        return nil;
    }
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([string hasPrefix:@"rgb("] && [string hasSuffix:@")"]) {
        string = [string substringWithRange:NSMakeRange(4, string.length - 5)];
        if (string && string.length) {
            NSArray * elems = [string componentsSeparatedByString:@","];
            if (elems && elems.count == 3) {
                NSInteger r = [[elems objectAtIndex:0] integerValue];
                NSInteger g = [[elems objectAtIndex:1] integerValue];
                NSInteger b = [[elems objectAtIndex:2] integerValue];
                return [UIColor colorWithRed:(r * 1.0f / 255.0f) green:(g * 1.0f / 255.0f) blue:(b * 1.0f / 255.0f) alpha:1.0f];
            }
        }
    }
    NSArray *array = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *color = [array objectAtIndex:0];
    CGFloat alpha = 1.0f;
    if (array.count == 2) {
        alpha = [[array objectAtIndex:1] floatValue];
    }
    if ( [color hasPrefix:@"#"] ) {// #FFF
        color = [color substringFromIndex:1];
        if ( color.length == 3 ) {
            NSUInteger hexRGB = strtol(color.UTF8String , nil, 16);
            return [UIColor fromShortHexValue:hexRGB alpha:alpha];
        } else if ( color.length == 6 ) {
            NSUInteger hexRGB = strtol(color.UTF8String , nil, 16);
            return [UIColor fromHexValue:hexRGB alpha:alpha];
        }
    } else if ( [color hasPrefix:@"0x"] || [color hasPrefix:@"0X"] ) {// #FFF
        color = [color substringFromIndex:2];
        if ( color.length == 8 ) {
            NSUInteger hexRGB = strtol(color.UTF8String , nil, 16);
            return [UIColor fromHexValue:hexRGB];
        } else if ( color.length == 6 ) {
            NSUInteger hexRGB = strtol(color.UTF8String , nil, 16);
            return [UIColor fromHexValue:hexRGB alpha:1.0f];
        }
    }
    return nil;
}


+ (UIColor *)fromHexValue:(NSUInteger)hex {
    NSUInteger a = ((hex >> 24) & 0x000000FF);
    float fa = ((0 == a) ? 1.0f : (a * 1.0f) / 255.0f);

    return [UIColor fromHexValue:hex alpha:fa];
}

+ (UIColor *)fromHexValue:(NSUInteger)hex alpha:(CGFloat)alpha {
    NSUInteger r = ((hex >> 16) & 0x000000FF);
    NSUInteger g = ((hex >> 8) & 0x000000FF);
    NSUInteger b = ((hex >> 0) & 0x000000FF);
    float fr = (r * 1.0f) / 255.0f;
    float fg = (g * 1.0f) / 255.0f;
    float fb = (b * 1.0f) / 255.0f;

    return [UIColor colorWithRed:fr green:fg blue:fb alpha:alpha];
}

+ (UIColor *)fromShortHexValue:(NSUInteger)hex {
    return [UIColor fromShortHexValue:hex alpha:1.0f];
}

+ (UIColor *)fromShortHexValue:(NSUInteger)hex alpha:(CGFloat)alpha {
    NSUInteger r = ((hex >> 8) & 0x0000000F);
    NSUInteger g = ((hex >> 4) & 0x0000000F);
    NSUInteger b = ((hex >> 0) & 0x0000000F);

    float fr = (r * 1.0f) / 15.0f;
    float fg = (g * 1.0f) / 15.0f;
    float fb = (b * 1.0f) / 15.0f;

    return [UIColor colorWithRed:fr green:fg blue:fb alpha:alpha];
}



+ (NSString*)colorTo16Hex:(UIColor*)color {
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    int rgb = (int) (r * 255.0f)<<16 | (int) (g * 255.0f)<<8 | (int) (b * 255.0f)<<0;
    return [NSString stringWithFormat:@"#%06x", rgb];
}
@end
