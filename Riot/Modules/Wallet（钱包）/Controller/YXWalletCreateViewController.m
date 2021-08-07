//
//  YXWalletCreateViewController.m
//  lianliao
//
//  Created by 廖燊 on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletCreateViewController.h"
#import "YXWalletCreateWorldView.h"
#import "YXWalletInputWorldView.h"
#import "YXWalletValidationHelpWordView.h"
#import "YXWalletCreateViewModel.h"
#import "YXWalletPopupView.h"
@interface YXWalletCreateViewController ()<UITextFieldDelegate>
@property (nonatomic , strong)YXNaviView *naviView;
@property (nonatomic , strong)UILabel *titleLabel;
@property (nonatomic , strong)UILabel *desLabel;
@property (nonatomic , strong)UIView *nameView;
@property (nonatomic , strong)UILabel *nameLabel;
@property (nonatomic , strong)UITextField *textField;
@property (nonatomic , strong)UILabel *nextLabel;
@property (nonatomic , strong)YXWalletCreateWorldView *createWorldView;
@property (nonatomic , strong)YXWalletInputWorldView *inputWorldView;
@property (nonatomic , strong)YXWalletValidationHelpWordView *helpWordView;
@property (nonatomic , strong)YXWalletCreateViewModel *viewModel;
@property (nonatomic , strong)YXWalletHelpWordModel *helpWordModel;
@property (nonatomic , strong)YXWalletPopupView *walletPopupView;
@end

@implementation YXWalletCreateViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    if (!self.walletPopupView.superview) {
        [UIApplication.sharedApplication.keyWindow addSubview:self.walletPopupView];
    }
}

-(YXWalletPopupView *)walletPopupView{
    if (!_walletPopupView) {
        _walletPopupView = [[YXWalletPopupView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) type:WalletPopupViewCJCGType];
        YXWeakSelf
        _walletPopupView.cancelBlock = ^{
            weakSelf.walletPopupView.hidden = YES;
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
        _walletPopupView.hidden = YES;
    }
    return _walletPopupView;
}


-(YXWalletCreateViewModel *)viewModel{
    if (!_viewModel) {
        _viewModel = [[YXWalletCreateViewModel alloc]init];
    }
    return _viewModel;
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"添加钱包";
        _titleLabel.font = [UIFont boldSystemFontOfSize: 20];
        _titleLabel.textColor = WalletColor;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

-(UILabel *)desLabel{
    if (!_desLabel) {
        _desLabel = [[UILabel alloc]init];
        _desLabel.numberOfLines = 0;
        _desLabel.text = @"钱包是存储数字资产的工具，更是一个生态的流量入口。随着生态中token经济生态的完善，使用场景会越来越多。";
        _desLabel.font = [UIFont fontWithName:@"PingFang SC" size: 12];
        _desLabel.textColor = UIColor153;
        _desLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _desLabel;
}


-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.leftImage = [UIImage imageNamed:@"back_b_black"];
        _naviView.backgroundColor = UIColor.whiteColor;
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
 
    }
    return _naviView;
}

-(UILabel *)nameLabel{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.numberOfLines = 0;
        _nameLabel.text = @"设置钱包名称";
        _nameLabel.font = [UIFont fontWithName:@"PingFang SC" size: 20];
        _nameLabel.textColor = kWhiteColor;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _nameLabel;
}

-(UIView *)nameView{
    if (!_nameView) {
        _nameView = [[UIView alloc]init];
        _nameView.layer.cornerRadius = 10;
        _nameView.layer.masksToBounds = YES;
        _nameView.backgroundColor = WalletColor;
    }
    return _nameView;
}

-(UITextField *)textField{
    if (!_textField) {
        _textField = [[UITextField alloc]init];
        _textField.textAlignment = NSTextAlignmentLeft;
        _textField.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _textField.textColor = UIColor51;
        _textField.textAlignment = NSTextAlignmentCenter;
        _textField.delegate = self;
        _textField.placeholder = @"";
        _textField.layer.cornerRadius = 20;
        _textField.layer.masksToBounds = YES;
        _textField.backgroundColor = kWhiteColor;
    }
    return _textField;
}

-(UILabel *)nextLabel{
    if (!_nextLabel) {
        _nextLabel = [[UILabel alloc]init];
        _nextLabel.numberOfLines = 0;
        _nextLabel.text = @"下一步";
        _nextLabel.font = [UIFont fontWithName:@"PingFang SC" size: 15];
        _nextLabel.backgroundColor = kWhiteColor;
        _nextLabel.textColor = WalletColor;
        _nextLabel.textAlignment = NSTextAlignmentCenter;
        [_nextLabel mm_addTapGestureWithTarget:self action:@selector(nextLabelAction)];
        _nextLabel.layer.cornerRadius = 20;
        _nextLabel.layer.masksToBounds = YES;
    }
    return _nextLabel;
}

- (void)nextLabelAction{
    if (self.textField.text.length > 0) {

        if (self.isCreate) {
            YXWeakSelf
            [self.viewModel getWalletCreateHelpWord:self.textField.text andCoinid:self.coinModel.ID complete:^(NSDictionary * _Nonnull responseObject) {
                YXWalletHelpWordModel *helpWordModel = [YXWalletHelpWordModel mj_objectWithKeyValues:responseObject];
                weakSelf.helpWordModel = helpWordModel;
                [weakSelf createHelpWordSuccess:helpWordModel.data];
            }];
        }else{
            //导入钱包
            self.inputWorldView.hidden = NO;
            self.nameLabel.text = @"导入钱包助记词";
            self.desLabel.text = @"请将12位助记词填入下面的输入框，并用空格隔开。";
        }

    }
}

- (void)createHelpWordSuccess:(NSArray *)tagArray{
    self.nameLabel.text = @"生成助记词";
    self.desLabel.text = @"请记录好生成的助记词，下一页将会验证助记词的合法性。";
    self.nameView.hidden = YES;
    self.createWorldView.hidden = NO;
    self.createWorldView.tagsArray = tagArray;
    [self.textField resignFirstResponder];
}

-(YXWalletCreateWorldView *)createWorldView{
    if (!_createWorldView) {
        _createWorldView = [[YXWalletCreateWorldView alloc]init];
        _createWorldView.tagsArray = @[];
        _createWorldView.hidden = YES;
        YXWeakSelf
        [_createWorldView setNextBlock:^{
            weakSelf.nameLabel.text = @"验证助记词";
            weakSelf.desLabel.text = @"请记录好生成的助记词，下一页将会验证助记词的合法性。";
            weakSelf.createWorldView.hidden = YES;
            weakSelf.helpWordView.hidden = NO;
            weakSelf.helpWordView.tagsArray = [[weakSelf mub_randomArray:weakSelf.helpWordModel.data] mutableCopy];
            
        }];
    }
    return _createWorldView;
}

-(YXWalletInputWorldView *)inputWorldView{
    if (!_inputWorldView) {
        _inputWorldView = [[YXWalletInputWorldView alloc]init];

        _inputWorldView.hidden = YES;
        YXWeakSelf
        [_inputWorldView setNextBlock:^{
            if (weakSelf.inputWorldView.helpWorld.length > 0) {
                [weakSelf creatWalletWith:weakSelf.inputWorldView.helpWorld];
            }
        }];
    }
    return _inputWorldView;
}


-(YXWalletValidationHelpWordView *)helpWordView{
    if (!_helpWordView) {
        _helpWordView = [[YXWalletValidationHelpWordView alloc]init];
        _helpWordView.hidden = YES;
        YXWeakSelf
        [_helpWordView setNextBlock:^(NSMutableArray * _Nonnull array) {
           BOOL isEqual = [weakSelf array:weakSelf.helpWordModel.data isEqualTo:array];
            weakSelf.helpWordView.showTip = isEqual;
            if (isEqual) {//助记词正确创建钱包
                NSString *helpWord = [array componentsJoinedByString:@" "];
                [weakSelf creatWalletWith:helpWord];
            }
        }];
    }
    return _helpWordView;
}

- (void)creatWalletWith:(NSString *)helpWord{
    YXWeakSelf
    [self.viewModel createWalletCreateHelpWord:helpWord walletName:self.textField.text andCoinid:self.coinModel.ID complete:^(NSDictionary * _Nonnull responseObject) {
        YXWalletCreateModel *createModel = [YXWalletCreateModel mj_objectWithKeyValues:responseObject];
        if (createModel.status == 200) {
            //创建成功
            weakSelf.walletPopupView.hidden = NO;
        }
    }];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    if (!self.isCreate) {//导入钱包
        self.titleLabel.text = @"导入钱包";
    }
}

- (void)setupUI{
    self.view.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.naviView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.desLabel];
    
    [self.view addSubview:self.nameView];
    [self.view addSubview:self.createWorldView];
    [self.view addSubview:self.inputWorldView];
    [self.view addSubview:self.helpWordView];
    
    [self.nameView addSubview:self.nameLabel];
    [self.nameView addSubview:self.textField];
    [self.nameView addSubview:self.nextLabel];
    
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.naviView.mas_bottom).offset(15);
        make.left.mas_equalTo(15);
        make.height.mas_equalTo(20);
    }];
    
    [self.desLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(14);
        make.height.mas_equalTo(32);
    }];
    
    [self.nameView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(35);
        make.height.mas_equalTo(250);
    }];
    
    [self.nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(45);
        make.height.mas_equalTo(20);
        make.centerX.mas_equalTo(self.nameView.mas_centerX);
    }];
    
    [self.textField mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.nameLabel.mas_bottom).offset(15);
        make.height.mas_equalTo(40);
        make.left.mas_equalTo(23);
        make.right.mas_equalTo(-23);
    }];
    
    [self.nextLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.textField.mas_bottom).offset(45);
        make.height.mas_equalTo(40);
        make.left.mas_equalTo(23);
        make.right.mas_equalTo(-23);
    }];
    
    
    [self.createWorldView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(35);
        make.height.mas_equalTo(315);
    }];
    
    [self.inputWorldView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(35);
        make.height.mas_equalTo(315);
    }];
    
    [self.helpWordView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.right.mas_equalTo(-15);
        make.top.mas_equalTo(self.desLabel.mas_bottom).offset(35);
        make.height.mas_equalTo(395);
    }];
}

///判断两个数组是否相等，包含内容和顺序
- (BOOL)array:(NSArray *)array1 isEqualTo:(NSArray *)array2 {
    if (array1.count != array2.count) {
        return NO;
    }
    
    for (int i = 0 ; i < array1.count ; i++) {
        NSString *obj1 = array1[i];
        NSString *obj2 = array2[i];
        if (![obj1 isEqualToString:obj2]) {
            return NO;
        }
    }
    return YES;
}

/*
 *  @brief 将数组随机打乱
 */
- (NSArray *)mub_randomArray:(NSArray *)array {
    // 转为可变数组
    NSMutableArray * tmp = array.mutableCopy;
    // 获取数组长度
    NSInteger count = tmp.count;
    // 开始循环
    while (count > 0) {
        // 获取随机角标
        NSInteger index = arc4random_uniform((int)(count - 1));
        // 获取角标对应的值
        id value = tmp[index];
        // 交换数组元素位置
        tmp[index] = tmp[count - 1];
        tmp[count - 1] = value;
        count--;
    }
    // 返回打乱顺序之后的数组
    return tmp.copy;
}

@end
