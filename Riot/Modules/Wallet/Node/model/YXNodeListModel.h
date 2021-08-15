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

@interface YXNodeConfigDataItem :NSObject
@property (nonatomic , copy) NSString              * address;
@property (nonatomic , assign) NSInteger              satoshis;
@property (nonatomic , assign) NSInteger              amount;
@property (nonatomic , copy) NSString              * scriptPubKey;
@property (nonatomic , copy) NSString              * txid;
@property (nonatomic , assign) NSInteger              vout;
@property (nonatomic , assign) BOOL              locked;
@property (nonatomic , assign) BOOL              coinbase;
@property (nonatomic , assign) NSInteger              confirmations;
@property (nonatomic , copy) NSString              * path;
@property (nonatomic , strong) NSArray <NSString *>              * publicKeys;

@end


@interface YXNodeConfigModelPledeg :NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) NSArray <YXNodeConfigDataItem *>              * data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

@interface YXNodeListdata :NSObject
@property (nonatomic , copy) NSString              * sentinelversion;
@property (nonatomic , copy) NSString              * ip;
@property (nonatomic , copy) NSString              * userId;
@property (nonatomic , copy) NSString              * status;
@property (nonatomic , copy) NSString              * maturityTime;
@property (nonatomic , copy) NSString              * turnoffFlag;
@property (nonatomic , copy) NSString              * country;
@property (nonatomic , assign) BOOL              configuration;
@property (nonatomic , copy) NSString              * lastseen;
@property (nonatomic , copy) NSString              * updateTime;
@property (nonatomic , copy) NSString              * latitude;
@property (nonatomic , copy) NSString              * city;
@property (nonatomic , copy) NSString              * genkey;
@property (nonatomic , copy) NSString              * lastpaidblock;
@property (nonatomic , copy) NSString              * lastSendTime;
@property (nonatomic , copy) NSString              * ID;
@property (nonatomic , copy) NSString              * protocol;
@property (nonatomic , copy) NSString              * longitude;
@property (nonatomic , copy) NSString              * daemonversion;
@property (nonatomic , copy) NSString              * activeseconds;
@property (nonatomic , copy) NSString              * phone;
@property (nonatomic , copy) NSString              * asn;
@property (nonatomic , copy) NSString              * armingFlag;
@property (nonatomic , copy) NSString              * pid;
@property (nonatomic , copy) NSString              * vpsid;
@property (nonatomic , copy) NSString              * createTime;
@property (nonatomic , copy) NSString              * payee;
@property (nonatomic , copy) NSString              * orderId;
@property (nonatomic , copy) NSString              * sentinelstate;
@property (nonatomic , copy) NSString              * walletId;
@property (nonatomic , assign) BOOL maturity;//是否到期
@end

@interface YXNodeListModel : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , strong) NSNumber              * status;
@property (nonatomic , strong) NSArray <YXNodeListdata *>             * data;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , copy) NSString              * path;
@property (nonatomic , strong) NSNumber              * actualSucess;
@end

@interface YXNodeActivityModel : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , strong) NSNumber              * status;
@property (nonatomic , strong) id               data;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , copy) NSString              * path;
@property (nonatomic , strong) NSNumber              * actualSucess;
@end

NS_ASSUME_NONNULL_END
