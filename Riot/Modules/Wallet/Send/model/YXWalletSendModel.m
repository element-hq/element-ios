//
//  YXWalletSendModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSendModel.h"


@implementation YXWalletSendFirendDataItem
@end


@implementation YXWalletSendFirendModel
+ (NSDictionary *)mj_objectClassInArray{
    return @{
        @"data":[YXWalletSendFirendDataItem class],
    };
}
@end

@implementation YXWalletSendConfirmPayModel
@end
@implementation YXWalletSendDataInfo
+ (NSDictionary *)mj_replacedKeyFromPropertyName
{
    return @{
        @"ID" : @"id",
        @"coinDate" : @"newDate",
        
    };
}
@end

@implementation YXWalletSendDataModel
@end

@implementation YXWalletSendModel

- (NSMutableArray <YXWalletSendModel *>*)getSendData{
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:[self createModelWithCellName:@"YXWalletTipCloaseTableViewCell" cellHeight:25 cellType:YXWalletSendCellTypeClose desc:@"发送您的资产前请先确认您的周围环境安全！" name:nil placedholder:nil title:nil content:nil]];
    [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:15 cellType:YXWalletSendCellTypeLine desc:nil name:nil placedholder:nil title:nil content:nil]];
    [array addObject:[self createModelWithCellName:@"YXWalletAssetsSelectTableViewCell" cellHeight:90 cellType:YXWalletSendCellTypeSelect desc:@"VCL" name:@"资产种类" placedholder:@"VCL总余额：2000.00 VCL" title:nil content:nil]];
    [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:15 cellType:YXWalletSendCellTypeLine desc:nil name:nil placedholder:nil title:nil content:nil]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendAddressTableViewCell" cellHeight:100 cellType:YXWalletSendCellTypeAddress desc:nil name:@"钱包地址" placedholder:@"请输入收款钱包地址" title:nil content:nil]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendTextFieldTableViewCell" cellHeight:100 cellType:YXWalletSendCellTypeTextField desc:@"（可用：1000 VCL）" name:@"发送数量" placedholder:@"请输入发送数量" title:nil content:nil]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendTextFieldTableViewCell" cellHeight:100 cellType:YXWalletSendCellTypeTextField desc:@"（选填）" name:@"备注信息" placedholder:@"请输入备注信息" title:nil content:nil]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendNextTableViewCell" cellHeight:110 cellType:YXWalletSendCellTypeNext desc:nil name:@"下一步" placedholder:nil title:nil content:nil]];
    
    return array;
}

- (NSMutableArray <YXWalletSendModel *>*)getConfirmationData:(YXWalletSendDataInfo *)model{
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:30 cellType:YXWalletSendCellTypeLine desc:nil name:nil placedholder:nil title:nil content:nil]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendCellTypTopViewCell" cellHeight:150 cellType:YXWalletSendCellTypTopView desc:@"≈￥0.0007" name:nil placedholder:nil title:@"-0.001 VCL" content:nil]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendCellTypeContentCell" cellHeight:80 cellType:YXWalletSendCellTypeContent desc:@"" name:nil placedholder:nil title:@"交易类型" content:@"转账"]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendCellTypeContentCell" cellHeight:80 cellType:YXWalletSendCellTypeContent desc:@"" name:nil placedholder:nil title:@"接收地址" content:@"MW4a6de6a5s465fef13f46dg6rey6S"]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendCellTypeContentCell" cellHeight:80 cellType:YXWalletSendCellTypeContent desc:@"VCL" name:nil placedholder:nil title:@"手续费" content:@"手续费"]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendCellTypCenterViewCell" cellHeight:60 cellType:YXWalletSendCellTypeContent desc:@"" name:nil placedholder:nil title:@"" content:@""]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendCellTypeContentCell" cellHeight:80 cellType:YXWalletSendCellTypeContent desc:@"VCL" name:nil placedholder:nil title:@"交易单号" content:@"90b48d55-09cb-405f-b32f-e6ad44b7934b"]];
    [array addObject:[self createModelWithCellName:@"YXWalletSendCellTypBottomViewCell" cellHeight:80 cellType:YXWalletSendCellTypBottomView desc:@"VCL" name:nil placedholder:nil title:@"交易单号" content:@"90b48d55-09cb-405f-b32f-e6ad44b7934b"]];
    [array addObject:[self createModelWithCellName:@"YXLineTableViewCell" cellHeight:30 cellType:YXWalletSendCellTypeLine desc:nil name:nil placedholder:nil title:nil content:nil]];
    
    if (![model.title isEqualToString:@"交易详情"]) {
        [array addObject:[self createModelWithCellName:@"YXWalletCopyTableViewCell" cellHeight:40 cellType:YXWalletSendCellTypeLine desc:nil name:nil placedholder:nil title:[model.action isEqualToString:@"pending"] ? @"继续支付" : @"确认支付" content:nil]];
    }

    
    return array;
}

- (YXWalletSendModel *)createModelWithCellName:(NSString *)cellName
                                    cellHeight:(CGFloat)cellheight
                                      cellType:(YXWalletSendCellType)type desc:(NSString *)desc
                                          name:(NSString *)name
                                  placedholder:(NSString *)placedholder
                                         title:(NSString *)title
                                       content:(NSString *)content{
    YXWalletSendModel *model = [[YXWalletSendModel alloc]init];
    model.cellName = cellName;
    model.cellHeight = cellheight;
    model.cellType = type;
    model.desc = desc;
    model.name = name;
    model.placedholder = placedholder;
    model.title = title;
    model.content = content;
    return model;
}

@end


