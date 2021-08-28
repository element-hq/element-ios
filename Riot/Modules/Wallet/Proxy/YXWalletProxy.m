//
//  YXWalletProxy.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletProxy.h"
NSString *const kYXWalletNextCloseTipView = @"kYXWalletNextCloseTipView";
NSString *const kYXWalletHelpWordCloseTipView = @"kYXWalletHelpWordCloseTipView";
NSString *const kYXJumpWalletAssetsDetail = @"kYXJumpWalletAssetsDetail";
NSString *const kYXConfigNodeListForDetail = @"kYXConfigNodeListForDetail";
NSString *const kYXArmingFlagNodeListForDetail = @"kYXArmingFlagNodeListForDetail";
NSString *const kYXWalletShowAddViewFountion = @"kYXWalletShowAddViewFountion";
NSString *const kYXWalletJumpSendEditDetail = @"kYXWalletJumpSendEditDetail";
NSString *const kYXWalletJumpReceiveCodeVC = @"kYXWalletJumpReceiveCodeVC";
NSString *const kYXWalletJumpCashVC = @"kYXWalletJumpCashVC";
NSString *const kYXWalletShowSelectAssetsView = @"kYXWalletShowSelectAssetsView";
NSString *const kYXWalletJumpContactDetail = @"kYXWalletJumpContactDetail";
NSString *const kYXWalletReceiveCodeSelectAssets = @"kYXWalletReceiveCodeSelectAssets";
NSString *const kYXWalletSendNextAction = @"kYXWalletSendNextAction";
NSString *const kYXWalletJumpContactView = @"kYXWalletJumpContactView";
NSString *const kYXWalletJumpScanView = @"kYXWalletJumpScanView";
NSString *const kYXWalletAccountSettingDefault = @"kYXWalletAccountSettingDefault";
NSString *const kYXNodeSelectConfig = @"kYXNodeSelectConfig";
NSString *const kYXWalleBindingAccount = @"kYXWalleBindingAccount";
NSString *const kYXWalletAddAccountSelectPhoto = @"kYXWalletAddAccountSelectPhoto";
NSString *const kYXWalletAddAccountUnBinding = @"kYXWalletAddAccountUnBinding";
NSString *const kYXWalletConfirmToCash = @"kYXWalletConfirmToCash";
NSString *const kYXWalletCopyHelpWord = @"kYXWalletCopyHelpWord";
NSString *const kYXWalletPrivateKeyNext = @"kYXWalletPrivateKeyNext";
NSString *const kYXWalletPrivateKeyCopy = @"kYXWalletPrivateKeyCopy";
NSString *const kYXWalletRefreshAddress = @"kYXWalletRefreshAddress";
NSString *const kYXWalletSendConfirmPay = @"kYXWalletSendConfirmPay";
NSString *const kYXWalletActivationNode = @"kYXWalletActivationNode";
NSString *const kYXWalletArmingFlagNode = @"kYXWalletArmingFlagNode";
@interface YXWalletProxy ()
@property (nonatomic, strong) NSDictionary *tempEventProxy;
@end

@implementation YXWalletProxy
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.eventStrategy = self.tempEventProxy;
    }
    return self;
}

- (NSDictionary *)tempEventProxy{
    if (!_tempEventProxy) {
        _tempEventProxy = @{
            kYXWalletNextCloseTipView:[self createInvocationForSelector:@selector(walletNextCloseTipView:)],
            kYXWalletShowAddViewFountion:[self createInvocationForSelector:@selector(walletShowAddViewFountion)],
            kYXWalletHelpWordCloseTipView:[self createInvocationForSelector:@selector(walletHelpWordCloseTipView:)],
            kYXJumpWalletAssetsDetail:[self createInvocationForSelector:@selector(jumpWalletAssetsDetail)],
            kYXArmingFlagNodeListForDetail:[self createInvocationForSelector:@selector(armingFlagNodeListForDetail:)],
            kYXConfigNodeListForDetail:[self createInvocationForSelector:@selector(configNodeListForDetail:)],
            kYXWalletJumpSendEditDetail:[self createInvocationForSelector:@selector(jumpSendEditDetail)],
            kYXWalletJumpReceiveCodeVC:[self createInvocationForSelector:@selector(jumpReceiveCodeDetail)],
            kYXWalletJumpCashVC:[self createInvocationForSelector:@selector(JumpCashVCDetail)],
            kYXWalletShowSelectAssetsView:[self createInvocationForSelector:@selector(showSelectAssetsView)],
            kYXWalletJumpContactDetail:[self createInvocationForSelector:@selector(jumpContactDetail)],
            kYXWalletReceiveCodeSelectAssets:[self createInvocationForSelector:@selector(receiveCodeSelectAssets)],
            kYXWalletSendNextAction:[self createInvocationForSelector:@selector(sendNextAction:)],
            kYXWalletJumpContactView:[self createInvocationForSelector:@selector(jumpContactViewAction)],
            kYXWalletJumpScanView:[self createInvocationForSelector:@selector(jumpScanViewAction)],
            kYXWalletAccountSettingDefault:[self createInvocationForSelector:@selector(walletAccountSettingDefault:)],
            kYXNodeSelectConfig:[self createInvocationForSelector:@selector(nodeSelectConfig:)],
            kYXWalleBindingAccount:[self createInvocationForSelector:@selector(walleBindingAccount)],
            kYXWalletAddAccountSelectPhoto:[self createInvocationForSelector:@selector(walletAddAccountSelectPhoto)],
            kYXWalletAddAccountUnBinding:[self createInvocationForSelector:@selector(walletAddAccountUnBinding)],
            kYXWalletConfirmToCash:[self createInvocationForSelector:@selector(walletConfirmToCash)],
            kYXWalletCopyHelpWord:[self createInvocationForSelector:@selector(walletCopyHelpWord)],
            kYXWalletPrivateKeyNext:[self createInvocationForSelector:@selector(walletPrivateKeyNext)],
            kYXWalletPrivateKeyCopy:[self createInvocationForSelector:@selector(walletPrivateKeyCopy)],
            kYXWalletRefreshAddress:[self createInvocationForSelector:@selector(refreshAddress)],
            kYXWalletSendConfirmPay:[self createInvocationForSelector:@selector(walletSendConfirmPay)],
            kYXWalletActivationNode:[self createInvocationForSelector:@selector(walletActivationNode)],
            kYXWalletArmingFlagNode:[self createInvocationForSelector:@selector(walletArmingFlagNode)],
        };
    }
    return _tempEventProxy;
}

-(void)walletNextCloseTipView:(UITableViewCell *)cell{
    [self.viewModel closeTipView:cell];
}

-(void)walletShowAddViewFountion{
    if (self.walletViewModel.showAddViewBlock) {
        self.walletViewModel.showAddViewBlock();
    }
}

-(void)jumpSendEditDetail{
    if (self.walletViewModel.jumpSendEditDetailBlock) {
        self.walletViewModel.jumpSendEditDetailBlock();
    }
}

-(void)jumpReceiveCodeDetail{
    if (self.walletViewModel.jumpReceiveCodeBlock) {
        self.walletViewModel.jumpReceiveCodeBlock();
    }
}

-(void)JumpCashVCDetail{
    if (self.walletViewModel.jumpCashVCDetailBlock) {
        self.walletViewModel.jumpCashVCDetailBlock();
    }
}



-(void)walletHelpWordCloseTipView:(UITableViewCell *)cell{
    [self.viewModel closeTipView:cell];
}

-(void)jumpWalletAssetsDetail{
    [self.assetsDetailViewModel jumpNodeListVc];
}

-(void)configNodeListForDetail:(id)model{
    if (self.nodeListViewModel.configNodeListForDetailBlock) {
        self.nodeListViewModel.configNodeListForDetailBlock(model);
    }
}

-(void)armingFlagNodeListForDetail:(id)model{
    if (self.nodeListViewModel.touchNodeListForDetailBlock) {
        self.nodeListViewModel.touchNodeListForDetailBlock(model);
    }
}

-(void)showSelectAssetsView{
    if (self.sendViewModel.showSelectAssetsViewBlock) {
        self.sendViewModel.showSelectAssetsViewBlock();
    }
}

-(void)jumpContactDetail{
    if (self.sendViewModel.jumpContactDetailBlock) {
        self.sendViewModel.jumpContactDetailBlock();
    }
}

//扫码
-(void)jumpScanViewAction{
    if (self.sendViewModel.jumpScanViewBlock) {
        self.sendViewModel.jumpScanViewBlock();
    }
}

//联系人
-(void)jumpContactViewAction{
    if (self.sendViewModel.jumpContactViewBlock) {
        self.sendViewModel.jumpContactViewBlock();
    }
}

-(void)sendNextAction:(id)model{
    [self.sendViewModel nextSendOperation];

}

-(void)receiveCodeSelectAssets{
    if (self.receiveCodeViewModel.showSelectAssetsViewBlock) {
        self.receiveCodeViewModel.showSelectAssetsViewBlock();
    }
}

//设置默认账户
- (void)walletAccountSettingDefault:(YXWalletPaymentAccountRecordsItem *)model{
    [self.paymentAccountViewModel walletAccountSettingDefault:model];
}

- (void)nodeSelectConfig:(YXWalletMyWalletRecordsItem *)model{
    [self.nodeListViewModel reloadNewData:model];
}

//绑定账户
- (void)walleBindingAccount{
    [self.addAcountEditViewModel walleBindingAccount];
}

- (void)walletAddAccountSelectPhoto{
    [self.addAcountEditViewModel walletAddAccountSelectPhoto];
}

//解除绑定
- (void)walletAddAccountUnBinding{
    [self.accountDetailViewModel walletAddAccountUnBinding];
}

//确认兑现
- (void)walletConfirmToCash{
    [self.cashViewModel walletConfirmToCash];
}

- (void)walletCopyHelpWord{
    [self.HelpWordVM walletCopyHelpWord];
}

- (void)walletPrivateKeyNext{
    [self.viewModel walletPrivateKeyNext];
}

- (void)walletPrivateKeyCopy{
    [self.viewModel walletPrivateKeyCopy];
}

//刷新地址
- (void)refreshAddress{
    if (self.receiveCodeViewModel.refreshAddressBlock) {
        self.receiveCodeViewModel.refreshAddressBlock();
    }
}

//确认支付
- (void)walletSendConfirmPay{
    [self.sendViewModel walletSendConfirmPay];
}

//重新激活节点
- (void)walletActivationNode{
    if (self.detailViewModel.activationNodeBlock) {
        self.detailViewModel.activationNodeBlock();
    }
}

- (void)walletArmingFlagNode{
    if (self.detailViewModel.walletArmingFlagNodeBlock) {
        self.detailViewModel.walletArmingFlagNodeBlock();
    }
}
@end

