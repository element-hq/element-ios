//
//  YXNodeSelectTableViewCell.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeSelectTableViewCell.h"
#import "YXWalletMyWalletModel.h"

extern NSString *const kYXNodeSelectConfig;

@interface YXNodeSelectTableViewCell ()
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *dropsLabel;
@property (nonatomic , strong)UILabel *normalLabel;
@property (nonatomic , strong)YXWalletMyWalletRecordsItem *rowData;
@end

@implementation YXNodeSelectTableViewCell

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"状态筛选";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 13];
        _desLabel.textColor = UIColor51;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

-(UILabel *)dropsLabel{
    if (!_dropsLabel) {
        _dropsLabel = [[UILabel alloc]init];
        _dropsLabel.numberOfLines = 0;
        _dropsLabel.text = @"节点掉线";
        _dropsLabel.font = [UIFont fontWithName:@"PingFang SC" size: 13];
        _dropsLabel.textColor = kWhiteColor;
        _dropsLabel.textAlignment = NSTextAlignmentCenter;
        _dropsLabel.layer.cornerRadius = 10;
        _dropsLabel.layer.masksToBounds = YES;
        _dropsLabel.backgroundColor = RGBA(255,160,0,1);
        YXWeakSelf
        [_dropsLabel addTapAction:^(UITapGestureRecognizer * _Nonnull sender) {
            weakSelf.rowData.noteType = YXWalletNoteTypeDrops;
            [weakSelf routerEventForName:kYXNodeSelectConfig paramater:weakSelf.rowData];
        }];
    }
    return _dropsLabel;
}

-(UILabel *)normalLabel{
    if (!_normalLabel) {
        _normalLabel = [[UILabel alloc]init];
        _normalLabel.numberOfLines = 0;
        _normalLabel.text = @"正常运行";
        _normalLabel.font = [UIFont fontWithName:@"PingFang SC" size: 13];
        _normalLabel.textColor = UIColor153;
        _normalLabel.textAlignment = NSTextAlignmentCenter;
        _normalLabel.layer.cornerRadius = 10;
        _normalLabel.layer.masksToBounds = YES;
        _normalLabel.backgroundColor = RGBA(238,238,238,1);
        YXWeakSelf
        [_normalLabel addTapAction:^(UITapGestureRecognizer * _Nonnull sender) {
            weakSelf.rowData.noteType = YXWalletNoteTypeNormal;
            [weakSelf routerEventForName:kYXNodeSelectConfig paramater:weakSelf.rowData];
        }];
    }
    return _normalLabel;
}



- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kBgColor;
        [self setupUI];
        
    }
    return self;
}

- (void)setupUI{

    [self.contentView addSubview:self.desLabel];
    [self.contentView addSubview:self.dropsLabel];
    [self.contentView addSubview:self.normalLabel];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(13);
        make.width.mas_equalTo(52);
        make.left.mas_equalTo(15);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
    }];
    
    [self.dropsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(70);
        make.centerY.mas_equalTo(self.desLabel.mas_centerY);
        make.left.mas_equalTo(self.desLabel.mas_right).offset(10);
    }];
    
    [self.normalLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(70);
        make.centerY.mas_equalTo(self.desLabel.mas_centerY);
        make.left.mas_equalTo(self.dropsLabel.mas_right).offset(10);
    }];
}

-(void)setupCellWithRowData:(YXWalletMyWalletRecordsItem *)rowData{
    self.rowData = rowData;
    if (rowData.noteType == YXWalletNoteTypeConfig) {
        _dropsLabel.textColor = UIColor153;
        _dropsLabel.backgroundColor = RGBA(238,238,238,1);
        _normalLabel.textColor = UIColor153;
        _normalLabel.backgroundColor = RGBA(238,238,238,1);
    }else if (rowData.noteType == YXWalletNoteTypeNormal){
        _normalLabel.textColor = kWhiteColor;
        _normalLabel.backgroundColor = RGBA(255,160,0,1);
        _dropsLabel.textColor = UIColor153;
        _dropsLabel.backgroundColor = RGBA(238,238,238,1);
    }else if (rowData.noteType == YXWalletNoteTypeDrops){
        _normalLabel.textColor = UIColor153;
        _normalLabel.backgroundColor = RGBA(238,238,238,1);
        _dropsLabel.textColor = kWhiteColor;
        _dropsLabel.backgroundColor = RGBA(255,160,0,1);
    }
}

@end
