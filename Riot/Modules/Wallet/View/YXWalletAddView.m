//
//  YXWalletAddView.m
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletAddView.h"
#import "YXWalletAddCollectionViewCell.h"

@interface YXWalletAddView ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)UIView *topView;
@property (nonatomic , strong)UIView *bottomView;
@property (nonatomic , strong)UIView *headView;
@property (nonatomic , strong)UIButton *leftBarButtonItem;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UIView *lineView;
@property (nonatomic , strong)UICollectionView *addCollectionView;
@end

@implementation YXWalletAddView

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
        _titleLabel.text = @"新增资产";
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

- (UICollectionView *)addCollectionView{
    if (!_addCollectionView) {
        
        CGSize itemSize = CGSizeMake(SCREEN_WIDTH/3 - 10, 60);
        CGRect collectFrame = CGRectMake(0, 0, 0, itemSize.height);
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = itemSize;
        layout.minimumLineSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        layout.footerReferenceSize = CGSizeMake(0, 0);//隐藏表尾，宽高设置成0
        _addCollectionView = [[UICollectionView alloc]initWithFrame:collectFrame collectionViewLayout:layout];
        _addCollectionView.delegate=self;
        _addCollectionView.dataSource=self;
        _addCollectionView.showsVerticalScrollIndicator = NO;
        _addCollectionView.backgroundColor = [UIColor clearColor];
        [_addCollectionView registerClass:[YXWalletAddCollectionViewCell class] forCellWithReuseIdentifier:@"YXWalletAddCollectionViewCell"];
        [_addCollectionView setCollectionViewLayout:layout];
    }
    return _addCollectionView;
}

#pragma mark  设置CollectionView的组数
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

#pragma mark  设置CollectionView每组所包含的个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.coinModel.data.count;
}

#pragma mark  设置CollectionCell的内容
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    YXWalletAddCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YXWalletAddCollectionViewCell" forIndexPath:indexPath];
    cell.model = self.coinModel.data[indexPath.row];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.selectAddWalletItemBlock) {
        self.selectAddWalletItemBlock(self.coinModel.data[indexPath.row]);
    }
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
    [self.bgView addSubview:self.addCollectionView];
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
    
    [self.addCollectionView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.headView.mas_bottom);
        make.right.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.bottom.mas_equalTo(0);
    }];
    
}

-(void)setCoinModel:(YXWalletCoinModel *)coinModel{
    _coinModel = coinModel;
    [self.addCollectionView reloadData];
}


@end
