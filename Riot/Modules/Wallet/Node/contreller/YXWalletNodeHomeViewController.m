//
//  YXWalletNodeHomeViewController.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/27.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletNodeHomeViewController.h"
#import "YXWalletNoteListViewController.h"
#import "YXNodeListModel.h"
@interface YXWalletNodeHomeViewController ()
@property (nonatomic, strong) NSMutableArray *menuList;
@property (nonatomic, strong) YXWalletNoteListViewController *allNode;
@property (nonatomic, strong) YXWalletNoteListViewController *alreadylConfigure;
@property (nonatomic, strong) YXWalletNoteListViewController *willConfigure;
@property (nonatomic, strong) YXNaviView *naviView;
@property (nonatomic, copy) NSString *allTitle;
@property (nonatomic, copy) NSString *alreadylTitle;
@property (nonatomic, copy) NSString *willTitle;
@end

@implementation YXWalletNodeHomeViewController


-(void)dealloc{
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}


-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"我的节点";
        _naviView.titleColor = UIColor51;
        _naviView.backgroundColor = kClearColor;
        _naviView.leftImage = [UIImage imageNamed:@"back_b_black"];
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        
    }
    return _naviView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
}

#pragma mark - UI

- (void)initUI
{
    //背景
    self.view.backgroundColor = kBgColor;
    [self initMagicView];
    
}

- (void)initMagicView
{
    [self.magicView.navigationView addSubview:self.naviView];
    self.magicView.layoutStyle = VTLayoutStyleDivide;
    self.magicView.bounces = YES;
    self.magicView.contentView.panGestureRecognizer.enabled = NO;
    
    //隐藏头部栏
    self.magicView.headerHidden = YES;
    
    //设置菜单栏
    self.magicView.navigationColor = kBgColor;
    self.magicView.againstStatusBar = YES;
    self.magicView.navigationHeight = 74;//菜单距离状态栏的距离
    //由于不知道白天模式 分割线颜色 所有特殊处理一下
    self.magicView.separatorColor = kClearColor;
    
    //设置菜单项的间距
    self.magicView.itemSpacing = 35;
    
    self.magicView.navigationInset = UIEdgeInsetsMake(30, 0, 0, 0);
    //设置滑块
    self.magicView.sliderColor = WalletColor;
    self.magicView.sliderWidth = 30;
    self.magicView.sliderHeight = 1;
    
    //必须重新加载
    [self.magicView reloadData];
}

#pragma mark - VTMagicViewDataSource

- (NSArray<NSString *> *)menuTitlesForMagicView:(VTMagicView *)magicView {
    return self.menuList;
}

- (UIButton *)magicView:(VTMagicView *)magicView menuItemAtIndex:(NSUInteger)itemIndex {
    static NSString *itemIdentifier = @"itemIdentifier";
    UIButton *menuItem = [magicView dequeueReusableItemWithIdentifier:itemIdentifier];
    if (!menuItem) {
        menuItem = [UIButton buttonWithType:UIButtonTypeCustom];
        [menuItem setTitleColor:UIColor102 forState:UIControlStateNormal];
        [menuItem setTitleColor:WalletColor forState:UIControlStateSelected];
        menuItem.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:15.f];
    }
    
    return menuItem;
}

/**
 切换当前显示control
 
 @param magicView magicView description
 @param pageIndex 页面索引
 @return 对象
 */
- (UIViewController *)magicView:(VTMagicView *)magicView viewControllerAtPage:(NSUInteger)pageIndex
{
    UIViewController *vc = [UIViewController new];
    if (pageIndex < self.menuList.count) {
        if (pageIndex == 0) {
            vc = self.allNode;
        } else if (pageIndex == 1) {
            vc = self.alreadylConfigure;
        }else if (pageIndex == 2) {
            vc = self.willConfigure;
        }
    }
    return vc;
}

#pragma mark - Lazy

- (NSMutableArray *)menuList {
    if (!_menuList) {
        _menuList = [NSMutableArray array];
        _allTitle = @"全部(0)";
        _alreadylTitle = @"已配置(0)";
        _willTitle = @"待配置(0)";
        [_menuList addObject:self.allTitle];
        [_menuList addObject:self.alreadylTitle];
        [_menuList addObject:self.willTitle];
    }
    return _menuList;
}

-(YXWalletNoteListViewController *)allNode{
    if (!_allNode) {
        _allNode = [[YXWalletNoteListViewController alloc]init];
        _allNode.model = [self getConfigModel];;
        _allNode.model.noteType = YXWalletNoteTypeAll;
        YXWeakSelf
        [_allNode setRequestNodeSuccessBlock:^(YXNodeListModel * _Nonnull model) {
        
            weakSelf.allTitle = [NSString stringWithFormat:@"全部(%@)",@(model.data.count).stringValue];
     
        }];
    }
    return _allNode;
}

-(YXWalletNoteListViewController *)alreadylConfigure{
    if (!_alreadylConfigure) {
        _alreadylConfigure = [[YXWalletNoteListViewController alloc]init];
        _alreadylConfigure.model = [self getConfigModel];
        _alreadylConfigure.model.noteType = YXWalletNoteTypeConfig;
        YXWeakSelf
        [_alreadylConfigure setRequestNodeSuccessBlock:^(YXNodeListModel * _Nonnull model) {
            
            weakSelf.alreadylTitle = [NSString stringWithFormat:@"已配置(%@)",@(model.data.count).stringValue];
     
            
        }];
    }
    return _alreadylConfigure;
}


-(YXWalletNoteListViewController *)willConfigure{
    if (!_willConfigure) {
        _willConfigure = [[YXWalletNoteListViewController alloc]init];
        _willConfigure.model = [self getConfigModel];
        _willConfigure.model.noteType = YXWalletNoteTypeWillConfig;
        YXWeakSelf
        [_willConfigure setRequestNodeSuccessBlock:^(YXNodeListModel * _Nonnull model) {
            
            weakSelf.willTitle = [NSString stringWithFormat:@"待配置(%@)",@(model.data.count).stringValue];
     
            
        }];
    }
    return _willConfigure;
}

- (YXWalletMyWalletRecordsItem *)getConfigModel{
    NSDictionary *dic = self.model.mj_keyValues;
    YXWalletMyWalletRecordsItem *model = [YXWalletMyWalletRecordsItem mj_objectWithKeyValues:dic];
    return model;
}

-(void)setAllTitle:(NSString *)allTitle{
    _allTitle = allTitle;
    [self updatNaviTitle];
}

-(void)setAlreadylTitle:(NSString *)alreadylTitle{
    _alreadylTitle = alreadylTitle;
    [self updatNaviTitle];
}

-(void)setWillTitle:(NSString *)willTitle{
    _willTitle = willTitle;
    [self updatNaviTitle];
}

- (void)updatNaviTitle{
    [self.menuList removeAllObjects];
    [self.menuList addObject:self.allTitle];
    [self.menuList addObject:self.alreadylTitle];
    [self.menuList addObject:self.willTitle];
    [self.magicView reloadData];
}

@end
