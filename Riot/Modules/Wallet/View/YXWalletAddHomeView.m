//
//  YXWalletAddHomeView.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddHomeView.h"

@interface YXWalletAddHomeView ()
@property (nonatomic , strong)UIImageView *titleIcon;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@end
@implementation YXWalletAddHomeView

- (UIImageView *)titleIcon{
    if (!_titleIcon){
        _titleIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"ADD_NEW"]];
        _titleIcon.contentMode = UIViewContentModeScaleAspectFill;
        _titleIcon.layer.masksToBounds = YES;
        _titleIcon.layer.cornerRadius = 22;
    }
    return _titleIcon;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"创建新钱包";
        _titleLabel.font =  [UIFont boldSystemFontOfSize: 20];
        _titleLabel.textColor = UIColor51;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"创建一个全新的钱包";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 13];
        _desLabel.textColor = UIColor153;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = kWhiteColor;
        [self setupUI];
        YXWeakSelf
        [self addTapAction:^(UITapGestureRecognizer *sender) {
            if (weakSelf.touchBlock) {
                weakSelf.touchBlock();
            }
        }];
    }
    return self;
}

- (void)setupUI{
    
    [self addSubview:self.titleIcon];
    [self addSubview:self.titleLabel];
    [self addSubview:self.desLabel];
 
    [self.titleIcon mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mas_centerY);
        make.left.mas_equalTo(15);
        make.width.height.mas_equalTo(44);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleIcon.mas_top);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(18);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.titleIcon.mas_bottom);
        make.left.mas_equalTo(self.titleIcon.mas_right).offset(10);
        make.width.mas_equalTo(240);
        make.height.mas_equalTo(14);
    }];
    
}

-(void)setTitle:(NSString *)title{
    _title = title;
    _titleLabel.text = title;
}


-(void)setDesc:(NSString *)desc{
    _desc = desc;
    _desLabel.text = desc;
}

-(void)setImage:(UIImage *)image{
    _image = image;
    _titleIcon.image = image;
}

@end
