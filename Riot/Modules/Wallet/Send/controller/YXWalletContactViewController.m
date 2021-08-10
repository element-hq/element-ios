//
//  YXWalletContactViewController.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/30.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletContactViewController.h"
#import "YXWalletSendViewModel.h"
#import "YXWalletProxy.h"
#import "YXWalletAssetsSelectView.h"
#import <Contacts/Contacts.h>
#import "ContactsDataSource.h"
@interface YXWalletContactViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)YXWalletSendViewModel *viewModel;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXWalletProxy *proxy;
@property (nonatomic , strong)YXWalletAssetsSelectView *assetsSelectView;
@end

@implementation YXWalletContactViewController



-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT )];
        _naviView.title = @"选择联系人";
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
        [_viewModel setReloadContactDataBlock:^{
            weakSelf.tableView.dataSource = weakSelf.viewModel.dataSource;
            weakSelf.tableView.delegate = weakSelf.viewModel.delegate;
            [weakSelf.tableView reloadData];
        }];
        
        [_viewModel setSelectFirendBlock:^(NSString * _Nonnull walletAddr) {
            if (weakSelf.selectFirendBlock) {
                weakSelf.selectFirendBlock(walletAddr);
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    NSArray *matrixContacts = [MXKContactManager sharedManager].matrixContacts;
//
//    NSArray *localContacts = [MXKContactManager sharedManager].localContacts;
//    NSArray *localContactsWithMethods = [MXKContactManager sharedManager].localContactsWithMethods;
    self.view.backgroundColor = kWhiteColor;
    [self.view addSubview:self.naviView];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.right.bottom.offset(0);
        make.top.mas_equalTo(STATUS_AND_NAVIGATION_HEIGHT);
    }];
    
    [self.viewModel reloadContactData:self.currentSelectModel];
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
