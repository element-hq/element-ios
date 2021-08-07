//
//  YXWalletSettingPasswordViewController.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletSettingPasswordViewController.h"
#import "YXWalletSettingPasswordView.h"
#import "YXWalletPopupView.h"
#import "YXWalletSettingViewModel.h"
#import "YXWalletSettingModel.h"

@interface YXWalletSettingPasswordViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)YXWalletSettingPasswordView *verifyPasswordView;//验证密码
@property (nonatomic , strong)YXWalletSettingPasswordView *settingPasswordView;//设置密码
@property (nonatomic , strong)YXWalletSettingPasswordView *deteminePasswordView;//确定密码
@property (nonatomic , strong)YXWalletPopupView *walletPopupView;
@property (nonatomic , strong)YXWalletSettingViewModel *viewModel;
@end

@implementation YXWalletSettingPasswordViewController


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if (!self.walletPopupView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletPopupView];
    }
}

-(YXWalletSettingViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXWalletSettingViewModel alloc]init];
    }
    return _viewModel;
}


-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = self.havePassword ? @"修改钱包密码" : @"设置钱包密码";
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
        _walletPopupView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewXGCGType];
        YXWeakSelf
        _walletPopupView.cancelBlock = ^{
            weakSelf.walletPopupView.hidden = YES;
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        _walletPopupView.hidden = YES;
    }
    return _walletPopupView;
}

-(YXWalletSettingPasswordView *)deteminePasswordView{
    if (!_deteminePasswordView) {
        _deteminePasswordView = [[YXWalletSettingPasswordView alloc]init];
        _deteminePasswordView.title = @"确认钱包密码";
        _deteminePasswordView.des = @"再次确认设置的钱包密码";
        _deteminePasswordView.hidden = YES;
        _deteminePasswordView.nextText = self.havePassword ? @"确认修改" : @"确认";
        YXWeakSelf
        _deteminePasswordView.touchBlock = ^{
            //判断两次密码是否一样
            if ([weakSelf.settingPasswordView.password isEqualToString:weakSelf.deteminePasswordView.password]) {
                
                [weakSelf.viewModel walletChangePassword:WalletManager.userId Password:weakSelf.deteminePasswordView.password complete:^(NSDictionary * _Nonnull responseObject) {
                    
                    YXWalletSettingPasswordModel *passwordModel = [YXWalletSettingPasswordModel mj_objectWithKeyValues:responseObject];
                
                    if (passwordModel.status == 200) {
                        //一样保存代码
                        weakSelf.walletPopupView.hidden = NO;
                    }else{
                        [MBProgressHUD showError:@"修改失败"];
                    }
                                      
                }];
                
            }else{
                //提示框
                weakSelf.deteminePasswordView.showError = YES;
                weakSelf.deteminePasswordView.error = @"两次输入的密码不一致";
            }
        };
    }
    return _deteminePasswordView;
}

-(YXWalletSettingPasswordView *)settingPasswordView{
    if (!_settingPasswordView) {
        _settingPasswordView = [[YXWalletSettingPasswordView alloc]init];
        _settingPasswordView.title = self.havePassword ? @"输入新的钱包密码": @"设置你的钱包密码";
        _settingPasswordView.des = self.havePassword ? @"请输入新的钱包密码":@"初次使用请设置您的钱包密码";
        YXWeakSelf
        _settingPasswordView.touchBlock = ^{
            
            if (weakSelf.settingPasswordView.password.length < 6) {
                weakSelf.settingPasswordView.showError = YES;
                weakSelf.settingPasswordView.error = @"输入密码长度不足";
                return;
            }
            
            weakSelf.settingPasswordView.hidden = YES;
            weakSelf.deteminePasswordView.hidden = NO;
    
        };
    }
    return _settingPasswordView;
}

-(YXWalletSettingPasswordView *)verifyPasswordView{
    if (!_verifyPasswordView) {
        _verifyPasswordView = [[YXWalletSettingPasswordView alloc]init];
        _verifyPasswordView.title = @"验证钱包密码";
        _verifyPasswordView.des = @"请输入当前钱包密码完成身份验证";
        YXWeakSelf
        _verifyPasswordView.touchBlock = ^{
            
            if (weakSelf.verifyPasswordView.password.length < 6) {
                weakSelf.verifyPasswordView.showError = YES;
                weakSelf.verifyPasswordView.error = @"输入密码长度不足";
                //这里还需要验证之前的密码是否正确
                
                return;
            }
            
            weakSelf.verifyPasswordView.hidden = YES;
            weakSelf.settingPasswordView.hidden = NO;
    
        };
    }
    return _verifyPasswordView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kWhiteColor;
    [self.view addSubview:self.naviView];
    [self.view addSubview:self.settingPasswordView];
    [self.view addSubview:self.deteminePasswordView];
    
    [self.settingPasswordView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.height.mas_equalTo(260);
        make.top.mas_equalTo(STATUS_AND_NAVIGATION_HEIGHT + 12);
    }];
    
    [self.deteminePasswordView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.height.mas_equalTo(260);
        make.top.mas_equalTo(STATUS_AND_NAVIGATION_HEIGHT + 12);
    }];
    
    if (self.havePassword) {
        [self.view addSubview:self.verifyPasswordView];
        [self.verifyPasswordView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.offset(0);
            make.height.mas_equalTo(260);
            make.top.mas_equalTo(STATUS_AND_NAVIGATION_HEIGHT + 12);
        }];
        self.settingPasswordView.hidden = YES;
    }
    
}


@end
