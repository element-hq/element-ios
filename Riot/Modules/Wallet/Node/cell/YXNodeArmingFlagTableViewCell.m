// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "YXNodeArmingFlagTableViewCell.h"
#import "YXNodeDetailModel.h"
@interface YXNodeArmingFlagTableViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UIImageView *stateIcon;

@end

@implementation YXNodeArmingFlagTableViewCell

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.alpha = 1;
        _bgView.backgroundColor = kWhiteColor;
    }
    return _bgView;
}


- (UIImageView *)stateIcon{
    if (!_stateIcon){
        _stateIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"warning_wallet_icon"]];
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
        _titleLabel.text = @"您的节点服务器已停机";
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
        _desLabel.text = @"由于您的节点在规定的期限内未完成续费，您的服务器已经停止工作。若您的1000质押交易尚未解冻，请点击上方的“解冻质押”按钮进行解冻，解冻后即可以自由提现及交易。";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _desLabel.textColor = UIColor153;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kBgColor;
        [self setupUI];
        
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.stateIcon];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.desLabel];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [self.stateIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(55);
        make.height.mas_equalTo(55);
        make.top.mas_equalTo(0);;
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(19);
        make.top.mas_equalTo(self.stateIcon.mas_bottom).offset(15);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(30);
        make.centerX.mas_equalTo(self.mas_centerX);
    }];

}


@end
