//
//  YXWalletNoteListViewController.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/26.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletNoteListViewController.h"
#import "YXNodeListViewModel.h"
#import "YXWalletProxy.h"
#import "YXNodeDetailViewController.h"
#import "YXNodeConfigViewController.h"
@interface YXWalletNoteListViewController ()
@property (nonatomic , strong)UITableView *tableView;
@property (nonatomic , strong)YXNodeListViewModel *viewModel;
@property (nonatomic , strong)YXWalletProxy *proxy;
@property (nonatomic , strong)NSTimer *timer;
@end

@implementation YXWalletNoteListViewController

- (void)deleteTimer{
    [self.timer invalidate];
    self.timer = nil;
}

-(void)dealloc{
  
}

- (YXWalletProxy *)proxy{
    if (!_proxy) {
        _proxy = [[YXWalletProxy alloc]init];
    }
    return _proxy;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self reloadNewData];
    self.proxy.nodeListViewModel = self.viewModel;
    self.eventProxy = self.proxy;
    
    // 添加定时器
    [self seupTimer];
    
    [self addNoti];
}

- (void)seupTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:60 * 3 target:self selector:@selector(reloadNewData) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

-(void)addNoti{
    //进入后台
    YXWeakSelf
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationDidEnterBackgroundNotification
     object:nil queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification * _Nonnull note) {
         [weakSelf.timer setFireDate:[NSDate distantFuture]];
     }];
    
    //进入前台
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationWillEnterForegroundNotification
     object:nil queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification * _Nonnull note) {
         [weakSelf.timer setFireDate:[NSDate date]];
     }];
}


- (void)reloadNewData{
    [self.viewModel reloadNewData:self.model];
}



-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)setupUI{
    
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.right.bottom.top.offset(0);
    }];
   
}

-(YXNodeListViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXNodeListViewModel alloc]init];
        YXWeakSelf
        [_viewModel setRequestNodeSuccessBlock:^(YXNodeListModel * _Nonnull model) {
            weakSelf.tableView.dataSource = weakSelf.viewModel.dataSource;
            weakSelf.tableView.delegate = weakSelf.viewModel.delegate;
            [weakSelf.tableView reloadData];
            
            if (weakSelf.requestNodeSuccessBlock) {
                weakSelf.requestNodeSuccessBlock(model);
            }
        }];
        
        [_viewModel setTouchNodeListForDetailBlock:^(YXNodeListdata * _Nonnull model) {
            YXNodeDetailViewController *detailVc = [[YXNodeDetailViewController alloc]init];
            detailVc.nodeListModel = model;
            detailVc.nodeListModel.walletId = weakSelf.model.walletId;
            [weakSelf.navigationController pushViewController:detailVc animated:YES];
        }];
        
        [_viewModel setConfigNodeListForDetailBlock:^(YXNodeListdata * _Nonnull model) {
            YXNodeConfigViewController *configVc = [[YXNodeConfigViewController alloc]init];
            //配置成功需要刷新当前页面
            [configVc setReloadDataBlock:^{
                [weakSelf.viewModel reloadNewData:weakSelf.model];
            }];
            model.walletId = weakSelf.model.walletId;
            configVc.nodeListModel = model;
            [weakSelf.navigationController pushViewController:configVc animated:YES];
        }];

    }
    return _viewModel;
}


- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0) style:(UITableViewStylePlain)];
        _tableView.alwaysBounceVertical = YES;
        [_tableView setBackgroundColor:kBgColor];
        _tableView.estimatedRowHeight = 0.0f;
        _tableView.estimatedSectionHeaderHeight = 0.0f;
        _tableView.estimatedSectionFooterHeight = 0.0f;
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.separatorColor = [UIColor clearColor];
        _tableView.showsVerticalScrollIndicator = YES;
        if (@available(iOS 11.0, *)) {
               _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass(UITableViewCell.class)];

    }
    return _tableView;
}



@end
