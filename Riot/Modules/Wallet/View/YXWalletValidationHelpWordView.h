//
//  YXWalletValidationHelpWordView.h
//  lianliao
//
//  Created by 廖燊 on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YXWalletValidationHelpWordView : UIView
@property (nonatomic , copy)void (^nextBlock)(NSMutableArray *array);
@property (nonatomic , copy)void (^backBlock)(void);
@property (nonatomic , strong)NSMutableArray *tagsArray;
@property (nonatomic , assign)BOOL showTip;
-(void)removeTagViewData;
@end

NS_ASSUME_NONNULL_END
