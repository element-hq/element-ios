//
//  YXWalletSendViewController.m
//  lianliao
//
//  Created by liaoshen on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSendViewController.h"
#import "YXWalletSendViewModel.h"
#import "YXWalletProxy.h"
#import "YXWalletAssetsSelectView.h"
#import "YXWalletContactViewController.h"
#import "YXWalletConfirmationViewController.h"
#import "TTVCodeScanViewController.h"
@interface YXWalletSendViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)YXWalletSendViewModel *viewModel;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXWalletProxy *proxy;
@property (nonatomic , strong)YXWalletAssetsSelectView *assetsSelectView;
@property (nonatomic , strong)YXWalletContactViewController *contactVc;
@property (nonatomic , strong)TTVCodeScanViewController *codeScanvc;
@end

@implementation YXWalletSendViewController

-(YXWalletContactViewController *)contactVc{
    if (!_contactVc) {
        _contactVc = [[YXWalletContactViewController alloc]init];
        YXWeakSelf
        _contactVc.currentSelectModel = weakSelf.currentSelectModel;
        _contactVc.selectFirendBlock = ^(NSString * _Nonnull walletAddr) {
            weakSelf.currentSelectModel.sendAddress = walletAddr;
            [weakSelf.viewModel reloadNewData:weakSelf.currentSelectModel];
        };
    }
    return _contactVc;
}

-(TTVCodeScanViewController *)codeScanvc{
    if (!_codeScanvc) {
        _codeScanvc = [[TTVCodeScanViewController alloc]init];
        YXWeakSelf
        _codeScanvc.scanWalletAddrBlock = ^(NSString * _Nonnull walletAddr) {
            weakSelf.currentSelectModel.sendAddress = walletAddr;
            [weakSelf.viewModel reloadNewData:weakSelf.currentSelectModel];
        };
    }
    return _codeScanvc;
}

-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"发送";
        _naviView.titleColor = UIColor51;
        _naviView.leftImage = [UIImage imageNamed:@"back_b_black"];
        _naviView.backgroundColor = UIColor.whiteColor;
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
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
        
        [_viewModel setShowSelectAssetsViewBlock:^{
            weakSelf.assetsSelectView.hidden = NO;
        }];
        
        [_viewModel setJumpContactDetailBlock:^{
            YXWalletContactViewController *contactVc = [[YXWalletContactViewController alloc]init];
            [weakSelf.navigationController pushViewController:contactVc animated:YES];
        }];
        
        [_viewModel setNextBlock:^(YXWalletSendDataInfo * _Nonnull model) {
            YXWalletConfirmationViewController *confirmatVc = [[YXWalletConfirmationViewController alloc]init];
            confirmatVc.sendDataInfo = model;
            [weakSelf.navigationController pushViewController:confirmatVc animated:YES];
        }];
        
        [_viewModel setJumpContactViewBlock:^{
            [weakSelf.navigationController pushViewController:weakSelf.contactVc animated:YES];
        }];
        
        [_viewModel setJumpScanViewBlock:^{
          
            [weakSelf.navigationController pushViewController:weakSelf.codeScanvc animated:YES];
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
    self.view.backgroundColor = kBgColor;
    [self.view addSubview:self.naviView];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.right.bottom.offset(0);
        make.top.mas_equalTo(STATUS_AND_NAVIGATION_HEIGHT);
    }];
    
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

@end
