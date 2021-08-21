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

typedef NS_ENUM(NSInteger , YXAssetsDetailRecordsStatue) {
    YXAssetsDetailRecordsStatueCanceldeal = -1,//取消交易
    YXAssetsDetailRecordsStatueUnfinished = 0,//未完成
    YXAssetsDetailRecordsStatueFinished = 2,//完成
};

@interface YXAssetsDetailRecordsItem :NSObject
@property (nonatomic , copy) NSString              * ID;
@property (nonatomic , copy) NSString              * txId;
@property (nonatomic , copy) NSString              * txHash;
@property (nonatomic , copy) NSString              * walletId;
@property (nonatomic , copy) NSString              * action;
@property (nonatomic , copy) NSString              * type;
@property (nonatomic , copy) NSString              * addr;
@property (nonatomic , copy) NSString              * message;
@property (nonatomic , assign) CGFloat              amount;
@property (nonatomic , assign) CGFloat              fees;
@property (nonatomic , copy) NSString              * coinDate;
@property (nonatomic , copy) NSString              * baseSybol;
@property (nonatomic , assign) YXAssetsDetailRecordsStatue              status;
@property (nonatomic , assign) NSInteger              flag;

@end


@interface YXAssetsDetailOrdersItem :NSObject

@end


@interface YXAssetsDetailData :NSObject
@property (nonatomic , strong) NSArray <YXAssetsDetailRecordsItem *>              * records;
@property (nonatomic , strong) NSArray <YXAssetsDetailRecordsItem *>              * unProcess;

@end



@interface YXAssetsDetailListModel : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) YXAssetsDetailData              * data;
@property (nonatomic , assign) BOOL              actualSucess;

@end

NS_ASSUME_NONNULL_END
