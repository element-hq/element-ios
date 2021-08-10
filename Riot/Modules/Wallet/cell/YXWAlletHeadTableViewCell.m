//
//  YXWAlletHeadTableViewCell.m
//  UniversalApp
//
//  Created by liaoshen on 2021/6/22.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import "YXWAlletHeadTableViewCell.h"
extern NSString *const kYXWalletJumpSendEditDetail;
extern NSString *const kYXWalletJumpReceiveCodeVC;
extern NSString *const kYXWalletJumpCashVC;
@interface YXWAlletHeadTableViewCell ()
@property (nonatomic , strong)UIView *bottomView;
@property (nonatomic , strong)UIButton *sendBtn;
@property (nonatomic , strong)UIButton *receiveCodeBtn;
@property (nonatomic , strong)UIButton *cashBtn;
@end

@implementation YXWAlletHeadTableViewCell

-(UIButton *)sendBtn{
    if (!_sendBtn) {
        _sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sendBtn setImage:[UIImage imageNamed:@"home_top_send.png"] forState:UIControlStateNormal];
        [_sendBtn addTarget:self action:@selector(sendBtnAction) forControlEvents:UIControlEventTouchUpInside];
        [_sendBtn setTitle:@"发送" forState:UIControlStateNormal];
        _sendBtn.titleLabel.textColor = UIColor.whiteColor;
        _sendBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        [_sendBtn jk_setImagePosition:LXMImagePositionTop spacing:8.0];
    }
    return _sendBtn;
}

- (void)sendBtnAction{
    [self routerEventForName:kYXWalletJumpSendEditDetail paramater:nil];
}

-(UIButton *)receiveCodeBtn{
    if (!_receiveCodeBtn) {
        _receiveCodeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_receiveCodeBtn setImage:[UIImage imageNamed:@"home_top_qr.png"] forState:UIControlStateNormal];
        [_receiveCodeBtn addTarget:self action:@selector(receiveCodeBtnAction) forControlEvents:UIControlEventTouchUpInside];
        [_receiveCodeBtn setTitle:@"接收码" forState:UIControlStateNormal];
        _receiveCodeBtn.titleLabel.textColor = UIColor.whiteColor;
        _receiveCodeBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        [_receiveCodeBtn jk_setImagePosition:LXMImagePositionTop spacing:8.0];
    }
    return _receiveCodeBtn;
}

- (void)receiveCodeBtnAction{
    [self routerEventForName:kYXWalletJumpReceiveCodeVC paramater:nil];
}

-(UIButton *)cashBtn{
    if (!_cashBtn) {
        _cashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cashBtn setImage:[UIImage imageNamed:@"home_top_tixian.png"] forState:UIControlStateNormal];
        [_cashBtn addTarget:self action:@selector(cashBtnAction) forControlEvents:UIControlEventTouchUpInside];
        [_cashBtn setTitle:@"兑现" forState:UIControlStateNormal];
        _cashBtn.titleLabel.textColor = UIColor.whiteColor;
        _cashBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        [_cashBtn jk_setImagePosition:LXMImagePositionTop spacing:8.0];
    }
    return _cashBtn;
}

- (void)cashBtnAction{
    [self routerEventForName:kYXWalletJumpCashVC paramater:nil];
}

-(UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]init];
        _bottomView.backgroundColor = UIColor.clearColor;
    }
    return _bottomView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.clipsToBounds = YES;
        self.backgroundColor = WalletColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
    [self.contentView addSubview:self.bottomView];
    [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.mas_equalTo(0);
        make.height.mas_equalTo(120);
    }];
    
    [self.bottomView addSubview:self.receiveCodeBtn];
    [self.bottomView addSubview:self.sendBtn];
    [self.bottomView addSubview:self.cashBtn];

    [self.receiveCodeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.bottomView.mas_centerX);
        make.top.bottom.mas_equalTo(0);
        make.width.mas_equalTo(SCREEN_WIDTH/3);
    }];

    [self.sendBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.left.mas_equalTo(0);
        make.width.mas_equalTo(SCREEN_WIDTH/3);
    }];

    [self.cashBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.mas_equalTo(0);
        make.width.mas_equalTo(SCREEN_WIDTH/3);
    }];
    
}



@end
