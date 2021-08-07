//
//  YXWalletSettingModel.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSettingModel.h"
@implementation YXWalletSettingPasswordModel
@end

@implementation YXWalletSettingModel
- (NSMutableArray <YXWalletSettingModel *>*)getSettingData:(BOOL)isWalletSetting{
    NSMutableArray *array = [NSMutableArray array];
    if (isWalletSetting) {
        [array addObject:[self createModelWithName:@"显示助记词" andDes:@"" isCenter:NO andType:YXWalletSettingXSZJQType]];
        [array addObject:[self createModelWithName:@"显示私钥" andDes:@"" isCenter:NO andType:YXWalletSettingXSSYType]];
    }else{
        [array addObject:[self createModelWithName:@"收款账户" andDes:@"" isCenter:NO andType:YXWalletSettingSKZHType]];
        [array addObject:[self createModelWithName:@"钱包密码" andDes:@"未设置" isCenter:NO andType:YXWalletSettingQBMMType]];
        [array addObject:[self createModelWithName:@"关于我们" andDes:@"当前版本V2.0.0" isCenter:NO andType:YXWalletSettingGYWMType]];
        [array addObject:[self createModelWithName:@"帮助反馈" andDes:@"" isCenter:NO andType:YXWalletSettingBZFKType]];
    }



    return array;
}

- (NSMutableArray <YXWalletSettingModel *>*)getDeleteData:(BOOL)isWalletSetting{
    NSMutableArray *array = [NSMutableArray array];
    if (isWalletSetting) {
        [array addObject:[self createModelWithName:@"删除钱包" andDes:@"" isCenter:YES andType:YXWalletSettingSCQBType]];
        [array addObject:[self createModelWithName:@"同步数据（上次同步：2021-03-06）" andDes:@"" isCenter:YES andType:YXWalletSettingTBJLType]];
    }
    return array;
}

- (YXWalletSettingModel *)createModelWithName:(NSString *)name andDes:(NSString *)des isCenter:(BOOL)center andType:(YXWalletSettingType)type{
    YXWalletSettingModel *model = [[YXWalletSettingModel alloc]init];
    model.title = name;
    model.des = des;
    model.isCenter = center;
    model.type = type;
    return model;
}

-(void)setType:(YXWalletSettingType)type{
    _type = type;
}

@end
