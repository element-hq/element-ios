//
//  YXNodeDetailViewController.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeDetailViewController.h"
#import "YXNodeDetailViewModel.h"
#import "YXWalletProxy.h"
#import "YXNodeConfigViewController.h"
#import "YXWalletPopupView.h"
@interface YXNodeDetailViewController ()
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXNodeDetailViewModel *viewModel;
@property (nonatomic , strong)YXWalletProxy *proxy;
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)YXWalletPopupView *walletPopupView;
@property (nonatomic , strong)YXWalletPopupView *walletArmingFlagView;
@end

@implementation YXNodeDetailViewController

- (YXWalletProxy *)proxy{
    if (!_proxy) {
        _proxy = [[YXWalletProxy alloc]init];
    }
    return _proxy;
}

-(YXWalletPopupView *)walletPopupView{
    if (!_walletPopupView) {
        _walletPopupView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewJDDQType];
        YXWeakSelf
        _walletPopupView.cancelBlock = ^{
            weakSelf.walletPopupView.hidden = YES;
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        _walletPopupView.hidden = YES;
    }
    return _walletPopupView;
}

-(YXWalletPopupView *)walletArmingFlagView{
    if (!_walletArmingFlagView) {
        _walletArmingFlagView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewJYZDType];
        YXWeakSelf
        _walletArmingFlagView.cancelBlock = ^{
            weakSelf.walletArmingFlagView.hidden = YES;
            [weakSelf walletArmingFlagViewAction];
        };
        _walletArmingFlagView.hidden = YES;
    }
    return _walletArmingFlagView;
}

- (void)walletArmingFlagViewAction{
    YXWeakSelf
    [self.viewModel pledgeUnfreezeNode:self.nodeListModel Complete:^{
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
}

-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"节点详情";
        _naviView.titleColor = kWhiteColor;
        _naviView.backgroundColor = kClearColor;
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        
    }
    return _naviView;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!self.walletPopupView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletPopupView];
    }
    if (!self.walletArmingFlagView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletArmingFlagView];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.nodeListModel.maturity) {
        self.walletPopupView.hidden = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self.viewModel reloadNewData:self.nodeListModel];
    self.proxy.detailViewModel = self.viewModel;
    self.eventProxy = self.proxy;
}

- (void)setupUI{
    
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.right.bottom.top.offset(0);
    }];
    [self.view addSubview:self.naviView];
    
}

-(YXNodeDetailViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXNodeDetailViewModel alloc]init];
        YXWeakSelf
        [_viewModel setReloadData:^{
            weakSelf.tableView.dataSource = weakSelf.viewModel.dataSource;
            weakSelf.tableView.delegate = weakSelf.viewModel.delegate;
            [weakSelf.tableView reloadData];
        }];
        
        //重新激活
        [_viewModel setActivationNodeBlock:^{
            YXNodeConfigViewController *configVc = [[YXNodeConfigViewController alloc]init];
            //配置成功需要刷新当前页面
            [configVc setReloadDataBlock:^{
                [weakSelf.viewModel reloadNewData:weakSelf.nodeListModel];
            }];
            configVc.nodeListModel = weakSelf.nodeListModel;
            [weakSelf.navigationController pushViewController:configVc animated:YES];
        }];

        //解冻质押
        [_viewModel setWalletArmingFlagNodeBlock:^{
            weakSelf.walletArmingFlagView.hidden = NO;
        }];
        
    }
    return _viewModel;
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



@end

