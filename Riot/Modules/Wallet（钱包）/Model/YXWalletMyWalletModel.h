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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger , YXWalletNoteType) {
    YXWalletNoteTypeAll = 0, //查询所有的
    YXWalletNoteTypeConfig, //已经配置
    YXWalletNoteTypeNormal, //状态正常的
    YXWalletNoteTypeDrops, //掉线的
    YXWalletNoteTypeWillConfig, //未配置的
};

@interface YXWalletMyWalletAddressModel : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) NSString              * data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

@interface YXWalletMyWalletAccountInfo :NSObject
@property (nonatomic , copy) NSString              * name;
@property (nonatomic , copy) NSString              * account;
@end

@interface YXWalletMyWalletRecordsItem :NSObject
@property (nonatomic , copy) NSString              * walletId;
@property (nonatomic , copy) NSString              * userId;
@property (nonatomic , copy) NSString              * coinId;
@property (nonatomic , copy) NSString              * walletName;
@property (nonatomic , copy) NSString              * mnemonic;
@property (nonatomic , copy) NSString              * enable;
@property (nonatomic , copy) NSString              * coinDate;
@property (nonatomic , copy) NSString              * modifyDate;
@property (nonatomic , assign) NSInteger              flag;
@property (nonatomic , copy) NSString              * accountId;
@property (nonatomic , copy) NSString              * password;
@property (nonatomic , copy) NSString              * coinName;
@property (nonatomic , copy) NSString              * baseSymbol;
@property (nonatomic , assign) CGFloat              balance;
@property (nonatomic , copy) NSString              * fundValue;
@property (nonatomic , copy) NSString              * image;
@property (nonatomic , copy) NSString              * cashCount;//兑换量
@property (nonatomic , copy) NSString              * cashNoteInfo;//兑现备注
@property (nonatomic , copy) NSString              * address;
@property (nonatomic , copy) NSString              * sendAddress;//发送地址
@property (nonatomic , copy) NSString              * sendCount;//发送数量
@property (nonatomic , copy) NSString              * sendInfo;//发送备注
@property (nonatomic , strong) YXWalletMyWalletAccountInfo              * accountInfo;
@property (nonatomic , copy) NSString              * cashFee;
@property (nonatomic , assign) YXWalletNoteType noteType;
@end
 

@interface YXWalletMyWalletJumpModel : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) YXWalletMyWalletRecordsItem              * data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

@interface YXWalletMyWalletOrdersItem :NSObject

@end


@interface YXWalletMyWalletData :NSObject
@property (nonatomic , strong) NSArray <YXWalletMyWalletRecordsItem *>              * records;
@property (nonatomic , assign) NSInteger              total;
@property (nonatomic , assign) NSInteger              size;
@property (nonatomic , assign) NSInteger              current;
@property (nonatomic , strong) NSArray <YXWalletMyWalletOrdersItem *>              * orders;
@property (nonatomic , assign) BOOL              optimizeCountSql;
@property (nonatomic , assign) BOOL              hitCount;
@property (nonatomic , assign) BOOL              searchCount;
@property (nonatomic , assign) NSInteger              pages;

@end


@interface YXWalletMyWalletModel : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) YXWalletMyWalletData              * data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

NS_ASSUME_NONNULL_END
