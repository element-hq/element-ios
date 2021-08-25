//
//  YXWalletCashModel.m
//  lianliao
//
//  Created by 廖燊 on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCashModel.h"

@implementation YXWalletCashCreateData

@end

@implementation YXWalletCashCreateModel

@end

@implementation YXWalletCashRecordsItem

@end


@implementation YXWalletCashOrdersItem

@end


@implementation YXWalletCashData
+ (NSDictionary *)mj_objectClassInArray{
    return @{
        @"orders":[YXWalletCashOrdersItem class],
        @"records":[YXWalletCashRecordsItem class]
    };
}
@end


@implementation YXWalletCashExampleModelName

@end

@implementation YXWalletCashModel
- (NSMutableArray <YXWalletCashModel *>*)getCellArray{
    
    NSMutableArray *array = [NSMutableArray array];

//    [array addObject:[self createModelWithCellName:@"YXWalletCodeAssetsSelectCell" cellHeight:60 desc:@"VCL" name:@"资产种类" content:nil placedholder:@"" showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:30 desc:nil name:nil content:nil placedholder:nil showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXWalletCashCardTableViewCell" cellHeight:50 desc:@"**** 9941 储蓄卡" name:@"中国银行" content:nil placedholder:nil showLine:NO bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:15 desc:nil name:nil content:nil placedholder:nil showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXWalletCashTitleTableViewCell" cellHeight:60 desc:@"￥0.7476" name:@"当前价值" content:nil placedholder:nil showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXWalletCashTitleTableViewCell" cellHeight:60 desc:@"6%" name:@"手续费" content:nil placedholder:nil showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXWalletCashTextFieldTableViewCell" cellHeight:60 desc:@"" name:@"VCL" content:nil placedholder:@"输入兑换数量" showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXWalletCashNoteTableViewCell" cellHeight:160 desc:@"全部" name:@"备注" content:@"可兑换数量600.54 VCL" placedholder:@"输入备注信息（选填）" showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:45 desc:nil name:nil content:nil placedholder:nil showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXWalletCopyTableViewCell" cellHeight:40 desc:nil name:@"确认兑现" content:nil placedholder:nil showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    
    return array;
}

- (NSMutableArray <YXWalletCashModel *>*)getAddCardCellArray{
    
    NSMutableArray *array = [NSMutableArray array];

    
    [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:30 desc:nil name:nil content:nil placedholder:nil showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXWalletCashCardTableViewCell" cellHeight:70 desc:@"**** 9941 储蓄卡" name:@"中国银行" content:nil placedholder:nil showLine:YES bindingType:YXWalletAccountCardType selectCard:YES]];
    
    [array addObject:[self createModelWithCellName:@"YXWalletCashCardTableViewCell" cellHeight:70 desc:@"138***666@.qq.com" name:@"支付宝" content:nil placedholder:nil showLine:YES bindingType:YXWalletAccountCardType selectCard:NO]];
    
    [array addObject:[self createModelWithCellName:@"YXWalletCashCardTableViewCell" cellHeight:70 desc:@"zheli diaoyongde shenmmingzi" name:@"微信支付" content:nil placedholder:nil showLine:NO bindingType:YXWalletAccountCardType selectCard:NO]];
    
    
    return array;
}

- (YXWalletCashModel *)createModelWithCellName:(NSString *)cellName
                                    cellHeight:(CGFloat)cellheight
                                          desc:(NSString *)desc
                                          name:(NSString *)name
                                       content:(NSString *)content
                                  placedholder:(NSString *)placedholder
                                      showLine:(BOOL)showLine
                                   bindingType:(YXWalletAccountBindingType)bindingType
                                    selectCard:(BOOL)selectCard
{
    YXWalletCashModel *model = [[YXWalletCashModel alloc]init];
    model.cellName = cellName;
    model.cellHeight = cellheight;
    model.desc = desc;
    model.name = name;
    model.content = content;
    model.placedholder = placedholder;
    model.showLine = showLine;
    model.bindingType = bindingType;
    model.selectCard = selectCard;
    return model;
}

@end
