//
//  YXWalletPrivateKeyModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletPrivateKeyModel.h"



@implementation YXWalletPrivateKeyDataInfo ;
@end

@implementation YXWalletPrivateKeyData
@end

@implementation YXWalletPrivateKeyModel

-(CGFloat)cellHeight{
    return [self calculateLabelHeightWith:self.title andWidth:SCREEN_WIDTH - 64 andFont:15];
}

- (CGFloat)calculateLabelHeightWith:(NSString *)text andWidth:(CGFloat)width andFont:(CGFloat)font{
    UILabel *label = [[UILabel alloc]init];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:font];
    label.text = text;
    CGFloat labelHeight = [label sizeThatFits:CGSizeMake(width, MAXFLOAT)].height;
    return labelHeight;
}

@end
