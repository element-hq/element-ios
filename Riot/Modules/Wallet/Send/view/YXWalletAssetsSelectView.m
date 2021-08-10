//
//  YXWalletAssetsSelectView.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/29.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAssetsSelectView.h"
#import "YXWalletSelectAssetsTableViewCell.h"

@interface YXWalletAssetsSelectView ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIView *topView;
@property (nonatomic , strong)UIView *bottomView;
@property (nonatomic , strong)UIView *headView;
@property (nonatomic , strong)UIButton *leftBarButtonItem;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UIView *lineView;
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , assign)NSInteger currentPage;
@end

@implementation YXWalletAssetsSelectView

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


-(UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc]init];
        _bottomView.backgroundColor = kWhiteColor;
    }
    return _bottomView;
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
        _titleLabel.text = @"选择资产种类";
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



- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = UIColor221;
        _lineView.hidden = YES;
    }
    return _lineView;
}

- (NSMutableArray<YXWalletMyWalletRecordsItem *> *)sectionItems
{
    if (!_sectionItems) {
        _sectionItems = [NSMutableArray array];
    }
    return _sectionItems;
}


- (UITableView *)tableView
{
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] init];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.bounces = YES;
        tableView.allowsSelection = YES;
        [tableView registerClass:[YXWalletSelectAssetsTableViewCell class] forCellReuseIdentifier:NSStringFromClass(YXWalletSelectAssetsTableViewCell.class)];
        tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
        [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        _tableView = tableView;
        _tableView.mj_header = [MJRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshHeaderAction)];
        _tableView.mj_footer = [MJRefreshBackFooter footerWithRefreshingTarget:self refreshingAction:@selector(refreshFooterAction)];

    }
    return _tableView;
}

- (void)refreshHeaderAction{
    self.currentPage = 1;
    [self.sectionItems removeAllObjects];
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:WalletManager.userId forKey:@"userId"];
    [paramDict setObject:@(self.currentPage).stringValue forKey:@"currpage"];
    [paramDict setObject:@"20" forKey:@"pagesize"];
    [NetWorkManager GET:kURL(@"/wallet/all_wallet") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletMyWalletModel *myWalletModel = [YXWalletMyWalletModel mj_objectWithKeyValues:responseObject];
            if (myWalletModel.status == 200) {
                [weakSelf.sectionItems addObjectsFromArray:myWalletModel.data.records];
                [weakSelf.tableView reloadData];
                
                if (weakSelf.requestAssetsSuccessBlock) {
                    weakSelf.requestAssetsSuccessBlock(myWalletModel.data.records.firstObject);
                }
            }
        }
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView.mj_footer endRefreshing];
     
    } failure:^(NSError * _Nonnull error) {
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView.mj_footer endRefreshing];

    }];
}

- (void)refreshFooterAction{
 
    self.currentPage += 1;
    YXWeakSelf
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:WalletManager.userId forKey:@"userId"];
    [paramDict setObject:@(self.currentPage).stringValue forKey:@"currpage"];
    [paramDict setObject:@"20" forKey:@"pagesize"];
    [NetWorkManager GET:kURL(@"/wallet/all_wallet") parameters:paramDict success:^(id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            YXWalletMyWalletModel *myWalletModel = [YXWalletMyWalletModel mj_objectWithKeyValues:responseObject];
            if (myWalletModel.status == 200) {
                [weakSelf.sectionItems addObjectsFromArray:myWalletModel.data.records];
                [weakSelf.tableView reloadData];
            }
        }
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView.mj_footer endRefreshing];
    } failure:^(NSError * _Nonnull error) {
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView.mj_footer endRefreshing];
    }];
    
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
    
    [self addSubview:self.bottomView];
    [self addSubview:self.bgView];
    [self addSubview:self.topView];
    [self.bgView addSubview:self.headView];
    [self.bgView addSubview:self.tableView];
    [self.headView addSubview:self.titleLabel];
    [self.headView addSubview:self.leftBarButtonItem];
    [self.headView addSubview:self.lineView];

    [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.offset(0);
        make.height.mas_equalTo(20);
    }];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.offset(0);
        make.height.mas_equalTo(SCREEN_HEIGHT - 169 - StatusSizeH);
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
    
    [self.lineView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1);
        make.right.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.headView.mas_bottom);
        make.right.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
    [self refreshHeaderAction];
    
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sectionItems.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YXWalletSelectAssetsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(YXWalletSelectAssetsTableViewCell.class) forIndexPath:indexPath];
    cell.model = self.sectionItems[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
        
    if (self.selectAssetsBlock) {
        self.selectAssetsBlock(self.sectionItems[indexPath.row]);
    }
}

@end
