//
//  UIViewController+Alert.h
//  ZLAssetsPickerDemo
//
//  Created by zhanglei on 16/2/3.
//  Copyright © 2016年 com.zixue101.www. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Alert)
- (void)showWaitingAnimationWithText:(NSString *)text;
- (void)hideWaitingAnimation;
@end
