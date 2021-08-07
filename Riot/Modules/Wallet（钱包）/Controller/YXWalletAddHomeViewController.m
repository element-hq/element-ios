//
//  YXWalletAddHomeViewController.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddHomeViewController.h"
#import "YXWalletAddHomeView.h"
#import "YXWalletCreateViewController.h"
@interface YXWalletAddHomeViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)YXWalletAddHomeView *addWalletView;
@property (nonatomic , strong)YXWalletAddHomeView *daoruWalletView;
@property (nonatomic , strong)UILabel *titleLabel;
@end

@implementation YXWalletAddHomeViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"添加钱包";
        _titleLabel.font = [UIFont boldSystemFontOfSize: 20];
        _titleLabel.textColor = WalletColor;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.leftImage = [UIImage imageNamed:@"back_b_black"];
        _naviView.backgroundColor = UIColor.whiteColor;
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
 
    }
    return _naviView;
}

-(YXWalletAddHomeView *)addWalletView{
    if (!_addWalletView) {
        _addWalletView = [[YXWalletAddHomeView alloc]init];
        YXWeakSelf
        _addWalletView.touchBlock = ^{
            YXWalletCreateViewController *createVC = [[YXWalletCreateViewController alloc]init];
            createVC.isCreate = YES;
            createVC.coinModel = weakSelf.coinModel;
            [weakSelf.navigationController pushViewController:createVC animated:YES];
        };
    }
    return _addWalletView;
}

-(YXWalletAddHomeView *)daoruWalletView{
    if (!_daoruWalletView) {
        _daoruWalletView = [[YXWalletAddHomeView alloc]init];
        _daoruWalletView.title = @"导入已有钱包";
        _daoruWalletView.desc = @"从已备份的钱包助记词或私钥中导入";
        _daoruWalletView.image = [UIImage imageNamed:@"ADD_daoru"];
        YXWeakSelf
        _daoruWalletView.touchBlock = ^{
            YXWalletCreateViewController *createVC = [[YXWalletCreateViewController alloc]init];
            createVC.isCreate = NO;
            createVC.coinModel = weakSelf.coinModel;
            [weakSelf.navigationController pushViewController:createVC animated:YES];
        };
    }
    return _daoruWalletView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.naviView];
    
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.addWalletView];
    [self.view addSubview:self.daoruWalletView];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.top.mas_equalTo(self.naviView.mas_bottom).offset(12);
        make.height.mas_equalTo(20);
    }];
    
    [self.addWalletView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(12);
        make.height.mas_equalTo(90);
    }];
    
    [self.daoruWalletView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.top.mas_equalTo(self.addWalletView.mas_bottom);
        make.height.mas_equalTo(90);
    }];
    
}



@end
