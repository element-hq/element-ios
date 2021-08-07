//
//  YXWalletSettingPasswordView.h
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YXWalletSettingPasswordView : UIView
@property (nonatomic, copy) void (^touchBlock)(void);
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *des;
@property (nonatomic, copy) NSString *error;
@property (nonatomic, copy) NSString *nextText;
@property (nonatomic, assign) BOOL showError;
@end

NS_ASSUME_NONNULL_END
