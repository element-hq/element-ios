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

@interface YXWalletPaymentAccountOptions :NSObject
@property (nonatomic , copy) NSString              * bank;
@property (nonatomic , copy) NSString              * name;
@property (nonatomic , copy) NSString              * phone;
@property (nonatomic , copy) NSString              * account;
@property (nonatomic , copy) NSString              * subbranch;

@end


@interface YXWalletPaymentAccountRecordsItem :NSObject
@property (nonatomic , copy) NSString              * ID;
@property (nonatomic , copy) NSString              * userId;
@property (nonatomic , copy) NSString              * type;
@property (nonatomic , copy) NSString              * acquiescence;
@property (nonatomic , copy) NSString              * coinDate;
@property (nonatomic , assign) NSInteger              flag;
@property (nonatomic , strong) YXWalletPaymentAccountOptions              * options;
@property (nonatomic , assign) BOOL isDetail;//详情需要隐藏默认设置按钮
@property (nonatomic , copy) NSString *title;
@end


@interface YXWalletPaymentAccountOrdersItem :NSObject

@end


@interface YXWalletPaymentAccountData :NSObject
@property (nonatomic , strong) NSArray <YXWalletPaymentAccountRecordsItem *>              * records;
@property (nonatomic , assign) NSInteger              total;
@property (nonatomic , assign) NSInteger              size;
@property (nonatomic , assign) NSInteger              current;
@property (nonatomic , strong) NSArray <YXWalletPaymentAccountOrdersItem *>              * orders;
@property (nonatomic , assign) BOOL              optimizeCountSql;
@property (nonatomic , assign) BOOL              hitCount;
@property (nonatomic , assign) BOOL              searchCount;
@property (nonatomic , assign) NSInteger              pages;

@end

@interface YXWalletPaymentAccountModel : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) YXWalletPaymentAccountData              * data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

NS_ASSUME_NONNULL_END
