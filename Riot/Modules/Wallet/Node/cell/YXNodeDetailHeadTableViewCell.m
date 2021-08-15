//
//  YXNodeDetailHeadTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeDetailHeadTableViewCell.h"
extern NSString *const kYXWalletActivationNode;
extern NSString *const kYXWalletArmingFlagNode;
@interface YXNodeDetailHeadTableViewCell ()
@property (nonatomic , strong)UIImageView *bgImageView;
@property (nonatomic , strong)UIView *activationView;
@property (nonatomic , strong)UILabel *activationLabel;
@property (nonatomic , strong)UIView *bottomView;
@property (nonatomic , strong)UILabel *titleLabel;
@end
@implementation YXNodeDetailHeadTableViewCell

- (UIImageView *)bgImageView{
    if (!_bgImageView){
        _bgImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"jiedian_working"]];
        _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        _bgImageView.clipsToBounds = YES;
        _bgImageView.userInteractionEnabled = YES;
    
    }
    return _bgImageView;
}

-(UIView *)activationView{
    if (!_activationView) {
        _activationView = [[UIView alloc]init];
        _activationView.backgroundColor = RGBA(255, 255, 255, 0.3);
        _activationView.layer.cornerRadius = 25;
        _activationView.layer.masksToBounds = YES;
        _activationView.userInteractionEnabled = YES;
    }
    return _activationView;
}

-(UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]init];
        _bottomView.backgroundColor = kWhiteColor;
        _bottomView.layer.cornerRadius = 10;
        _bottomView.layer.masksToBounds = YES;
    }
    return _bottomView;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"节点信息";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = UIColor51;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

-(UILabel *)activationLabel{
    if (!_activationLabel) {
        _activationLabel = [[UILabel alloc]init];
        _activationLabel.numberOfLines = 0;
        _activationLabel.text = @"重新激活";
        _activationLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _activationLabel.textColor = RGBA(255,160,0,1);
        _activationLabel.textAlignment = NSTextAlignmentCenter;
        _activationLabel.layer.cornerRadius = 20;
        _activationLabel.layer.masksToBounds = YES;
        _activationLabel.backgroundColor = kWhiteColor;
        YXWeakSelf
        [_activationLabel addTapAction:^(UITapGestureRecognizer *sender) {
            if ([weakSelf.activationLabel.text isEqualToString:@"重新激活"]) {
                [weakSelf routerEventForName:kYXWalletActivationNode paramater:nil];
            }else{
                [weakSelf routerEventForName:kYXWalletArmingFlagNode paramater:nil];
            }
        }];
    }
    return _activationLabel;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kBgColor;
        [self setupUI];
        
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.bgImageView];
    [self.bgImageView addSubview:self.activationView];
    [self.activationView addSubview:self.activationLabel];
    [self.bgImageView addSubview:self.bottomView];
    [self.bottomView addSubview:self.titleLabel];
    
    [self.bgImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    
    [self.activationView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
        make.height.mas_equalTo(50);
        make.width.mas_equalTo(160);
        make.top.mas_equalTo(50 + StatusSizeH);
    }];
    
    [self.activationLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.activationView.mas_centerX);
        make.centerY.mas_equalTo(self.activationView.mas_centerY);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(150);
       
    }];
    
    [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(10);
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.height.mas_equalTo(40);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
        make.height.mas_equalTo(16);
        make.width.mas_equalTo(160);
        make.bottom.mas_equalTo(-14);
    }];

}

-(void)setupCellWithRowData:(NSString *)rowData{
    _activationLabel.text = rowData;
    if ([rowData isEqualToString:@"重新激活"]) {
        _bgImageView.image = [UIImage imageNamed:@"jiedian_working"];
        _titleLabel.hidden = NO;
    }else{
        _bgImageView.image = [UIImage imageNamed:@"jiedian_diaox"];
        _titleLabel.hidden = YES;
    }
}

@end

