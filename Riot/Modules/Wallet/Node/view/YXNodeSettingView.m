//
//  YXNodeSettingView.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXNodeSettingView.h"
#import "YXNodeSettingTableViewCell.h"
@interface YXNodeSettingView ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIView *topView;
@property (nonatomic , strong)UIView *headView;
@property (nonatomic , strong)UIButton *leftBarButtonItem;
@property (nonatomic , strong)UIButton *rightBarButtonItem;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UIView *lineView;
@property (nonatomic , strong)UILabel *selectLabel;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , assign)BOOL is_pledeg;//是否为质押交易
@end

@implementation YXNodeSettingView

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.alpha = 1;
        _bgView.layer.cornerRadius = 15;
        _bgView.clipsToBounds = YES;
        _bgView.backgroundColor = kWhiteColor;
    }
    return _bgView;
}

-(UIView *)topView{
    if (!_topView) {
        _topView = [[UIView alloc]init];
        _topView.backgroundColor = kClearColor;
        YXWeakSelf
        [_topView addTapAction:^(UITapGestureRecognizer *sender) {
            weakSelf.hidden = YES;
        }];
    }
    return _topView;
}


-(UIView *)headView{
    if (!_headView) {
        _headView = [[UIView alloc]init];
        _headView.alpha = 1;
    }
    return _headView;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"选择质押交易";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size: 16];
        _titleLabel.textColor = [UIColor colorWithRed:27/255.0 green:27/255.0 blue:27/255.0 alpha:1.0];
    }
    return _titleLabel;
}

-(UIButton *)leftBarButtonItem{
    if (!_leftBarButtonItem) {
        _leftBarButtonItem = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftBarButtonItem setTitle:@"取消" forState:UIControlStateNormal];
        [_leftBarButtonItem addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        _leftBarButtonItem.titleLabel.font = [UIFont systemFontOfSize:16];
        _leftBarButtonItem.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_leftBarButtonItem setTitleColor:UIColor170 forState:UIControlStateNormal];
    }
    return _leftBarButtonItem;
}

- (void)backAction{
    self.hidden = YES;
}

-(UIButton *)rightBarButtonItem{
    if (!_rightBarButtonItem) {
        _rightBarButtonItem = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightBarButtonItem setTitle:@"刷新" forState:UIControlStateNormal];
        [_rightBarButtonItem addTarget:self action:@selector(moreAction) forControlEvents:UIControlEventTouchUpInside];
        _rightBarButtonItem.titleLabel.font = [UIFont systemFontOfSize:16];
        _rightBarButtonItem.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_rightBarButtonItem setTitleColor:RGBA(255,160,0,1) forState:UIControlStateNormal];
    }
    return _rightBarButtonItem;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = UIColor221;
    }
    return _lineView;
}


- (void)moreAction{
    if (self.moreBlock) {
        self.moreBlock();
    }
}

-(UILabel *)selectLabel{
    if (!_selectLabel) {
        _selectLabel = [[UILabel alloc]init];
        _selectLabel.numberOfLines = 0;
        _selectLabel.text = @"选择";
        _selectLabel.font = [UIFont fontWithName:@"PingFang SC" size: 16];
        _selectLabel.backgroundColor = WalletColor;
        _selectLabel.textColor = kWhiteColor;
        _selectLabel.textAlignment = NSTextAlignmentCenter;
        [_selectLabel mm_addTapGestureWithTarget:self action:@selector(selectLabelAction)];
    }
    return _selectLabel;
}

- (void)selectLabelAction{
    
}


- (UITableView *)tableView
{
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] init];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.bounces = NO;
        tableView.allowsSelection = YES;
        [tableView registerClass:[YXNodeSettingTableViewCell class] forCellReuseIdentifier:NSStringFromClass(YXNodeSettingTableViewCell.class)];
        
        tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
        [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        _tableView = tableView;
    }
    return _tableView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = RGBA(0, 0, 0, 0.3);
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    [self addSubview:self.bgView];
    [self addSubview:self.topView];
    [self.bgView addSubview:self.headView];
    [self.bgView addSubview:self.tableView];
    [self.bgView addSubview:self.selectLabel];
    [self.headView addSubview:self.titleLabel];
    [self.headView addSubview:self.leftBarButtonItem];
    [self.headView addSubview:self.rightBarButtonItem];
    [self.headView addSubview:self.lineView];

    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.offset(0);
        make.height.mas_equalTo(SCREEN_HEIGHT/2);
    }];
    
    [self.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.offset(0);
        make.bottom.mas_equalTo(self.bgView.mas_top);
    }];
    
    [self.headView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.offset(0);
        make.height.mas_equalTo(67);
    }];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(18);
        make.centerX.mas_equalTo(self.mas_centerX);
        make.top.mas_equalTo(22);
    }];
     
    [self.leftBarButtonItem mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(18);
        make.width.mas_equalTo(40);
        make.left.mas_equalTo(21);
        make.top.mas_equalTo(22);
    }];
    
    [self.rightBarButtonItem mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(18);
        make.width.mas_equalTo(40);
        make.right.mas_equalTo(-21);
        make.top.mas_equalTo(22);
    }];
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
        make.right.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [self.selectLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(50);
        make.right.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(67);
        make.right.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.bottom.mas_equalTo(-50);
    }];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.is_pledeg) {
        return self.pledegModel.data.count;
    }
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.is_pledeg) {
        return 54;
    }
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YXNodeSettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(YXNodeSettingTableViewCell.class) forIndexPath:indexPath];
    if (self.is_pledeg) {
        cell.model = self.pledegModel.data[indexPath.row];
    }else{
        cell.nodeInfoModel = _nodeInfoModel;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.is_pledeg) {
        YXNodeConfigDataItem *model = self.pledegModel.data[indexPath.row];
        if (self.selectTXblock) {
            self.selectTXblock(model);
        }
    }else{
        if (self.selectNodeInfoblock) {
            self.selectNodeInfoblock(_nodeInfoModel);
        }
    }
    
    self.hidden = YES;
}


-(void)setPledegModel:(YXNodeConfigModelPledeg *)pledegModel{
    _pledegModel = pledegModel;
    _titleLabel.text = @"选择质押交易";
    self.is_pledeg = YES;
    self.rightBarButtonItem.hidden = NO;
    [self.tableView reloadData];
}

-(void)setNodeInfoModel:(YXNodeListdata *)nodeInfoModel{
    _nodeInfoModel = nodeInfoModel;
    _titleLabel.text = @"选择主节点";
    self.is_pledeg = NO;
    self.rightBarButtonItem.hidden = YES;
    [self.tableView reloadData];
}


@end
