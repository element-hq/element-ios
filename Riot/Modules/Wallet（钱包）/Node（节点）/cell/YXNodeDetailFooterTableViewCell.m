//
//  YXNodeDetailFooterTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeDetailFooterTableViewCell.h"
@interface YXNodeDetailFooterTableViewCell ()
@property (nonatomic , strong)UIView *bottomView;
@end
@implementation YXNodeDetailFooterTableViewCell


-(UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]init];
        _bottomView.backgroundColor = kWhiteColor;
        _bottomView.layer.cornerRadius = 10;
        _bottomView.layer.masksToBounds = YES;
    }
    return _bottomView;
}



- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kBgColor;
        [self setupUI];
        
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.bottomView];

    [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(-10);
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.height.mas_equalTo(36);
    }];
    

}

@end
