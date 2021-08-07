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
@interface YXWalletCreateModel : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , assign) BOOL              data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

@interface YXWalletHelpWordModel : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) NSArray <NSString *>              * data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

@interface YXWalletCoinDataModel : NSObject
@property (nonatomic , copy) NSString              * ID;
@property (nonatomic , copy) NSString              * coinName;
@property (nonatomic , copy) NSString              * symbol;
@property (nonatomic , copy) NSString              * image;
@property (nonatomic , copy) NSString              * baseSymbol;
@property (nonatomic , copy) NSString              * destroyAddr;
@property (nonatomic , copy) NSString              * bwsUrl;
@property (nonatomic , copy) NSString              * customerUrl;
@property (nonatomic , copy) NSString              * username;
@property (nonatomic , copy) NSString              * password;
@property (nonatomic , copy) NSString              * signature;
@property (nonatomic , assign) NSInteger              rpcPort;
@property (nonatomic , assign) NSInteger              p2pPort;
@property (nonatomic , assign) CGFloat              minWithdrawCount;
@property (nonatomic , assign) CGFloat              minWithdrawAmount;
@property (nonatomic , copy) NSString              * enable;
@property (nonatomic , copy) NSString              * useNode;
@property (nonatomic , copy) NSString              * coinDate;
@property (nonatomic , assign) NSInteger              flag;
@end

@interface YXWalletCoinModel : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) NSArray <YXWalletCoinDataModel *>              * data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

NS_ASSUME_NONNULL_END
