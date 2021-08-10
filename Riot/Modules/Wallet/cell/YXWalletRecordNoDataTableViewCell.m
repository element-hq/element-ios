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

#import "YXWalletRecordNoDataTableViewCell.h"

@interface YXWalletRecordNoDataTableViewCell ()
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UIImageView *addIcon;
@end

@implementation YXWalletRecordNoDataTableViewCell

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"没有兑现记录";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _titleLabel.textColor = UIColor170;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}


- (UIImageView *)addIcon{
    if (!_addIcon){
        _addIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon_nothing"]];
        _addIcon.contentMode = UIViewContentModeScaleAspectFill;
        _addIcon.clipsToBounds = YES;
    
    }
    return _addIcon;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kWhiteColor;
        [self setupUI];
        
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.addIcon];

    [self.addIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(10);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
        make.width.mas_equalTo(172);
        make.height.mas_equalTo(172);
    }];
    
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(15);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
        make.top.mas_equalTo(self.addIcon.mas_bottom).offset(15);
    }];
    
}



@end
