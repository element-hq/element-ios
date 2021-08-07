//
//  YXNodeNoDetailTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/27.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeNoDetailTableViewCell.h"

@interface YXNodeNoDetailTableViewCell ()
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UIImageView *addIcon;
@end

@implementation YXNodeNoDetailTableViewCell

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"暂未发现可配置节点";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = UIColor51;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}


- (UIImageView *)addIcon{
    if (!_addIcon){
        _addIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"Master_node_none"]];
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
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(15);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
        make.top.mas_equalTo(43);
    }];
    
    
    [self.addIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(36);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
        make.width.mas_equalTo(214);
        make.height.mas_equalTo(207);
    }];
}



@end
