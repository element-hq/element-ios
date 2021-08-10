//
//  YXWalletAddAccountDetailViewController.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddAccountDetailViewController.h"
#import "YXWalletAddAccountEditViewModel.h"
#import "YXWalletProxy.h"
#import "YXWalletPopupView.h"
#import "TTVCameraLogic.h"
@interface YXWalletAddAccountDetailViewController ()<TTVUploadImagesDelegate,UIActionSheetDelegate>
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)YXWalletAddAccountEditViewModel *viewModel;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXWalletProxy *proxy;
@property (nonatomic , strong)YXWalletPopupView *walletPopupView;
@end

@implementation YXWalletAddAccountDetailViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if (!self.walletPopupView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletPopupView];
    }
}

-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"收款账户";
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

-(YXWalletPopupView *)walletPopupView{
    if (!_walletPopupView) {
        _walletPopupView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewTJCGType];
        YXWeakSelf
        _walletPopupView.cancelBlock = ^{
            weakSelf.walletPopupView.hidden = YES;
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        _walletPopupView.hidden = YES;
    }
    return _walletPopupView;
}


-(YXWalletAddAccountEditViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXWalletAddAccountEditViewModel alloc]init];
        YXWeakSelf
        [_viewModel setReloadData:^{
            weakSelf.tableView.dataSource = weakSelf.viewModel.dataSource;
            weakSelf.tableView.delegate = weakSelf.viewModel.delegate;
            [weakSelf.tableView reloadData];
        }];
        
        [_viewModel setAddSuccessBlock:^{
            weakSelf.walletPopupView.hidden = NO;
        }];
        
        [_viewModel setCallCameraBlock:^{
            [weakSelf callCamera];
        }];
    }
    return _viewModel;
}

- (void)callCamera {
    TTVCameraLogic *cameraInstance =[TTVCameraLogic sharedTTVCameraLogic];
    cameraInstance.withController    = self;
    cameraInstance.delegate          = self;
    [cameraInstance didSelectPhotos];
}

#pragma mark -TTVUploadImagesDelegate

- (void)uploadCommunityImages:(NSArray *)data {
    [self.viewModel uploadCommunityImages:data];
}

- (YXWalletProxy *)proxy{
    if (!_proxy) {
        _proxy = [[YXWalletProxy alloc]init];
    }
    return _proxy;
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
    
    [self.viewModel reloadNewDataWith:self.type];
    self.proxy.addAcountEditViewModel = self.viewModel;
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

