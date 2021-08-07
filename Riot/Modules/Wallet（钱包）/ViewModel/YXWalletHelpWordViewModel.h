//
//  YXWalletHelpWordViewModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/24.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import "YXBaseViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YXWalletHelpWordViewModel : YXBaseViewModel
@property (nonatomic , copy)dispatch_block_t reloadData;
@property (nonatomic , copy)NSString *helpWord;
- (void)reloadNewData:(NSArray *)wordArray;
- (void)walletCopyHelpWord;
- (void)closeTipView:(UITableViewCell *)cell;
@end

NS_ASSUME_NONNULL_END
