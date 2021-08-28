//
//  YXWalletAccountModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger , YXWalletAccountCellType) {
    YXWalletAccountCellLineType = 0,                 //间隔类型
    YXWalletAccountCellTitleType,                    //标题类型
    YXWalletAccountCellTextFieldType,                //输入宽类型
    YXWalletAccountCellPhotoType,                    //选择图片类型
    YXWalletAccountCellButtomType,                   //按钮类型
    YXWalletAccountCellVerificationCodeType,         //验证码类型
};

typedef NS_ENUM(NSInteger , YXWalletAccountBindingType) {
    YXWalletAccountCardType = 0,                 //银行卡
    YXWalletAccountZFBType,                      //支付宝
    YXWalletAccountWeCharType,                   //微信
  
};

@interface YXWalletAddAccountModel :NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , assign) BOOL              data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

@interface YXWalletAccountOptionsModel : NSObject
@property (nonatomic , copy) NSString *nick;
@property (nonatomic , copy) NSString *name;
@property (nonatomic , copy) NSString *account;
@property (nonatomic , copy) NSString *bank;
@property (nonatomic , copy) NSString *subbranch;
@property (nonatomic , copy) NSString *phone;
@property (nonatomic , copy) NSString *vfCode;
@property (nonatomic , copy) NSString *imageId;
@end

@interface YXWalletAccountModel : NSObject
@property (nonatomic , assign) YXWalletAccountCellType cellType;
@property (nonatomic , assign) YXWalletAccountBindingType bindingType;
@property (nonatomic , assign) CGFloat cellHeight;
@property (nonatomic , assign) BOOL showLine;
@property (nonatomic , copy) NSString *cellName;
@property (nonatomic , copy) NSString *desc;
@property (nonatomic , copy) NSString *name;
@property (nonatomic , copy) NSString *placedholder;
@property (nonatomic , copy) NSString *content;
@property (nonatomic , copy) NSString *nick;
@property (nonatomic , copy) NSString *userName;
@property (nonatomic , copy) NSString *account;
@property (nonatomic , copy) NSString *zfbAccount;
@property (nonatomic , copy) NSString *bank;
@property (nonatomic , copy) NSString *subbranch;
@property (nonatomic , copy) NSString *phone;
@property (nonatomic , copy) NSString *vfCode;

- (NSMutableArray <YXWalletAccountModel *>*)getCellArrayWithBindingType:(YXWalletAccountBindingType)type;

@end

NS_ASSUME_NONNULL_END
