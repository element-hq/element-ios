//
//  YXWalletCashViewController.m
//  lianliao
//
//  Created by 廖燊 on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCashViewController.h"
#import "YXWalletCashViewModel.h"
#import "YXWalletProxy.h"
#import "YXWalletAssetsSelectView.h"
#import "YXWalletContactViewController.h"
#import "YXWalletCashAddCardViewController.h"
#import "YXWalletCashRecordViewController.h"
#import "YXWalletPaymentAccountViewController.h"
#import "YXWalletInputPasswordView.h"
#import "YXWalletPopupView.h"
#import "YXWalletViewController.h"

@interface YXWalletCashViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)YXWalletCashViewModel *viewModel;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXWalletProxy *proxy;
@property (nonatomic , strong)YXWalletAssetsSelectView *assetsSelectView;
@property (nonatomic , strong)YXWalletInputPasswordView *inputPasswordView;
@property (nonatomic , strong)YXWalletPopupView *walletPopupView;
@end

@implementation YXWalletCashViewController

-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"接收码";
        _naviView.leftImage = [UIImage imageNamed:@"back_b_black"];
        _naviView.backgroundColor = UIColor.whiteColor;
        _naviView.showRightLabel = YES;
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
 
        _naviView.rightLabelBlock = ^{
            YXWalletCashRecordViewController *vc = [[YXWalletCashRecordViewController alloc]init];
            vc.model = weakSelf.model;
            [weakSelf.navigationController pushViewController:vc animated:YES];
        };
    }
    return _naviView;
}


-(YXWalletCashViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXWalletCashViewModel alloc]init];
        YXWeakSelf
        [_viewModel setReloadData:^{
            weakSelf.tableView.dataSource = weakSelf.viewModel.dataSource;
            weakSelf.tableView.delegate = weakSelf.viewModel.delegate;
            [weakSelf.tableView reloadData];
        }];
        
        [_viewModel setShowSelectAssetsViewBlock:^{
            weakSelf.assetsSelectView.hidden = NO;
        }];
        
        [_viewModel setShowInputPasswordViewBlock:^{
            [weakSelf.inputPasswordView removeFromSuperview];
            weakSelf.inputPasswordView = nil;
            [UIApplication.sharedApplication.keyWindow addSubview:weakSelf.inputPasswordView];
            weakSelf.inputPasswordView.hidden = NO;
        }];
        
        [_viewModel setConfirmCashSuccessBlock:^{
            weakSelf.inputPasswordView.hidden = YES;
            weakSelf.walletPopupView.hidden = NO;
        }];
        
        [_viewModel setShowAddCardBlock:^{
            YXWalletPaymentAccountViewController *addCard = [[YXWalletPaymentAccountViewController alloc]init];
            addCard.isCash = YES;
            [addCard setSettingDefaultSuccessBlock:^{
                [weakSelf.viewModel getCurrentAcountData:weakSelf.model];
            }];
            [weakSelf.navigationController pushViewController:addCard animated:YES];
        }];

        
    }
    return _viewModel;
}

- (YXWalletProxy *)proxy{
    if (!_proxy) {
        _proxy = [[YXWalletProxy alloc]init];
    }
    return _proxy;
}

-(YXWalletAssetsSelectView *)assetsSelectView{
    if (!_assetsSelectView) {
        _assetsSelectView = [[YXWalletAssetsSelectView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _assetsSelectView.hidden = YES;
    }
    return _assetsSelectView;
}

-(YXWalletInputPasswordView *)inputPasswordView{
    if (!_inputPasswordView) {
        _inputPasswordView = [[YXWalletInputPasswordView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _inputPasswordView.hidden = YES;
        YXWeakSelf
        [_inputPasswordView setEndEditBlock:^(NSString * _Nonnull password) {
            //验证密码是否正确
            NSString *md5Pw = [Tool stringToMD5:password];
            NSString *currentMd5 = [YXWalletPasswordManager sharedYXWalletPasswordManager].passWord;
            if ([md5Pw isEqualToString:currentMd5]) {
                [weakSelf.viewModel confirmToCash];
            }
            
            
        }];
    }
    return _inputPasswordView;
    
}

-(YXWalletPopupView *)walletPopupView{
    if (!_walletPopupView) {
        _walletPopupView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewDXCGType];
        YXWeakSelf
        _walletPopupView.cancelBlock = ^{
            weakSelf.walletPopupView.hidden = YES;
            UINavigationController *navigationVC = weakSelf.navigationController;
            UIViewController *currentVC;
            for (UIViewController *vc in navigationVC.viewControllers) {
                if ([vc isKindOfClass:YXWalletViewController.class]) {
                    currentVC = vc;
                }
            }
            if (currentVC) {
                [weakSelf.navigationController popToViewController:currentVC animated:YES];
            }else{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }
        };
        _walletPopupView.hidden = YES;
    }
    return _walletPopupView;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if (!self.assetsSelectView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.assetsSelectView];
    }
    
    if (!self.walletPopupView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletPopupView];
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kBgColor;
    [self.view addSubview:self.naviView];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.right.bottom.offset(0);
        make.top.mas_equalTo(STATUS_AND_NAVIGATION_HEIGHT);
    }];
    
    [self.viewModel getCurrentAcountData:self.model];
    self.proxy.cashViewModel = self.viewModel;
    self.eventProxy = self.proxy;
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
        _tableView.bounces  = NO;
        if (@available(iOS 11.0, *)) {
               _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass(UITableViewCell.class)];

    }
    return _tableView;
}

@end
