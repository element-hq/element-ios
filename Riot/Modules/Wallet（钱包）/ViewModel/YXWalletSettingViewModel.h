//
//  YXWalletSettingViewModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXWalletSettingModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletSettingViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)void (^touchSettingBlock)(YXWalletSettingModel *model);
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *model;
- (void)reloadNewData:(BOOL)isWalletSetting andModel:(YXWalletMyWalletRecordsItem *)model;
- (void)getWalletHelpWord:(NSString *)walletId complete:(nullable void (^)(NSDictionary *responseObject))complete;
- (void)deleteWalletHelpWord:(NSString *)walletId complete:(nullable void (^)(NSDictionary *responseObject))complete;
///修改密码
- (void)walletChangePassword:(NSString *)userId
                    Password:(NSString *)password
                    complete:(nullable void (^)(NSDictionary *responseObject))complete;
@end

NS_ASSUME_NONNULL_END
