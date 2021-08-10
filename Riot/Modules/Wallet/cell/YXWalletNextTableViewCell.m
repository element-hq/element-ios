//
//  YXWalletNextTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletNextTableViewCell.h"
extern NSString *const kYXWalletPrivateKeyNext;
extern NSString *const kYXWalletPrivateKeyCopy;
@interface YXWalletNextTableViewCell ()
@property (nonatomic , strong)UILabel *nextLabel;
@property (nonatomic , strong)UILabel *copyLabel;
@end

@implementation YXWalletNextTableViewCell

-(UILabel *)nextLabel{
    if (!_nextLabel) {
        _nextLabel = [[UILabel alloc]init];
        _nextLabel.numberOfLines = 0;
        _nextLabel.text = @"下一个";
        _nextLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _nextLabel.backgroundColor = RGBA(255,120,0,1);
        _nextLabel.textColor = kWhiteColor;
        _nextLabel.textAlignment = NSTextAlignmentCenter;
        [_nextLabel mm_addTapGestureWithTarget:self action:@selector(nextLabelAction)];
        _nextLabel.layer.cornerRadius = 20;
        _nextLabel.layer.masksToBounds = YES;
    }
    return _nextLabel;
}

- (void)nextLabelAction{
    [self routerEventForName:kYXWalletPrivateKeyNext paramater:nil];
}


-(UILabel *)copyLabel{
    if (!_copyLabel) {
        _copyLabel = [[UILabel alloc]init];
        _copyLabel.numberOfLines = 0;
        _copyLabel.text = @"复制私钥";
        _copyLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _copyLabel.backgroundColor = WalletColor;
        _copyLabel.textColor = kWhiteColor;
        _copyLabel.textAlignment = NSTextAlignmentCenter;
        [_copyLabel mm_addTapGestureWithTarget:self action:@selector(copyLabelAction)];
        _copyLabel.layer.cornerRadius = 20;
        _copyLabel.layer.masksToBounds = YES;
    }
    return _copyLabel;
}

- (void)copyLabelAction{
    [self routerEventForName:kYXWalletPrivateKeyCopy paramater:nil];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kClearColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.nextLabel];
    [self.contentView addSubview:self.copyLabel];
    [self.nextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(33);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
    }];
    
    [self.nextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(130);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.centerX.mas_equalTo(self.contentView.mas_centerX).offset(-85);
    }];
    
    [self.copyLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(130);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.centerX.mas_equalTo(self.contentView.mas_centerX).offset(85);
    }];
}

@end

