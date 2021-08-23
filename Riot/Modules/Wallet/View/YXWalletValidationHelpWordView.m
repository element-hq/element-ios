//
//  YXWalletValidationHelpWordView.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletValidationHelpWordView.h"
#import "TTTagView.h"
#import "YXWalletHelpWordCollectionViewCell.h"
 
@interface YXWalletValidationHelpWordView ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
@property (nonatomic , strong)UIView *bgView;
@property (nonatomic , strong)TTTagView *tagView;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UILabel *nextLabel;
@property (nonatomic , strong)UILabel *tipLabel;
@property (nonatomic , strong)UIView *wordView;
@property (nonatomic , strong)UICollectionView *addCollectionView;
@property (nonatomic , strong)NSMutableArray *crashArray;//缓存用于判断
@end

@implementation YXWalletValidationHelpWordView

-(NSMutableArray *)crashArray{
    if (!_crashArray) {
        _crashArray = [[NSMutableArray array]init];
    }
    return _crashArray;
}

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.layer.cornerRadius = 10;
        _bgView.clipsToBounds = YES;
        _bgView.backgroundColor = WalletColor;
    }
    return _bgView;
}

-(TTTagView *)tagView{
    if (!_tagView) {
        _tagView = [[TTTagView alloc] init];
        _tagView.numberOfLines = 3;
        _tagView.backgroundColor = kWhiteColor;
        _tagView.tagTextColor = UIColor51;
        _tagView.tagBackgroundColor = kWhiteColor;
        _tagView.tagBorderColor = kWhiteColor;
        _tagView.layer.cornerRadius = 10;
        _tagView.clipsToBounds = YES;
        _tagView.userInteractionEnabled = NO;
        _tagView.tagsArray = [NSArray new];
        YXWeakSelf
        [_tagView setSelectItemBlock:^(UIButton * _Nonnull sender) {
            [weakSelf.tagView removeTag:sender.titleLabel.text];
            [weakSelf.tagsArray addObject:sender.titleLabel.text];
            [weakSelf.addCollectionView reloadData];
        }];
    }
    return _tagView;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"请根据您记下的助记词，按顺序点击下面的单词，验证您备份的助记词无误。";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = kWhiteColor;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}

-(UIView *)wordView{
    if (!_wordView) {
        _wordView = [[UIView alloc]init];
    }
    return _wordView;
}

-(UILabel *)nextLabel{
    if (!_nextLabel) {
        _nextLabel = [[UILabel alloc]init];
        _nextLabel.numberOfLines = 0;
        _nextLabel.text = @"创建";
        _nextLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _nextLabel.backgroundColor = RGBA(255,160,0,0.3);
        _nextLabel.textColor = kWhiteColor;
        _nextLabel.textAlignment = NSTextAlignmentCenter;
        [_nextLabel mm_addTapGestureWithTarget:self action:@selector(nextLabelAction)];
        _nextLabel.layer.cornerRadius = 20;
        _nextLabel.layer.masksToBounds = YES;
    }
    return _nextLabel;
}

- (void)nextLabelAction{
    if (self.tagsArray.count != 0) return;
    self.addCollectionView.hidden = YES;
    
    //验证助记词是否正确
    if (self.nextBlock) {
        self.nextBlock([self.tagView.tagsArray mutableCopy]);
    }

}


-(UILabel *)tipLabel{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc]init];
        _tipLabel.numberOfLines = 0;
        _tipLabel.text = @"顺序或单词有误，请重新校对";
        _tipLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _tipLabel.backgroundColor = RGBA(255,60,0,1);
        _tipLabel.textColor = kWhiteColor;
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        [_tipLabel mm_addTapGestureWithTarget:self action:@selector(tipLabelAction)];
        _tipLabel.layer.cornerRadius = 20;
        _tipLabel.layer.masksToBounds = YES;
        _tipLabel.hidden = YES;
    }
    return _tipLabel;
}

- (void)tipLabelAction{
    if (self.backBlock) {
        self.backBlock();
    }
}


- (UICollectionView *)addCollectionView{
    if (!_addCollectionView) {
        
        CGSize itemSize = CGSizeMake((SCREEN_WIDTH - 32)/4, 26);
        CGRect collectFrame = CGRectMake(0, 0, 0, itemSize.height);
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = itemSize;
        layout.minimumLineSpacing = 6;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.sectionInset = UIEdgeInsetsMake(12, 16, 0, 16);
        layout.footerReferenceSize = CGSizeMake(0, 0);//隐藏表尾，宽高设置成0
        _addCollectionView = [[UICollectionView alloc]initWithFrame:collectFrame collectionViewLayout:layout];
        _addCollectionView.delegate=self;
        _addCollectionView.dataSource=self;
        _addCollectionView.showsVerticalScrollIndicator = NO;
        _addCollectionView.backgroundColor = [UIColor clearColor];
        [_addCollectionView registerClass:[YXWalletHelpWordCollectionViewCell class] forCellWithReuseIdentifier:@"YXWalletHelpWordCollectionViewCell"];
        [_addCollectionView setCollectionViewLayout:layout];
    }
    return _addCollectionView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;
        [self setupUI];

    }
    return self;
}

- (void)setupUI{
    [self addSubview:self.bgView];
    [self.bgView addSubview:self.tagView];
    [self.bgView addSubview:self.desLabel];
    [self addSubview:self.wordView];
    [self addSubview:self.nextLabel];
    [self addSubview:self.tipLabel];
    
    [self.wordView addSubview:self.addCollectionView];
    
    [self.bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.top.mas_equalTo(0);
        make.height.mas_equalTo(205);
    }];
    
    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(13);
        make.height.mas_equalTo(130);
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.tagView.mas_bottom).offset(6);
        make.height.mas_equalTo(40);
    }];
    
    [self.wordView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.top.mas_equalTo(self.bgView.mas_bottom).offset(0);
        make.height.mas_equalTo(150);
    }];
    
    [self.addCollectionView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    
    [self.nextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(40);
        make.left.mas_equalTo(23);
        make.right.mas_equalTo(-23);
    }];
    
    [self.tipLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-94);
        make.height.mas_equalTo(40);
        make.left.mas_equalTo(23);
        make.right.mas_equalTo(-23);
    }];
    
}

-(void)setTagsArray:(NSMutableArray *)tagsArray{
    _tagsArray = tagsArray;
    [self.crashArray removeAllObjects];
    [self.crashArray addObjectsFromArray:tagsArray];
    [self.addCollectionView reloadData];
    
}

#pragma mark  设置CollectionView的组数
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

#pragma mark  设置CollectionView每组所包含的个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.tagsArray.count;
}

#pragma mark  设置CollectionCell的内容
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    YXWalletHelpWordCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"YXWalletHelpWordCollectionViewCell" forIndexPath:indexPath];
    cell.title = self.tagsArray[indexPath.row];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self.tagView addTag:self.tagsArray[indexPath.row]];
    NSMutableArray *array = [NSMutableArray array];
    [array addObjectsFromArray:self.tagsArray];
    [self.tagsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (indexPath.row == idx) {
            [array removeObject:obj];
        }
    }];
    self.tagsArray = array;
    [self.addCollectionView reloadData];
    
    if (self.tagsArray.count == 0) {
        _nextLabel.backgroundColor = WalletColor;
    }else{
        _nextLabel.backgroundColor = RGBA(255,160,0,0.3);
    }

}

-(void)setShowTip:(BOOL)showTip{
    _showTip = shadow;
    self.tipLabel.hidden = showTip;
}

-(void)removeTagViewData{
    if (self.tagView.tagsArray.count > 0) {
        NSMutableArray *tagsArray = [NSMutableArray array];
        [tagsArray addObjectsFromArray:[self.tagView.tagsArray mutableCopy]];
            YXWeakSelf
            [tagsArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [weakSelf.tagView removeTag:obj];
            }];
        }
    }


@end

