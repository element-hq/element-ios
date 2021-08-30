//
//  YXNodeDetailViewModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"
#import "YXNodeListModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXNodeDetailViewModel : YXBaseViewModel
@property (nonatomic , strong)YXNodeConfigModelPledeg *pledegModel;
@property (nonatomic , strong)YXNodeListdata *nodeInfoModel;
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)dispatch_block_t getNodeInfoBlock;
@property (nonatomic , copy)dispatch_block_t getNodePledegBlock;
@property (nonatomic , copy)dispatch_block_t activationNodeBlock;
@property (nonatomic , copy)dispatch_block_t walletArmingFlagNodeBlock;
@property (nonatomic , copy)void (^jumpNodeDetailBlock)(id model);
- (void)reloadNewData:(YXNodeListdata *)model;
- (void)getPledegTxData:(YXNodeListdata *)model;//获取质押交易记录
- (void)getNodeInfo:(YXNodeListdata *)model;//获取节点信息
- (void)pledgeUnfreezeNode:(YXNodeListdata *)model
                  Complete:(void (^)(void))complete;//解冻质押
- (void)configNodeActivityWalletId:(NSString *)walletId
                              txid:(NSString *)txid
                              vout:(NSString *)vout
                                ip:(NSString *)ip
                        privateKey:(NSString *)privateKey
                          Complete:(void (^)(void))complete;//重新激活节点
@end

NS_ASSUME_NONNULL_END

