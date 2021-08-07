//
//  YXWalletProxy.h
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "SCEventProxy.h"
#import "YXWalletPrivatekeyViewModel.h"
#import "YXWalletHelpWordViewModel.h"
#import "YXWalletPaymentAccountViewModel.h"
#import "YXWalletAddAccountViewModel.h"
#import "YXWalletAccountDetailViewModel.h"
#import "YXWalletAddAccountEditViewModel.h"
#import "YXAssetsDetailViewModel.h"
#import "YXNodeListViewModel.h"
#import "YXNodeDetailViewModel.h"
#import "YXWalletViewModel.h"
#import "YXWalletSendViewModel.h"
#import "YXWalletReceiveCodeViewModel.h"
#import "YXWalletCashViewModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXWalletProxy : SCEventProxy
@property (nonatomic , strong)YXWalletViewModel *walletViewModel;
@property (nonatomic , strong)YXWalletPrivatekeyViewModel *viewModel;
@property (nonatomic , strong)YXWalletHelpWordViewModel *HelpWordVM;
@property (nonatomic , strong)YXWalletPaymentAccountViewModel *paymentAccountViewModel;
@property (nonatomic , strong)YXWalletAddAccountViewModel *addAccountViewModel;
@property (nonatomic , strong)YXWalletAccountDetailViewModel *accountDetailViewModel;
@property (nonatomic , strong)YXWalletAddAccountEditViewModel *addAcountEditViewModel;
@property (nonatomic , strong)YXAssetsDetailViewModel *assetsDetailViewModel;
@property (nonatomic , strong)YXNodeListViewModel *nodeListViewModel;
@property (nonatomic , strong)YXNodeDetailViewModel *detailViewModel;
@property (nonatomic , strong)YXWalletSendViewModel *sendViewModel;
@property (nonatomic , strong)YXWalletReceiveCodeViewModel *receiveCodeViewModel;
@property (nonatomic , strong)YXWalletCashViewModel *cashViewModel;
@end

NS_ASSUME_NONNULL_END
