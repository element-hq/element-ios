//
//  YXNodeConfigViewController.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeConfigViewController.h"
#import "YXNodeConfigView.h"
#import "YXNodeSettingView.h"
#import "YXNodeDetailViewModel.h"
#import "YXWalletPopupView.h"
@interface YXNodeConfigViewController ()
@property (nonatomic , strong) YXNaviView *naviView;
@property (nonatomic , strong) YXNodeConfigView *nodeConfigView;
@property (nonatomic , strong) YXNodeSettingView *nodeSettingView;
@property (nonatomic , strong) YXNodeDetailViewModel *viewModel;
@property (nonatomic , strong) YXNodeConfigDataItem *configData;
@property (nonatomic , strong) YXNodeListdata *noteInfo;
@property (nonatomic , assign) BOOL is_pledeg;
@property (nonatomic , assign) BOOL is_noteInfo;
@property (nonatomic , strong) YXWalletPopupView *walletPopupView;
@end

@implementation YXNodeConfigViewController


-(YXWalletPopupView *)walletPopupView{
    if (!_walletPopupView) {
        _walletPopupView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewPZCGType];
        YXWeakSelf
        _walletPopupView.cancelBlock = ^{
            weakSelf.walletPopupView.hidden = YES;
            [weakSelf.navigationController popViewControllerAnimated:YES];
            if (weakSelf.reloadDataBlock) {
                weakSelf.reloadDataBlock();
            }
        };
        _walletPopupView.hidden = YES;
    }
    return _walletPopupView;
}


-(YXNodeDetailViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXNodeDetailViewModel alloc]init];
        YXWeakSelf
        [_viewModel setGetNodeInfoBlock:^{
            weakSelf.nodeConfigView.nodeText = [NSString stringWithFormat:@"IP:%@\n%@", weakSelf.viewModel.nodeInfoModel.ip, weakSelf.viewModel.nodeInfoModel.genkey];
            weakSelf.noteInfo =  weakSelf.viewModel.nodeInfoModel;
        }];;

    }
    return _viewModel;
}


-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"主节点配置";
        _naviView.titleColor = UIColor51;
        _naviView.backgroundColor = kClearColor;
        _naviView.leftImage = [UIImage imageNamed:@"back_b_black"];
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        
    }
    return _naviView;
}

-(YXNodeConfigView *)nodeConfigView{
    if (!_nodeConfigView) {
        _nodeConfigView = [[YXNodeConfigView alloc]init];
        YXWeakSelf
        [_nodeConfigView setPledgeDealBlock:^{
            weakSelf.nodeSettingView.pledegModel = weakSelf.viewModel.pledegModel;
            weakSelf.nodeSettingView.hidden = NO;
         
        }];
        [_nodeConfigView setMainNodeBlock:^{
            weakSelf.nodeSettingView.nodeInfoModel = weakSelf.viewModel.nodeInfoModel;
            weakSelf.nodeSettingView.hidden = NO;
         
        }];
        
        [_nodeConfigView setActivationBlock:^{
            [weakSelf activationAction];
        }];
    }
    return _nodeConfigView;
}

-(YXNodeSettingView *)nodeSettingView{
    if (!_nodeSettingView) {
        _nodeSettingView = [[YXNodeSettingView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _nodeSettingView.hidden = YES;
        YXWeakSelf
        [_nodeSettingView setSelectTXblock:^(YXNodeConfigDataItem * _Nonnull model) {
            weakSelf.configData = model;
            weakSelf.nodeConfigView.pledgeText = model.txid;
            weakSelf.is_pledeg = YES;
        }];
        
        [_nodeSettingView setSelectNodeInfoblock:^(YXNodeListdata * _Nonnull model) {
            weakSelf.noteInfo = model;
            weakSelf.nodeConfigView.nodeText = [NSString stringWithFormat:@"IP:%@\n%@",model.ip,model.genkey];
            weakSelf.is_noteInfo = YES;
        }];
    }
    return _nodeSettingView;
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if (!self.nodeSettingView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.nodeSettingView];
    }
    
    if (!self.walletPopupView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletPopupView];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kBgColor;
    [self.view addSubview:self.naviView];
    [self.view addSubview:self.nodeConfigView];
    [self.nodeConfigView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.mas_equalTo(0);
        make.top.mas_equalTo(self.naviView.mas_bottom);
    }];
    
    [self.viewModel getPledegTxData:self.nodeListModel];
    [self.viewModel getNodeInfo:self.nodeListModel];
}

- (void)setIs_pledeg:(BOOL)is_pledeg{
    _is_pledeg = is_pledeg;
    [self changeSendUI];
}

-(void)setIs_noteInfo:(BOOL)is_noteInfo{
    _is_noteInfo = is_noteInfo;
    [self changeSendUI];
}

- (void)changeSendUI{
    
    if (_is_pledeg) {
        _nodeConfigView.sendLabel.backgroundColor = RGBA(255,160,0,1);
        _nodeConfigView.sendLabel.userInteractionEnabled = YES;
    }

}

- (void)activationAction{
    
    if (self.configData.confirmations < 15) {
        [MBProgressHUD showSuccess:[NSString stringWithFormat:@"质押交易需要15个区块确认，现还需要%ld区块确认",(15 - self.configData.confirmations)]];
        return;
    }
    
    YXWeakSelf
    [self.viewModel configNodeActivityWalletId:self.nodeListModel.walletId txid:self.configData.txid vout:@(self.configData.vout).stringValue ip:self.noteInfo.ip privateKey:self.nodeListModel.genkey Complete:^{
        weakSelf.walletPopupView.hidden = NO;
    }];
}

@end
