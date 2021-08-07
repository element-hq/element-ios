//
//  YXWalletHelpWordTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletHelpWordTableViewCell.h"
#import "TTTagView.h"
@interface YXWalletHelpWordTableViewCell ()
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)TTTagView *tagView;
@end

@implementation YXWalletHelpWordTableViewCell
-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor whiteColor];
        _bgView.layer.cornerRadius = 10;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

-(TTTagView *)tagView{
    if (!_tagView) {
        _tagView = [[TTTagView alloc] init];
        _tagView.numberOfLines = 3;
        _tagView.backgroundColor = kClearColor;
        _tagView.tagTextColor = RGB(153, 153, 153);
        _tagView.tagBackgroundColor = kWhiteColor;
        _tagView.tagBorderColor = RGB(153, 153, 153);
        _tagView.userInteractionEnabled = NO;
    }
    return _tagView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kClearColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.bgView];
    [self.bgView addSubview:self.tagView];
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.bottom.mas_equalTo(0);
    }];
    
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(13);
        make.bottom.mas_equalTo(-13);
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
    }];
    
}

-(void)setupCellWithRowData:(NSArray *)rowData{
    self.tagView.tagsArray = rowData;
}

@end
