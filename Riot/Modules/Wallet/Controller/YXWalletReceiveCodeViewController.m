//
//  YXWalletReceiveCodeViewController.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/30.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletReceiveCodeViewController.h"
#import "YXWalletReceiveCodeViewModel.h"
#import "YXWalletProxy.h"
#import "YXWalletAssetsSelectView.h"
#import "YXWalletContactViewController.h"
@interface YXWalletReceiveCodeViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)YXWalletReceiveCodeViewModel *viewModel;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXWalletProxy *proxy;
@property (nonatomic , strong)YXWalletAssetsSelectView *assetsSelectView;

@end

@implementation YXWalletReceiveCodeViewController

-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"接收码";
        _naviView.titleColor = kWhiteColor;
        _naviView.backgroundColor = UIColor.clearColor;
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
 
    }
    return _naviView;
}


-(YXWalletReceiveCodeViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXWalletReceiveCodeViewModel alloc]init];
        YXWeakSelf
        [_viewModel setReloadData:^{
            weakSelf.tableView.dataSource = weakSelf.viewModel.dataSource;
            weakSelf.tableView.delegate = weakSelf.viewModel.delegate;
            [weakSelf.tableView reloadData];
        }];
        
        [_viewModel setShowSelectAssetsViewBlock:^{
            weakSelf.assetsSelectView.hidden = NO;
        }];
        
        [_viewModel setRefreshAddressBlock:^{
            [weakSelf.viewModel refreshAddress:weakSelf.currentSelectModel];
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
        YXWeakSelf
        [_assetsSelectView setRequestAssetsSuccessBlock:^(YXWalletMyWalletRecordsItem * _Nonnull model) {
            if (!weakSelf.currentSelectModel) {
                weakSelf.currentSelectModel = model;
            }
            [weakSelf.viewModel reloadNewData:weakSelf.currentSelectModel];
        }];
        
        [_assetsSelectView setSelectAssetsBlock:^(YXWalletMyWalletRecordsItem * _Nonnull model) {
            weakSelf.currentSelectModel = model;
            weakSelf.assetsSelectView.hidden = YES;
            [weakSelf.viewModel reloadNewData:weakSelf.currentSelectModel];
        }];
    }
    return _assetsSelectView;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if (!self.assetsSelectView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.assetsSelectView];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = WalletColor;
    [self.view addSubview:self.naviView];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.right.bottom.offset(0);
        make.top.mas_equalTo(STATUS_AND_NAVIGATION_HEIGHT);
    }];

    self.proxy.receiveCodeViewModel = self.viewModel;
    self.eventProxy = self.proxy;
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0) style:(UITableViewStylePlain)];
        _tableView.alwaysBounceVertical = YES;
        [_tableView setBackgroundColor:WalletColor];
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
