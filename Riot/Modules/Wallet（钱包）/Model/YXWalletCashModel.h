//
//  YXWalletCashModel.h
//  lianliao
//
//  Created by 廖燊 on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YXWalletAccountModel.h"
#import "YXWalletPaymentAccountModel.h"
NS_ASSUME_NONNULL_BEGIN


@interface YXWalletCashRecordsItem :NSObject
@property (nonatomic , copy) NSString              * id;
@property (nonatomic , copy) NSString              * walletId;
@property (nonatomic , copy) NSString              * accoutId;
@property (nonatomic , copy) NSString              * userId;
@property (nonatomic , copy) NSString              * amount;
@property (nonatomic , copy) NSString              * cashFees;
@property (nonatomic , copy) NSString              * message;
@property (nonatomic , copy) NSString              * transcationId;
@property (nonatomic , copy) NSString              * createDate;
@property (nonatomic , assign) NSInteger              flag;
@property (nonatomic , assign) NSInteger              status;

@end


@interface YXWalletCashOrdersItem :NSObject

@end


@interface YXWalletCashData :NSObject
@property (nonatomic , strong) NSArray <YXWalletCashRecordsItem *>              * records;
@property (nonatomic , assign) NSInteger              total;
@property (nonatomic , assign) NSInteger              size;
@property (nonatomic , assign) NSInteger              current;
@property (nonatomic , strong) NSArray <YXWalletCashOrdersItem *>              * orders;
@property (nonatomic , assign) BOOL              optimizeCountSql;
@property (nonatomic , assign) BOOL              hitCount;
@property (nonatomic , assign) BOOL              searchCount;
@property (nonatomic , assign) NSInteger              pages;

@end


@interface YXWalletCashExampleModelName :NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) YXWalletCashData              * data;
@property (nonatomic , assign) BOOL              actualSucess;

@end

@interface YXWalletCashModel : NSObject
@property (nonatomic , assign) YXWalletAccountBindingType bindingType;
@property (nonatomic , assign) CGFloat cellHeight;
@property (nonatomic , assign) BOOL showLine;
@property (nonatomic , assign) BOOL selectCard;
@property (nonatomic , copy) NSString *cellName;
@property (nonatomic , copy) NSString *desc;
@property (nonatomic , copy) NSString *name;
@property (nonatomic , copy) NSString *placedholder;
@property (nonatomic , copy) NSString *content;
@property (nonatomic , strong) YXWalletMyWalletRecordsItem *walletModel;
@property (nonatomic , strong) YXWalletPaymentAccountRecordsItem *accountModel;
- (NSMutableArray <YXWalletCashModel *>*)getCellArray;
- (NSMutableArray <YXWalletCashModel *>*)getAddCardCellArray;
@end

NS_ASSUME_NONNULL_END
