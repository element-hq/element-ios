//
//  UIViewController+Alert.m
//  ZLAssetsPickerDemo
//
//  Created by zhanglei on 16/2/3.
//  Copyright © 2016年 com.zixue101.www. All rights reserved.
//

#import "UIViewController+Alert.h"

@implementation UIViewController (Alert)

- (void)showWaitingAnimationWithText:(NSString *)text{
    [self hideWaitingAnimation];
    [self showMessageWithText:text ?: @"加载中..."];
}

- (void)hideWaitingAnimation{
    UILabel *alertLabel = [[UIApplication sharedApplication].keyWindow viewWithTag:10001];
    [UIView animateWithDuration:1.0 animations:^{
        alertLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        [alertLabel removeFromSuperview];
    }];
}

- (void)showMessageWithText:(NSString *)text{
    UILabel *alertLabel = [[UILabel alloc] init];
    alertLabel.tag = 10001;
    alertLabel.font = [UIFont systemFontOfSize:15];
    alertLabel.text = text;
    alertLabel.textAlignment = NSTextAlignmentCenter;
    alertLabel.layer.masksToBounds = YES;
    alertLabel.textColor = [UIColor whiteColor];
    alertLabel.bounds = CGRectMake(0, 0, 100, 40);
    alertLabel.center = CGPointMake(self.view.frame.size.width * 0.5, self.view.frame.size.height * 0.5);
    alertLabel.backgroundColor = [UIColor colorWithRed:25/255.0 green:25/255.0 blue:25/255.0 alpha:0.8];
    alertLabel.layer.cornerRadius = 5.0f;
    [[UIApplication sharedApplication].keyWindow addSubview:alertLabel];
}


@end
