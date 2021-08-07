//
//  YXNodeConfigView.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeConfigView.h"
@interface YXNodeConfigView ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UILabel *titleLabel;

@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *pledgeDealLabe;//质押交易
@property (nonatomic , strong)UIView *lineView;

@property (nonatomic , strong)UILabel *mainLabel;
@property (nonatomic , strong)UILabel *mainNodeLabe;//主节点
@property (nonatomic , strong)UIView *mainlineView;



@end
@implementation YXNodeConfigView

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.alpha = 1;
        _bgView.layer.cornerRadius = 10;
        _bgView.clipsToBounds = YES;
        _bgView.backgroundColor = kWhiteColor;
    }
    return _bgView;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"主节点配置";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 16];
        _titleLabel.textColor = UIColor51;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"质押交易";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 16];
        _desLabel.textColor = UIColor51;
        _desLabel.textAlignment = NSTextAlignmentLeft;
        YXWeakSelf
        [_desLabel addTapAction:^(UITapGestureRecognizer *sender) {
            if (weakSelf.pledgeDealBlock) {
                weakSelf.pledgeDealBlock();
            }
        }];
    }
    return _desLabel;
}

-(UILabel *)pledgeDealLabe{
    if (!_pledgeDealLabe) {
        _pledgeDealLabe = [[UILabel alloc]init];
        _pledgeDealLabe.numberOfLines = 0;
        _pledgeDealLabe.text = @"请选择数量为整1000的资产作为质押交易";
        _pledgeDealLabe.font = [UIFont fontWithName:@"PingFang SC" size: 16];
        _pledgeDealLabe.textColor = UIColor170;
        _pledgeDealLabe.textAlignment = NSTextAlignmentLeft;
        YXWeakSelf
        [_pledgeDealLabe addTapAction:^(UITapGestureRecognizer *sender) {
            if (weakSelf.pledgeDealBlock) {
                weakSelf.pledgeDealBlock();
            }
        }];
    }
    return _pledgeDealLabe;
}


- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = UIColor221;
    }
    return _lineView;
}


-(UILabel *)mainLabel{
    if (!_mainLabel) {
        _mainLabel = [[UILabel alloc]init];
        _mainLabel.numberOfLines = 0;
        _mainLabel.text = @"主节点";
        _mainLabel.font = [UIFont fontWithName:@"PingFang SC" size: 16];
        _mainLabel.textColor = UIColor51;
        _mainLabel.textAlignment = NSTextAlignmentLeft;
        YXWeakSelf
        [_mainLabel addTapAction:^(UITapGestureRecognizer *sender) {
            if (weakSelf.mainNodeBlock) {
                weakSelf.mainNodeBlock();
            }
        }];
    }
    return _mainLabel;
}

-(UILabel *)mainNodeLabe{
    if (!_mainNodeLabe) {
        _mainNodeLabe = [[UILabel alloc]init];
        _mainNodeLabe.numberOfLines = 0;
        _mainNodeLabe.text = @"请选择主节点";
        _mainNodeLabe.font = [UIFont fontWithName:@"PingFang SC" size: 16];
        _mainNodeLabe.textColor = UIColor170;
        _mainNodeLabe.textAlignment = NSTextAlignmentLeft;
        YXWeakSelf
        [_mainNodeLabe addTapAction:^(UITapGestureRecognizer *sender) {
            if (weakSelf.mainNodeBlock) {
                weakSelf.mainNodeBlock();
            }
        }];
    }
    return _mainNodeLabe;
}


- (UIView *)mainlineView {
    if (!_mainlineView) {
        _mainlineView = [[UIView alloc]init];
        _mainlineView.backgroundColor = UIColor221;
    }
    return _mainlineView;
}


-(UILabel *)sendLabel{
    if (!_sendLabel) {
        _sendLabel = [[UILabel alloc]init];
        _sendLabel.numberOfLines = 0;
        _sendLabel.text = @"激活";
        _sendLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _sendLabel.textColor = kWhiteColor;
        _sendLabel.textAlignment = NSTextAlignmentCenter;
        [_sendLabel mm_addTapGestureWithTarget:self action:@selector(sendLabelAction)];
        _sendLabel.backgroundColor = RGBA(255,160,0,0.3);
        _sendLabel.userInteractionEnabled = NO;
        _sendLabel.layer.cornerRadius = 20;
        _sendLabel.layer.masksToBounds = YES;
    }
    return _sendLabel;
}

- (void)sendLabelAction{
    if (self.activationBlock){
        self.activationBlock();
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = kBgColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
    [self addSubview:self.bgView];
    [self.bgView addSubview:self.titleLabel];
    
    [self.bgView addSubview:self.desLabel];
    [self.bgView addSubview:self.pledgeDealLabe];
    [self.bgView addSubview:self.lineView];
    
    [self.bgView addSubview:self.mainLabel];
    [self.bgView addSubview:self.mainNodeLabe];
    [self.bgView addSubview:self.mainlineView];
    
    
    [self.bgView addSubview:self.sendLabel];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(30);
        make.height.mas_equalTo(480);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.bgView.mas_centerX);
        make.height.mas_equalTo(16);
        make.width.mas_equalTo(160);
        make.top.mas_equalTo(30);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(15);
        make.top.mas_equalTo(90);
    }];
    
    [self.pledgeDealLabe mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(30);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(1);
        make.top.mas_equalTo(self.pledgeDealLabe.mas_bottom).offset(10);
    }];
    
    
    [self.mainLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(15);
        make.top.mas_equalTo(235);
    }];
    
    [self.mainNodeLabe mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.mainLabel.mas_bottom).offset(30);
    }];
    
    [self.mainlineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-15);
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(1);
        make.top.mas_equalTo(self.mainNodeLabe.mas_bottom).offset(10);
    }];
    
    [self.sendLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(38);
        make.right.mas_equalTo(-38);
        make.height.mas_equalTo(40);
        make.bottom.mas_equalTo(-51);
    }];
    
}

-(void)setPledgeText:(NSString *)pledgeText{
    _pledgeText = pledgeText;
    _pledgeDealLabe.text = pledgeText;
}

-(void)setNodeText:(NSString *)nodeText{
    _nodeText = nodeText;
    _mainNodeLabe.text = nodeText;
}

@end
