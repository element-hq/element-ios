//
//  YXWalletHelpViewController.m
//  lianliao
//
//  Created by liaoshen on 2021/6/23.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXWalletHelpViewController.h"

@interface YXWalletHelpViewController ()
@property (nonatomic , strong)YXNaviView *naviView;
@end

@implementation YXWalletHelpViewController

-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"帮助反馈";
        _naviView.titleColor = UIColor51;
        _naviView.leftImage = [UIImage imageNamed:@"back_b_black"];
        _naviView.backgroundColor = UIColor.whiteColor;
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
 
    }
    return _naviView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.naviView];
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(16, 95, 343, 241);
    label.alpha = 1;
    label.numberOfLines = 0;
    [self.view addSubview:label];
    NSMutableAttributedString *string = [
      [NSMutableAttributedString alloc] initWithString:@"如果您在使用中遇到问题，可以通过以下方式与我们联系。\n\n感谢您的理解和支持\n\n联系电话：188-8888-8888\n\n电子邮箱：services@163.com\n\n官方网站：www.8852qkl.cn"
      attributes: @{
        NSFontAttributeName: [UIFont fontWithName:@"PingFang SC" size: 15],
        NSForegroundColorAttributeName: [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.00]
    }];
    
    label.attributedText = string;
    
}



@end
