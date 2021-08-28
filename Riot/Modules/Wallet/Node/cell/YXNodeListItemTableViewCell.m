//
//  YXNodeListItemTableViewCell.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/27.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeListItemTableViewCell.h"
#import "YXNodeListModel.h"
extern NSString *const kYXConfigNodeListForDetail;
extern NSString *const kYXArmingFlagNodeListForDetail;
@interface YXNodeListItemTableViewCell ()
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *stateLabel;
@property (nonatomic , strong)UIImageView *bgImageView;
@property (nonatomic , strong)UIImageView *titleImageView;
@property (nonatomic , strong)UIView *configView;
@property (nonatomic , strong)UILabel *configLabel;
@property (nonatomic , strong)UIButton *configBtn;
@property (nonatomic , strong)UIButton *armingFlagBtn;
@property (nonatomic , strong)YXNodeListdata *rowData;
@end

@implementation YXNodeListItemTableViewCell

-(UIView *)configView{
    if (!_configView) {
        _configView = [[UIView alloc]init];
        _configView.backgroundColor = RGBA(0, 0, 0, 0.3);
        _configView.layer.cornerRadius = 8;
        _configView.layer.masksToBounds = YES;
        _configView.hidden = YES;
    }
    return _configView;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"192.168.1.68:9990";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _titleLabel.textColor = kWhiteColor;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
      
    }
    return _titleLabel;
}

-(UILabel *)configLabel{
    if (!_configLabel) {
        _configLabel = [[UILabel alloc]init];
        _configLabel.numberOfLines = 0;
        _configLabel.text = @"192.168.1.68:9990";
        _configLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _configLabel.textColor = kWhiteColor;
        _configLabel.textAlignment = NSTextAlignmentLeft;
      
    }
    return _configLabel;
}

-(UIButton *)configBtn{
    if (!_configBtn) {
        _configBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_configBtn addTarget:self action:@selector(configBtnAction) forControlEvents:UIControlEventTouchUpInside];
        [_configBtn setTitle:@"立刻配置" forState:UIControlStateNormal];
        _configBtn.titleLabel.textColor = UIColor.whiteColor;
        [_configBtn setBackgroundColor:RGBA(255,160,0,1)];
        _configBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_configBtn setTitleColor:kWhiteColor forState:UIControlStateNormal];
        _configBtn.layer.cornerRadius = 15;
        _configBtn.layer.masksToBounds = YES;
    }
    return _configBtn;
}

- (void)configBtnAction{
    [self routerEventForName:kYXConfigNodeListForDetail paramater:self.rowData];
}

-(UIButton *)armingFlagBtn{
    if (!_armingFlagBtn) {
        _armingFlagBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_armingFlagBtn addTarget:self action:@selector(armingFlagBtnAction) forControlEvents:UIControlEventTouchUpInside];
        [_armingFlagBtn setTitle:@"解冻质押" forState:UIControlStateNormal];
        _armingFlagBtn.titleLabel.textColor = UIColor.whiteColor;
        [_armingFlagBtn setBackgroundColor:RGBA(255,160,0,1)];
        _armingFlagBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        [_armingFlagBtn setTitleColor:kWhiteColor forState:UIControlStateNormal];
        _armingFlagBtn.layer.cornerRadius = 15;
        _armingFlagBtn.layer.masksToBounds = YES;
        _armingFlagBtn.userInteractionEnabled = YES;
    }
    return _armingFlagBtn;
}

- (void)armingFlagBtnAction{
    [self routerEventForName:kYXArmingFlagNodeListForDetail paramater:self.rowData];
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"节点状态";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 13];
        _desLabel.textColor = kWhiteColor;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

-(UILabel *)stateLabel{
    if (!_stateLabel) {
        _stateLabel = [[UILabel alloc]init];
        _stateLabel.numberOfLines = 0;
        _stateLabel.text = @"正常运行";
        _stateLabel.font = [UIFont fontWithName:@"PingFang SC" size: 13];
        _stateLabel.textColor = kWhiteColor;
        _stateLabel.textAlignment = NSTextAlignmentCenter;
        _stateLabel.layer.cornerRadius = 10;
        _stateLabel.layer.masksToBounds = YES;
        _stateLabel.backgroundColor = RGBA(0,255,0,0.4);
    }
    return _stateLabel;
}

- (UIImageView *)bgImageView{
    if (!_bgImageView){
        _bgImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"new_note_bg"]];
        _bgImageView.contentMode = UIViewContentModeScaleToFill;
        _bgImageView.clipsToBounds = YES;
    
    }
    return _bgImageView;
}

- (UIImageView *)titleImageView{
    if (!_titleImageView){
        _titleImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"node_light_icon"]];
        _titleImageView.contentMode = UIViewContentModeScaleToFill;
        _titleImageView.clipsToBounds = YES;
    
    }
    return _titleImageView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = kBgColor;
        [self setupUI];
        
    }
    return self;
}

- (void)setupUI{
    
    [self.contentView addSubview:self.bgImageView];
    [self.bgImageView addSubview:self.titleLabel];
    [self.bgImageView addSubview:self.desLabel];
    [self.bgImageView addSubview:self.stateLabel];
    [self.bgImageView addSubview:self.titleImageView];
    [self.contentView addSubview:self.armingFlagBtn];
    
    //立刻配置
    [self.contentView addSubview:self.configView];
    [self.configView addSubview:self.configLabel];
    [self.configView addSubview:self.configBtn];
    [self.configView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.offset(0);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
    }];
    
    [self.bgImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.offset(0);
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
    }];
    
    [self.titleImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.width.mas_equalTo(52);
        make.height.mas_equalTo(52);
        make.centerY.mas_equalTo(self.bgImageView.mas_centerY);
    }];
    
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(14);
        make.left.mas_equalTo(75);
        make.top.mas_equalTo(21);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(13);
        make.width.mas_equalTo(52);
        make.left.mas_equalTo(75);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(20);
    }];
    
    [self.stateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(70);
        make.centerY.mas_equalTo(self.desLabel.mas_centerY);
        make.left.mas_equalTo(self.desLabel.mas_right).offset(10);
    }];
    
    [self.configLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(12);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
        make.top.mas_equalTo(21);
    }];
    
    [self.configBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(100);
        make.centerX.mas_equalTo(self.contentView.mas_centerX);
        make.top.mas_equalTo(self.configLabel.mas_bottom).offset(17);
    }];
    
    [self.armingFlagBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(100);
        make.centerY.mas_equalTo(self.contentView.mas_centerY);
        make.right.mas_equalTo(self.contentView.mas_right).offset(-35);
    }];
    
    [self setupConfigView:NO];
}

- (void)setupConfigView:(BOOL)config{
    self.configView.hidden = config;
    self.titleLabel.hidden = !config;
    self.desLabel.hidden = !config;
    self.stateLabel.hidden = !config;

    if ([self.rowData.armingFlag isEqualToString:@"0"]) {
        self.armingFlagBtn.hidden = !config;
    }else{
        self.armingFlagBtn.hidden = YES;
    }
 
}

- (void)setupCellWithRowData:(YXNodeListdata *)rowData{
    self.rowData = rowData;
    [self setupConfigView:rowData.configuration];
    self.configLabel.text = rowData.ip;
    self.titleLabel.text = rowData.ip;
    
    if ([rowData.status isEqualToString:@"ENABLED"] || [rowData.status isEqualToString:@"PRE_ENABLED"]) {
        _stateLabel.text = @"正常运行";
        _stateLabel.backgroundColor = RGBA(0,255,0,0.4);
    }else{
        _stateLabel.text = @"节点掉线";
        _stateLabel.backgroundColor = RGBA(255,72,0,1);
    }
}


@end
