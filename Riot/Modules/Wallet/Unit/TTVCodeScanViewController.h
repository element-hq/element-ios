//
//  TTVCodeScanViewController.h
//  TouchTV
//
//  Created by liaoshen on 2020/4/22.
//  Copyright © 2020 TouchTV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTVCodeScanViewController : UIViewController
@property (nonatomic , copy)void (^scanWalletAddrBlock)(NSString *walletAddr);
@end

NS_ASSUME_NONNULL_END
