//
//  YXWalletCreateWorldView.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCreateWorldView.h"
#import "TTTagView.h"
@interface YXWalletCreateWorldView ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)TTTagView *tagView;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *nextLabel;
@end

@implementation YXWalletCreateWorldView

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.alpha = 1;
        _bgView.layer.cornerRadius = 10;
        _bgView.clipsToBounds = YES;
        _bgView.backgroundColor = kClearColor;
    }
    return _bgView;
}

-(TTTagView *)tagView{
    if (!_tagView) {
        _tagView = [[TTTagView alloc] init];
        _tagView.numberOfLines = 3;
        _tagView.backgroundColor = kClearColor;
        _tagView.tagTextColor = kWhiteColor;
        _tagView.tagBackgroundColor = WalletColor;
        _tagView.tagBorderColor = kWhiteColor;
        _tagView.userInteractionEnabled = NO;
    }
    return _tagView;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"注意：助记词是用户钱包的唯一标识，不能分享给他人，严格保密。掌握该助记词的用户即可控制该钱包。";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = kWhiteColor;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

-(UILabel *)nextLabel{
    if (!_nextLabel) {
        _nextLabel = [[UILabel alloc]init];
        _nextLabel.numberOfLines = 0;
        _nextLabel.text = @"下一个";
        _nextLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _nextLabel.backgroundColor = kWhiteColor;
        _nextLabel.textColor = WalletColor;
        _nextLabel.textAlignment = NSTextAlignmentCenter;
        [_nextLabel mm_addTapGestureWithTarget:self action:@selector(nextLabelAction)];
        _nextLabel.layer.cornerRadius = 20;
        _nextLabel.layer.masksToBounds = YES;
    }
    return _nextLabel;
}

- (void)nextLabelAction{
    if (self.nextBlock) {
        self.nextBlock();
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = WalletColor;
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;
        [self setupUI];

    }
    return self;
}

- (void)setupUI{
    [self addSubview:self.bgView];
    [self.bgView addSubview:self.tagView];
    
    [self addSubview:self.desLabel];
    [self addSubview:self.nextLabel];
    
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(0);
        make.height.mas_equalTo(150);
    }];
    
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(13);
        make.bottom.mas_equalTo(-13);
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.tagView.mas_bottom).offset(30);
        make.height.mas_equalTo(40);
    }];
    
    [self.nextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-23);
        make.height.mas_equalTo(40);
        make.left.mas_equalTo(23);
        make.right.mas_equalTo(-23);
    }];
}

-(void)setTagsArray:(NSArray *)tagsArray{
    YXWeakSelf
    //每次赋值必须移除上一次记录
    [_tagsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf.tagView removeTag:obj];
    }];
    
    _tagsArray = tagsArray;
    
    [tagsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakSelf.tagView addTag:obj];
    }];
}



@end
