//
//  YXAssetsDetailViewController.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/26.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXAssetsDetailViewController.h"
#import "YXNaviView.h"
#import "YXAssetsDetailViewModel.h"
#import "YXWalletSettingViewController.h"
#import "YXWalletProxy.h"
#import "YXWalletNodeHomeViewController.h"
#import "YXAssetsDetailSendView.h"
#import "YXWalletSendViewController.h"
#import "YXWalletReceiveCodeViewController.h"
#import "YXWalletSettingViewController.h"
#import "YXWalletConfirmationViewController.h"

@interface YXAssetsDetailViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXAssetsDetailViewModel *viewModel;
@property (nonatomic , strong)YXWalletProxy *proxy;
@property (nonatomic , strong)YXAssetsDetailSendView *detailSendView;
@end

@implementation YXAssetsDetailViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}


-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = self.titleName;
        _naviView.titleColor = UIColor.whiteColor;
        _naviView.backgroundColor = WalletColor;
        _naviView.showMoreBtn = YES;
        _naviView.rightImage = [UIImage imageNamed:@"detail_more"];
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        
        _naviView.moreBlock = ^{
            YXWalletSettingViewController *vc = [[YXWalletSettingViewController alloc]init];
            vc.isWalletSetting = YES;
            vc.model = weakSelf.model;
            [weakSelf.navigationController pushViewController:vc animated:YES];
            
        };
    }
    return _naviView;
}

-(YXAssetsDetailSendView *)detailSendView{
    if (!_detailSendView) {
        _detailSendView = [[YXAssetsDetailSendView alloc]init];
        YXWeakSelf
        [_detailSendView setReceiveBlock:^{
            YXWalletReceiveCodeViewController *receiveCode = [[YXWalletReceiveCodeViewController alloc]init];
            receiveCode.currentSelectModel = weakSelf.model;
            [weakSelf.navigationController pushViewController:receiveCode animated:YES];
        }];
        
        [_detailSendView setSendBlock:^{
            YXWalletSendViewController *sendDetail = [[YXWalletSendViewController alloc]init];
            sendDetail.currentSelectModel = weakSelf.model;
            [weakSelf.navigationController pushViewController:sendDetail animated:YES];
        }];
    }
    return _detailSendView;
}

- (YXWalletProxy *)proxy{
    if (!_proxy) {
        _proxy = [[YXWalletProxy alloc]init];
    }
    return _proxy;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self.viewModel reloadNewData:self.model];
    self.proxy.assetsDetailViewModel = self.viewModel;
    self.eventProxy = self.proxy;
}

- (void)setupUI{
    
    [self.view addSubview:self.naviView];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.right.offset(0);
        make.top.mas_equalTo(STATUS_AND_NAVIGATION_HEIGHT);
        make.bottom.mas_equalTo(-60);
    }];
    
    [self.view addSubview:self.detailSendView];
    [self.detailSendView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.offset(0);
        make.height.mas_equalTo(60);
    }];
   
}

-(YXAssetsDetailViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXAssetsDetailViewModel alloc]init];
        YXWeakSelf
        [_viewModel setReloadData:^{
           
            weakSelf.tableView.dataSource = weakSelf.viewModel.dataSource;
            weakSelf.tableView.delegate = weakSelf.viewModel.delegate;
            [weakSelf.tableView.mj_header endRefreshing];
            [weakSelf.tableView.mj_footer endRefreshing];
            [weakSelf.tableView reloadData];
        }];
        
        [_viewModel setJumpNodeListVcBlock:^{
            YXWalletNodeHomeViewController *noteHome = [[YXWalletNodeHomeViewController alloc]init];
            noteHome.model = weakSelf.model;
            [weakSelf.navigationController pushViewController:noteHome animated:YES];
            
        }];
        
        [_viewModel setTouchAssetsDetailItemBlock:^(YXAssetsDetailRecordsItem * _Nonnull model) {

            YXWalletConfirmationViewController *confirmatVc = [[YXWalletConfirmationViewController alloc]init];
            if ([model.action isEqualToString:@"pending"]) {//待处理
                confirmatVc.naviTitle = @"待处理交易";
            }else{
                confirmatVc.naviTitle = @"交易详情";
            }
            NSDictionary *dic = model.mj_keyValues;
            confirmatVc.sendDataInfo = [YXWalletSendDataInfo mj_objectWithKeyValues:dic];
            confirmatVc.sendDataInfo.title = confirmatVc.naviTitle;
            [weakSelf.navigationController pushViewController:confirmatVc animated:YES];
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
        _tableView.mj_header = [MJRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshHeaderAction)];
        _tableView.mj_footer = [MJRefreshBackFooter footerWithRefreshingTarget:self refreshingAction:@selector(refreshFooterAction)];
    }
    return _tableView;
}

- (void)refreshHeaderAction{
    [self.viewModel reloadNewData:self.model];
}

- (void)refreshFooterAction{
    [self.viewModel reloadMoreData:self.model];
}

@end
