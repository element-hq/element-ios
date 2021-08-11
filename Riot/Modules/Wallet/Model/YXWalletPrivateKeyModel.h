//
//  YXWalletPrivateKeyModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YXWalletPrivateKeyDataInfo : NSObject
@property (nonatomic , copy) NSString              * address;
@property (nonatomic , copy) NSString              * privateKey;
@property (nonatomic , copy) NSString              * path;
@end

@interface YXWalletPrivateKeyData : NSObject
@property (nonatomic , copy) NSString              * localDateTime;
@property (nonatomic , assign) NSInteger              status;
@property (nonatomic , copy) NSString              * msg;
@property (nonatomic , strong) YXWalletPrivateKeyDataInfo              * data;
@property (nonatomic , assign) BOOL              actualSucess;
@end

@interface YXWalletPrivateKeyModel : NSObject
@property (nonatomic , copy) NSString *des;
@property (nonatomic , copy) NSString *title;
@property (nonatomic , assign) CGFloat cellHeight;
@end

NS_ASSUME_NONNULL_END
