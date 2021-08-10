//
//  YXWalletSettingModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger , YXWalletSettingType) {
    YXWalletSettingSKZHType = 0,    //收款账户
    YXWalletSettingQBMMType,        //钱包密码
    YXWalletSettingXSZJQType,       //显示助记词
    YXWalletSettingXSSYType,        //显示私钥
    YXWalletSettingGYWMType,        //关于我们
    YXWalletSettingBZFKType,        //帮助反馈
    YXWalletSettingSCQBType,        //删除钱包
    YXWalletSettingTBJLType,        //同步数据
};

@interface YXWalletSettingPasswordModel : NSObject

@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , copy) NSString              * data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

@interface YXWalletSettingModel : NSObject
@property (nonatomic , copy) NSString *title;
@property (nonatomic , copy) NSString *des;
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *walletModel;
@property (nonatomic , assign) YXWalletSettingType type;
@property (nonatomic , assign) BOOL isCenter;
- (NSMutableArray <YXWalletSettingModel *>*)getSettingData:(BOOL)isWalletSetting;
- (NSMutableArray <YXWalletSettingModel *>*)getDeleteData:(BOOL)isWalletSetting;
@end

NS_ASSUME_NONNULL_END
