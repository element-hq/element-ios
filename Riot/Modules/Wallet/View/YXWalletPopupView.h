//
//  YXWalletPopupView.h
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger , WalletPopupViewType) {
    WalletPopupViewDXCGType = 0,    //兑现-成功
    WalletPopupViewCJCGType,        //钱包创建成功
    WalletPopupViewCXZFType,        //取消支付
    WalletPopupViewSCQBType,        //删除钱包
    WalletPopupViewTJCGType,        //添加收款账户成功
    WalletPopupViewZFCGType,        //支付成功
    WalletPopupViewZFSBType,        //支付失败
    WalletPopupViewJDDQType,        //主节点-节点详情（到期）
    WalletPopupViewPZCGType,        //主节点配置成功
    WalletPopupViewXGCGType,        //修改成功
};

typedef NS_ENUM(NSInteger , WalletPopupViewState) {
    WalletPopupViewSuccessState = 0,
    WalletPopupViewFailState,
    WalletPopupViewWalletState,
};

@interface YXWalletPopupView : UIView
@property (nonatomic , copy)dispatch_block_t determineBlock;
@property (nonatomic , copy)dispatch_block_t cancelBlock;
- (instancetype)initWithFrame:(CGRect)frame type:(WalletPopupViewType)type;
@end

NS_ASSUME_NONNULL_END
