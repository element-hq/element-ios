//
//  YXWalletSettingViewController.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSettingViewController.h"
#import "YXWalletSettingViewModel.h"
#import "YXWalletHelpViewController.h"
#import "YXWalletPrivateKeyViewController.h"
#import "YXWalletPopupView.h"
#import "YXWalletHelpWordViewController.h"
#import "YXWalletSettingPasswordViewController.h"
#import "YXWalletPaymentAccountViewController.h"
#import "YXWalletViewController.h"
@interface YXWalletSettingViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXWalletSettingViewModel *viewModel;
@property (nonatomic , strong)YXWalletPopupView *walletPopupView;
@end

@implementation YXWalletSettingViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if (!self.walletPopupView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletPopupView];
    }
}

-(YXWalletPopupView *)walletPopupView{
    if (!_walletPopupView) {
        _walletPopupView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewSCQBType];
        YXWeakSelf
        _walletPopupView.determineBlock = ^{
            [weakSelf.viewModel deleteWalletHelpWord:weakSelf.model.walletId complete:^(NSDictionary * _Nonnull responseObject) {
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
            }];
        };
        _walletPopupView.cancelBlock = ^{
            weakSelf.walletPopupView.hidden = YES;
        };
        _walletPopupView.hidden = YES;
    }
    return _walletPopupView;
}

-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"设置";
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self.viewModel reloadNewData:self.isWalletSetting andModel:self.model];
}

- (void)setupUI{
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.right.bottom.offset(0);
        make.top.mas_equalTo(STATUS_AND_NAVIGATION_HEIGHT);
    }];
    [self.view addSubview:self.naviView];
}

-(YXWalletSettingViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXWalletSettingViewModel alloc]init];
        YXWeakSelf
        [_viewModel setReloadData:^{
            weakSelf.viewModel.tableView = weakSelf.tableView;
            weakSelf.tableView.dataSource = weakSelf.viewModel.dataSource;
            weakSelf.tableView.delegate = weakSelf.viewModel.delegate;
            [weakSelf.tableView reloadData];
        }];
        
        [_viewModel setTouchSettingBlock:^(YXWalletSettingModel * _Nonnull model) {
            [weakSelf touchSettingWith:model.type];
        }];
    }
    return _viewModel;
}

- (void)touchSettingWith:(YXWalletSettingType)type{
    YXWeakSelf
    
    if (type == YXWalletSettingSKZHType) {//收款账户
        
        YXWalletPaymentAccountViewController *paymentAccountVc = [[YXWalletPaymentAccountViewController alloc]init];
        [self.navigationController pushViewController:paymentAccountVc animated:YES];
        
    }else if (type == YXWalletSettingQBMMType){//钱包密码
        YXWalletSettingPasswordViewController *settingPasswordVC = [[YXWalletSettingPasswordViewController alloc]init];
        settingPasswordVC.havePassword = [YXWalletPasswordManager sharedYXWalletPasswordManager].isHavePassword;
        [self.navigationController pushViewController:settingPasswordVC animated:YES];
    }else if (type == YXWalletSettingXSZJQType){//显示助记词
        
        [self.viewModel getWalletHelpWord:self.model.walletId complete:^(NSDictionary * _Nonnull responseObject) {
            YXWalletHelpWordViewController *helpWordKeyVc = [[YXWalletHelpWordViewController alloc]init];
            helpWordKeyVc.helpWord = responseObject[@"data"];
            helpWordKeyVc.helpWordArray = [GET_A_NOT_NIL_STRING(helpWordKeyVc.helpWord) componentsSeparatedByString:@" "];
            [weakSelf.navigationController pushViewController:helpWordKeyVc animated:YES];
  
        }];

        
    }else if (type == YXWalletSettingXSSYType){//显示私钥
        
        YXWalletPrivateKeyViewController *privateKeyVc = [[YXWalletPrivateKeyViewController alloc]init];
        privateKeyVc.model = self.model;
        [self.navigationController pushViewController:privateKeyVc animated:YES];
        
    }else if (type == YXWalletSettingGYWMType){//关于我们
        
    }else if (type == YXWalletSettingBZFKType){//帮助反馈
        
        YXWalletHelpViewController *helpVc = [[YXWalletHelpViewController alloc]init];
        [self.navigationController pushViewController:helpVc animated:NO];
        
    }else if (type == YXWalletSettingSCQBType){//删除钱包
        
        self.walletPopupView.hidden = NO;
        
    }else if (type == YXWalletSettingTBJLType){//同步数据
        
    }
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
