//
//  YXAssetsDetailSendView.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/27.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXAssetsDetailSendView.h"
@interface YXAssetsDetailSendView ()
@property (nonatomic , strong)UILabel *receiveLabel;
@property (nonatomic , strong)UILabel *sendLabel;
@end
@implementation YXAssetsDetailSendView

-(UILabel *)receiveLabel{
    if (!_receiveLabel) {
        _receiveLabel = [[UILabel alloc]init];
        _receiveLabel.numberOfLines = 0;
        _receiveLabel.text = @"接收";
        _receiveLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _receiveLabel.backgroundColor = RGBA(255,120,0,1);
        _receiveLabel.textColor = kWhiteColor;
        _receiveLabel.textAlignment = NSTextAlignmentCenter;
        [_receiveLabel mm_addTapGestureWithTarget:self action:@selector(receiveLabelAction)];
        _receiveLabel.layer.cornerRadius = 20;
        _receiveLabel.layer.masksToBounds = YES;
    }
    return _receiveLabel;
}

- (void)receiveLabelAction{
    if(self.receiveBlock){
        self.receiveBlock();
    }
}


-(UILabel *)sendLabel{
    if (!_sendLabel) {
        _sendLabel = [[UILabel alloc]init];
        _sendLabel.numberOfLines = 0;
        _sendLabel.text = @"发送";
        _sendLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _sendLabel.backgroundColor = WalletColor;
        _sendLabel.textColor = kWhiteColor;
        _sendLabel.textAlignment = NSTextAlignmentCenter;
        [_sendLabel mm_addTapGestureWithTarget:self action:@selector(sendLabelAction)];
        _sendLabel.layer.cornerRadius = 20;
        _sendLabel.layer.masksToBounds = YES;
    }
    return _sendLabel;
}

- (void)sendLabelAction{
    if(self.sendBlock){
        self.sendBlock();
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = kWhiteColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
    [self addSubview:self.receiveLabel];
    [self addSubview:self.sendLabel];
    [self.receiveLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(33);
        make.centerY.mas_equalTo(self.mas_centerY);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.receiveLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(130);
        make.centerY.mas_equalTo(self.mas_centerY);
        make.centerX.mas_equalTo(self.mas_centerX).offset(-85);
    }];
    
    [self.sendLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(130);
        make.centerY.mas_equalTo(self.mas_centerY);
        make.centerX.mas_equalTo(self.mas_centerX).offset(85);
    }];
}


@end
