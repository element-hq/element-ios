//
//  YXWalletViewController.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/18.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletViewController.h"
#import "YXNaviView.h"
#import "YXWalletViewModel.h"
#import "YXWalletSettingViewController.h"
#import "YXAssetsDetailViewController.h"
#import "YXWalletAddView.h"
#import "YXWalletProxy.h"
#import "YXWalletAddHomeViewController.h"
#import "YXWalletSendViewController.h"
#import "YXWalletReceiveCodeViewController.h"
#import "YXWalletCashViewController.h"
#import "YXWalletAccountModel.h"
#import <AFNetworking.h>
#import "YXWalletAssetsSelectView.h"

@interface YXWalletViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXWalletViewModel *viewModel;
@property (nonatomic , strong)YXWalletAddView *walletAddView;
@property (nonatomic , strong)YXWalletProxy *proxy;
@property (nonatomic , strong)YXWalletAssetsSelectView *assetsSelectView;
@property (nonatomic , assign)BOOL isFirstRequest;
@end

@implementation YXWalletViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if (!self.walletAddView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletAddView];
    }
    
    if (!self.assetsSelectView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.assetsSelectView];
    }
    
    if (!self.isFirstRequest) {
        [self.viewModel reloadNewData];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

-(YXWalletAddView *)walletAddView{
    if (!_walletAddView) {
        _walletAddView = [[YXWalletAddView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _walletAddView.hidden = YES;
        YXWeakSelf
        [_walletAddView setSelectAddWalletItemBlock:^(YXWalletCoinDataModel * _Nonnull model) {
            YXWalletAddHomeViewController *addWallet = [[YXWalletAddHomeViewController alloc]init];
            addWallet.coinModel = model;
            [weakSelf.navigationController pushViewController:addWallet animated:YES];
            weakSelf.walletAddView.hidden = YES;
        }];
    }
    return _walletAddView;
}

-(YXWalletAssetsSelectView *)assetsSelectView{
    if (!_assetsSelectView) {
        _assetsSelectView = [[YXWalletAssetsSelectView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _assetsSelectView.hidden = YES;
        YXWeakSelf
        [_assetsSelectView setSelectAssetsBlock:^(YXWalletMyWalletRecordsItem * _Nonnull model) {
            [weakSelf jumpCashDetailWithWalletID:model.walletId];
         
        }];
    }
    return _assetsSelectView;
}

- (void)jumpCashDetailWithWalletID:(NSString *)walletId{
    YXWeakSelf
    [MBProgressHUD showMessage:@""];
    [self.viewModel getJumpWalletCashDataWalleId:walletId Complete:^(YXWalletMyWalletRecordsItem * _Nonnull walletModel) {
        if (walletModel) {
            YXWalletCashViewController *receiveCode = [[YXWalletCashViewController alloc]init];
            receiveCode.model = walletModel;
            [weakSelf.navigationController pushViewController:receiveCode animated:YES];
        }
        [MBProgressHUD hideHUD];
        weakSelf.assetsSelectView.hidden = YES;
    } failure:^{
        [MBProgressHUD hideHUD];
        weakSelf.assetsSelectView.hidden = NO;
    }];
}

-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"钱包";
        _naviView.showMoreBtn = YES;
        _naviView.titleColor = UIColor.whiteColor;
        _naviView.backgroundColor = WalletColor;
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        _naviView.moreBlock = ^{
            YXWalletSettingViewController *walletSettingVC = [[YXWalletSettingViewController alloc]init];
            [weakSelf.navigationController pushViewController:walletSettingVC animated:YES];
        };
    }
    return _naviView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self.viewModel reloadNewData];
    [self.viewModel getAllCoinInfo];
    [self.viewModel walletSecretCode];
    self.proxy.walletViewModel = self.viewModel;
    self.eventProxy = self.proxy;
}

- (void)setupUI{
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.edges.offset(0);
    }];
    [self.view addSubview:self.naviView];
    self.isFirstRequest = YES;
}

-(YXWalletViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXWalletViewModel alloc]init];
        YXWeakSelf
        [_viewModel setReloadData:^{
            weakSelf.isFirstRequest = NO;
            weakSelf.tableView.dataSource = weakSelf.viewModel.dataSource;
            weakSelf.tableView.delegate = weakSelf.viewModel.delegate;
            [weakSelf.tableView reloadData];
            [weakSelf.tableView.mj_header endRefreshing];
            [weakSelf.tableView.mj_footer endRefreshing];
        }];
        
        [_viewModel setSelectIndexBlock:^(YXWalletMyWalletRecordsItem *model) {
            YXAssetsDetailViewController *assetsDetail = [[YXAssetsDetailViewController alloc]init];
            assetsDetail.titleName = model.coinName;
            assetsDetail.model = model;
            [weakSelf.navigationController pushViewController:assetsDetail animated:YES];
        }];
        
        [_viewModel setShowAddViewBlock:^{
            weakSelf.walletAddView.hidden = NO;
            weakSelf.walletAddView.coinModel = weakSelf.viewModel.coinModel;
        }];

        [_viewModel setJumpSendEditDetailBlock:^{
            
            if ([weakSelf showWalletAddView]) return;
            
            YXWalletSendViewController *sendDetail = [[YXWalletSendViewController alloc]init];
            [weakSelf.navigationController pushViewController:sendDetail animated:YES];
        }];
        
        [_viewModel setJumpReceiveCodeBlock:^{
            
            if ([weakSelf showWalletAddView]) return;
            
            YXWalletReceiveCodeViewController *receiveCode = [[YXWalletReceiveCodeViewController alloc]init];
            [weakSelf.navigationController pushViewController:receiveCode animated:YES];
        }];
        
        [_viewModel setJumpCashVCDetailBlock:^{
            
            if ([weakSelf showWalletAddView]) return;
            weakSelf.assetsSelectView.hidden = NO;
            
        }];
         
    }
    return _viewModel;
}

- (BOOL)showWalletAddView{
    BOOL show = NO;
    if (self.viewModel.coinModel.data.count == 0) {
        [MBProgressHUD showSuccess:@"请先添加资产"];
        self.walletAddView.hidden = NO;
        self.walletAddView.coinModel = self.viewModel.coinModel;
        show = YES;
    }
    return show;
}

- (YXWalletProxy *)proxy{
    if (!_proxy) {
        _proxy = [[YXWalletProxy alloc]init];
    }
    return _proxy;
}


- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0) style:(UITableViewStylePlain)];
        _tableView.alwaysBounceVertical = YES;
        [_tableView setBackgroundColor:kBgColor];
        _tableView.estimatedRowHeight = 0.0f;
        _tableView.estimatedSectionHeaderHeight = 0.0f;
        _tableView.estimatedSectionFooterHeight = 0.0f;
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.separatorColor = [UIColor clearColor];
        _tableView.showsVerticalScrollIndicator = YES;
        if (@available(iOS 11.0, *)) {
               _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass(UITableViewCell.class)];
        
        _tableView.mj_header = [MJRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshHeaderAction)];
        _tableView.mj_footer = [MJRefreshBackFooter footerWithRefreshingTarget:self refreshingAction:@selector(refreshFooterAction)];

    }
    return _tableView;
}

- (void)refreshHeaderAction{
    [self.viewModel reloadNewData];
}

- (void)refreshFooterAction{
    [self.viewModel reloadMoreData];
}


@end
