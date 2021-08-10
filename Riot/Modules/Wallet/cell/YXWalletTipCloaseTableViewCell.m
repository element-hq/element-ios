//
//  YXWalletTipCloaseTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletTipCloaseTableViewCell.h"
#import "YXWalletTipCloseView.h"
#import "YXWalletSendModel.h"
 
extern NSString *const kYXWalletNextCloseTipView;

@interface YXWalletTipCloaseTableViewCell ()
@property (nonatomic , strong)YXWalletTipCloseView *tipCloseView;
@end
@implementation YXWalletTipCloaseTableViewCell

-(YXWalletTipCloseView *)tipCloseView{
    if (!_tipCloseView) {
        _tipCloseView = [[YXWalletTipCloseView alloc]init];
        YXWeakSelf
        _tipCloseView.closeBlock = ^{
            [weakSelf routerEventForName:kYXWalletNextCloseTipView paramater:weakSelf];
        };
    }
    return _tipCloseView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kClearColor;
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    [self.contentView addSubview:self.tipCloseView];
    [self.tipCloseView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.mas_equalTo(0);
    }];
}

-(void)setupCellWithRowData:(id)rowData{
    if ([rowData isKindOfClass:YXWalletSendModel.class]) {
        YXWalletSendModel *model = (YXWalletSendModel *)rowData;
        self.tipCloseView.title = model.desc;
    }else if ([rowData isKindOfClass:NSString.class]){
        self.tipCloseView.title = (NSString *)rowData;
    }
   
}

@end
