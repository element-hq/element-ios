//
//  YXWalletConfirmationViewController.m
//  lianliao
//
//  Created by liaoshen on 2021/7/1.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletConfirmationViewController.h"
#import "YXWalletProxy.h"
#import "YXWalletInputPasswordView.h"
#import "YXWalletPopupView.h"
#import "YXWalletViewController.h"
@interface YXWalletConfirmationViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)YXWalletSendViewModel *viewModel;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXWalletProxy *proxy;
@property (nonatomic , strong)YXWalletInputPasswordView *inputPasswordView;
@property (nonatomic , strong)YXWalletPopupView *walletPaySuccesView;//支付成功
@property (nonatomic , strong)YXWalletPopupView *walletPayFailView;//支付失败
@property (nonatomic , strong)YXWalletPopupView *walletCancelPayView;//取消支付
@end

@implementation YXWalletConfirmationViewController

-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        if (_naviTitle) {
            _naviView.title = _naviTitle;
        }else{
            _naviView.title = @"确认交易";
        }
        _naviView.titleColor = UIColor51;
        _naviView.leftImage = [UIImage imageNamed:@"back_b_black"];
        _naviView.backgroundColor = UIColor.whiteColor;
        if ([self.sendDataInfo.action isEqualToString:@"pending"]) {//待处理
            _naviView.showRightLabel = YES;
            _naviView.rightText = @"取消支付";
        }
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        _naviView.rightLabelBlock = ^{
            weakSelf.walletCancelPayView.hidden = NO;
        };
 
    }
    return _naviView;
}


-(YXWalletSendViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXWalletSendViewModel alloc]init];
        YXWeakSelf
        [_viewModel setReloadData:^{
            weakSelf.tableView.dataSource = weakSelf.viewModel.dataSource;
            weakSelf.tableView.delegate = weakSelf.viewModel.delegate;
            [weakSelf.tableView reloadData];
        }];
        
        [_viewModel setShowInputPasswordViewBlock:^{
            [weakSelf showInputPasswordView];
        }];
        
        [_viewModel setConfirmPaySuccessBlock:^{
            weakSelf.inputPasswordView.hidden = YES;
            weakSelf.walletPaySuccesView.hidden = NO;
        }];
        
        [_viewModel setConfirmPayFailError:^{
            [MBProgressHUD showError:@"支付失败请重试"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf showInputPasswordView];
            });
        }];
        
    }
    return _viewModel;
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
                [weakSelf.viewModel confirmPay];
            }else{
                weakSelf.inputPasswordView.hidden = YES;
                weakSelf.walletPayFailView.hidden = NO;
            }
            
        }];
        
        [_inputPasswordView setCloaseBtnBlock:^{
            weakSelf.walletPaySuccesView.hidden = YES;
            weakSelf.walletPayFailView.hidden = YES;
            weakSelf.walletCancelPayView.hidden = YES;
        }];
    }
    return _inputPasswordView;
    
}

-(YXWalletPopupView *)walletPaySuccesView{
    if (!_walletPaySuccesView) {
        _walletPaySuccesView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewZFCGType];
        YXWeakSelf
        _walletPaySuccesView.cancelBlock = ^{
            weakSelf.walletPaySuccesView.hidden = YES;
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
        _walletPaySuccesView.hidden = YES;
    }
    return _walletPaySuccesView;
}

-(YXWalletPopupView *)walletPayFailView{
    if (!_walletPayFailView) {
        _walletPayFailView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewZFSBType];
        YXWeakSelf
        
        //重试
        _walletPayFailView.cancelBlock = ^{
            [weakSelf showInputPasswordView];
            weakSelf.walletPayFailView.hidden = YES;
        };
        
        //取消
        _walletPayFailView.determineBlock = ^{
            weakSelf.walletPayFailView.hidden = YES;
        };
        
        _walletPayFailView.hidden = YES;
    }
    return _walletPayFailView;
}

-(YXWalletPopupView *)walletCancelPayView{
    if (!_walletCancelPayView) {
        _walletCancelPayView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewCXZFType];
        YXWeakSelf
        _walletCancelPayView.cancelBlock = ^{
            weakSelf.walletCancelPayView.hidden = YES;
            [weakSelf showInputPasswordView];
        };
        
        //继续支付
        _walletCancelPayView.determineBlock = ^{
            
            
            weakSelf.walletCancelPayView.hidden = YES;
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
        
        _walletCancelPayView.hidden = YES;
    }
    return _walletCancelPayView;
}



- (YXWalletProxy *)proxy{
    if (!_proxy) {
        _proxy = [[YXWalletProxy alloc]init];
    }
    return _proxy;
}



-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    
    if (!self.walletPaySuccesView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletPaySuccesView];
    }
    
    if (!self.walletPayFailView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletPayFailView];
    }
    
    if (!self.walletCancelPayView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletCancelPayView];
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
    
    [self.viewModel reloadConfirmationData:self.sendDataInfo];
    self.proxy.sendViewModel = self.viewModel;
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
        if (@available(iOS 11.0, *)) {
               _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass(UITableViewCell.class)];

    }
    return _tableView;
}

-(void)setNaviTitle:(NSString *)naviTitle{
    _naviTitle = naviTitle;
}

- (void)showInputPasswordView{
    [self.inputPasswordView removeFromSuperview];
    self.inputPasswordView = nil;
    [UIApplication.sharedApplication.keyWindow addSubview:self.inputPasswordView];
    self.inputPasswordView.hidden = NO;

}

@end
