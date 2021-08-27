//
//  YXWalletSendModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger , YXWalletSendCellType) {
    YXWalletSendCellTypeLine = 0,                   //间隔类型
    YXWalletSendCellTypeSelect,                     //选择资产类型
    YXWalletSendCellTypeTextField,                  //输入宽类型
    YXWalletSendCellTypeNone,                       //空白类型
    YXWalletSendCellTypeNext,                       //下一步类型
    YXWalletSendCellTypeAddress,                    //地址
    YXWalletSendCellTypeClose,                      //关闭
    YXWalletSendCellTypeContent,                    //确认交易内容
    YXWalletSendCellTypTopView,                     //确认交易头部
    YXWalletSendCellTypCenterView,                  //确认交易中间分隔
    YXWalletSendCellTypBottomView,                  //确认交易底部
};


@interface YXWalletSendFirendDataItem :NSObject
@property (nonatomic , copy) NSString              * url;
@property (nonatomic , copy) NSString              * nickName;
@property (nonatomic , copy) NSString              * walletAddr;
@end


@interface YXWalletSendFirendModel :NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) NSArray <YXWalletSendFirendDataItem *>              * data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

@interface YXWalletSendDataInfo : NSObject
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
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , assign) NSInteger              flag;
@property (nonatomic , copy) NSString              * title;
@end

@interface YXWalletSendConfirmPayModel : NSObject

@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , copy) NSString              * path;
@property (nonatomic , assign) BOOL               data;
@property (nonatomic , assign) BOOL              actualSucess;

@end

@interface YXWalletSendDataModel : NSObject

@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) YXWalletSendDataInfo              * data;
@property (nonatomic , assign) BOOL              actualSucess;

@end

@interface YXWalletSendModel : NSObject
@property (nonatomic , assign) YXWalletSendCellType cellType;
@property (nonatomic , assign) CGFloat cellHeight;
@property (nonatomic , assign) BOOL showLine;
@property (nonatomic , copy) NSString *cellName;
@property (nonatomic , copy) NSString *desc;
@property (nonatomic , copy) NSString *name;
@property (nonatomic , copy) NSString *placedholder;
@property (nonatomic , copy) NSString *content;
@property (nonatomic , copy) NSString *title;
@property (nonatomic , strong) YXWalletSendDataInfo *sendDataInfo;
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *currentSelectModel;
- (NSMutableArray <YXWalletSendModel *>*)getSendData;
- (NSMutableArray <YXWalletSendModel *>*)getConfirmationData:(YXWalletSendDataInfo *)model;

@end




NS_ASSUME_NONNULL_END
