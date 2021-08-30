//
//  YXWalletPopupView.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletPopupView.h"

@interface YXWalletPopupView ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UIImageView *stateIcon;
@property (nonatomic , strong)UIView *lineView;
@property (nonatomic , strong)UIView *marginView;
@property (nonatomic , strong)UILabel *determine;
@property (nonatomic , strong)UILabel *cancel;
@end

@implementation YXWalletPopupView

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor whiteColor];
        _bgView.layer.cornerRadius = 10;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

- (UIImageView *)stateIcon{
    if (!_stateIcon){
        _stateIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"success_wallet_icon"]];
        _stateIcon.contentMode = UIViewContentModeScaleAspectFill;
        _stateIcon.layer.masksToBounds = YES;
        _stateIcon.layer.cornerRadius = 25;
    }
    return _stateIcon;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 1;
        _titleLabel.text = @"删除钱包";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 20];
        _titleLabel.textColor = RGB(33, 33, 33);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 2;
        _desLabel.text = @"此操作会删除您当前设备钱包数据您可以再次使用助记词恢复钱包";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = RGB(99, 99, 99);
        _desLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _desLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = UIColor221;
    }
    return _lineView;
}

- (UIView *)marginView {
    if (!_marginView) {
        _marginView = [[UIView alloc]init];
        _marginView.backgroundColor = UIColor221;
    }
    return _marginView;
}

-(UILabel *)determine{
    if (!_determine) {
        _determine = [[UILabel alloc]init];
        _determine.numberOfLines = 0;
        _determine.text = @"确定删除";
        _determine.font = [UIFont fontWithName:@"PingFang SC" size: 20];
        _determine.textColor = RGB(153, 153, 153);
        _determine.textAlignment = NSTextAlignmentCenter;
        _determine.backgroundColor = kWhiteColor;
        YXWeakSelf
        [_determine addTapAction:^(UITapGestureRecognizer *sender) {
            if (weakSelf.determineBlock) {
                weakSelf.determineBlock();
            }
        }];
    }
    return _determine;
}

-(UILabel *)cancel{
    if (!_cancel) {
        _cancel = [[UILabel alloc]init];
        _cancel.numberOfLines = 0;
        _cancel.text = @"再想想";
        _cancel.font = [UIFont fontWithName:@"PingFang SC" size: 20];
        _cancel.textColor = WalletColor;
        _cancel.textAlignment = NSTextAlignmentCenter;
        _cancel.backgroundColor = kWhiteColor;
        YXWeakSelf
        [_cancel addTapAction:^(UITapGestureRecognizer *sender) {
            if (weakSelf.cancelBlock) {
                weakSelf.cancelBlock();
            }
        }];
    }
    return _cancel;
}

- (instancetype)initWithFrame:(CGRect)frame type:(WalletPopupViewType)type{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = RGBA(0, 0, 0, 0.3);
        [self setupUIwithtype:type];
    }
    return self;
}

- (void)setupUIwithtype:(WalletPopupViewType)type{
    [self addSubview:self.bgView];
    [self.bgView addSubview:self.stateIcon];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.lineView];
    [self.bgView addSubview:self.marginView];
    [self.bgView addSubview:self.determine];
    [self.bgView addSubview:self.cancel];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(300);
        make.height.mas_equalTo(200);
        make.centerY.mas_equalTo(self.mas_centerY);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.stateIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(55);
        make.height.mas_equalTo(55);
        make.top.mas_equalTo(15);;
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(19);
        make.top.mas_equalTo(self.stateIcon.mas_bottom).offset(10);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(10);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.bottom.mas_equalTo(-50);
        make.height.mas_equalTo(1);
    }];
    
    [self.marginView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.lineView.mas_bottom).offset(0);
        make.centerX.mas_equalTo(self.mas_centerX);
        make.bottom.mas_equalTo(0);
        make.width.mas_equalTo(1);
    }];
    
    [self.determine mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.top.mas_equalTo(self.lineView.mas_bottom).offset(0);
        make.bottom.mas_equalTo(0);
        make.right.mas_equalTo(self.marginView.mas_left).offset(0);
    }];
    
    [self.cancel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(0);
        make.top.mas_equalTo(self.lineView.mas_bottom).offset(0);
        make.bottom.mas_equalTo(0);
        make.left.mas_equalTo(self.marginView.mas_right).offset(0);
    }];
    
    [self showPopupUIWithType:type];
}
   
- (void)showPopupUIWithType:(WalletPopupViewType)type{
    switch (type) {
        case WalletPopupViewDXCGType:{//兑现-成功
            [self showPopupUIWith:@"提交成功" des:@"您的兑现申请已提交" State:WalletPopupViewSuccessState center:YES];
        }
            
            break;
        case WalletPopupViewCJCGType:{//钱包创建成功

            [self showPopupUIWith:@"创建成功" des:@"恭喜您，您的钱包已创建成功！" State:WalletPopupViewSuccessState center:YES];
        }
            
            break;
        case WalletPopupViewCXZFType:{//取消支付
            [self showPopupUIWith:@"取消支付" des:@"取消支付后，待处理交易将会被删除" State:WalletPopupViewWalletState center:NO];
            _cancel.text = @"继续支付";
            _determine.text = @"确认离开";
            
        }
            
            break;
        case WalletPopupViewSCQBType:{//删除钱包
            [self showPopupUIWith:@"删除钱包" des:@"此操作会删除您当前设备钱包数据您可以再次使用助记词恢复钱包" State:WalletPopupViewWalletState center:NO];
            
        }
            
            break;
        case WalletPopupViewTJCGType:{//添加收款账户成功
            
            [self showPopupUIWith:@"添加成功" des:@"您已成功添加新的账户到您的收款账户" State:WalletPopupViewSuccessState center:YES];
        }
            
            break;
        case WalletPopupViewZFCGType:{//支付成功
            [self showPopupUIWith:@"支付成功" des:@"恭喜您支付成功，您可回到首页查看记录" State:WalletPopupViewSuccessState center:YES];
            
        }
            
            break;
        case WalletPopupViewZFSBType:{ //支付失败
            [self showPopupUIWith:@"支付失败" des:@"您输入的密码有误，请核对后重试" State:WalletPopupViewFailState center:NO];
            _determine.text = @"取消";
            _cancel.text = @"重试";
            
        }
            
            break;
        case WalletPopupViewJDDQType:{//主节点-节点详情（到期）
            [self showPopupUIWith:@"节点服务器到期" des:@"您的节点服务器已经到期，此服务器我们将为您保留15日，为避免造成损失，请及时续费！" State:WalletPopupViewWalletState center:YES];
            _cancel.text = @"知道了";
        }
            
            break;
        case WalletPopupViewPZCGType:{//主节点配置成功
            [self showPopupUIWith:@"激活成功" des:@"恭喜您已成功激活主节点" State:WalletPopupViewSuccessState center:YES];
        }
            break;
        case WalletPopupViewXGCGType:{//修改成功
            [self showPopupUIWith:@"修改成功" des:@"您的钱包密码修改成功，请牢记您的新密码" State:WalletPopupViewSuccessState center:YES];
        }
            break;
        case WalletPopupViewJYZDType:{//解冻质押
            [self showPopupUIWith:@"解冻质押" des:@"该操作将解冻质押链分并回收服务器，请确认？" State:WalletPopupViewWalletState center:NO];
            _cancel.text = @"确定解冻";
            _determine.text = @"取消";
        }
            break;
        default:
            break;
    }
}

- (void)showPopupUIWith:(NSString *)title des:(NSString *)des State:(WalletPopupViewState)state center:(BOOL)center{
    self.titleLabel.text = title;
    self.desLabel.text = des;
    UIImage *image;
    if (state == WalletPopupViewSuccessState) {
        image = [UIImage imageNamed:@"success_wallet_icon"];
    }else if (state == WalletPopupViewFailState){
        image = [UIImage imageNamed:@"fail_wallet_icon"];
    }else if (state == WalletPopupViewWalletState){
        image = [UIImage imageNamed:@"warning_wallet_icon"];
    }
    self.stateIcon.image = image;
    if (center) {
        [self centerUI];
    }
  
}

- (void)centerUI{
    [self.cancel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(0);
        make.top.mas_equalTo(self.lineView.mas_bottom).offset(0);
        make.bottom.mas_equalTo(0);
        make.left.mas_equalTo(0);
    }];
    self.cancel.text = @"好的";
    self.determine.hidden = YES;
    self.marginView.hidden = YES;
}

@end

