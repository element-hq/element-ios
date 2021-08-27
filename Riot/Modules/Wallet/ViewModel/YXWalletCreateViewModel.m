// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "YXWalletCreateViewModel.h"

@implementation YXWalletCreateViewModel
- (void)getWalletCreateHelpWord:(NSString *)walletName andCoinid:(NSString *)coinId complete:(nullable void (^)(NSDictionary *responseObject))complete{
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:walletName forKey:@"walletName"];
    [paramDict setObject:coinId forKey:@"coinId"];
    [NetWorkManager POST:kURL(@"/wallet/produce_mnemonic") parameters:paramDict success:^(id  _Nonnull responseObject) {
        if (complete) {
            complete(responseObject);
        }
    } failure:^(NSError * _Nonnull error) {
            
    }];
}

- (void)createWalletCreateHelpWord:(NSString *)mnemonic walletName:(NSString *)walletName andCoinid:(NSString *)coinId complete:(nullable void (^)(NSDictionary *responseObject))complete{
    
    [self createWalletCreateHelpWord:mnemonic walletName:walletName andCoinid:coinId import:NO complete:complete];
}

- (void)createWalletCreateHelpWord:(NSString *)mnemonic walletName:(NSString *)walletName andCoinid:(NSString *)coinId import:(BOOL)import complete:(nullable void (^)(NSDictionary *responseObject))complete{
    
    [MBProgressHUD showMessage:@"创建钱包中"];
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc]init];
    [paramDict setObject:walletName forKey:@"walletName"];
    [paramDict setObject:coinId forKey:@"coinId"];
    [paramDict setObject:mnemonic forKey:@"mnemonic"];
    [paramDict setObject:WalletManager.userId forKey:@"userId"];
    NSString *URLString = import ? kURL(@"/wallet/import_wallet") : kURL(@"/wallet/save_wallet");
    [NetWorkManager POST:URLString parameters:paramDict success:^(id  _Nonnull responseObject) {
        YXWalletNomalModel *model = [YXWalletNomalModel mj_objectWithKeyValues:responseObject];
        if (model.status.intValue == 200) {
            if (complete) {
                complete(responseObject);
            }
        }else{
            [MBProgressHUD showMessage:model.msg];
        }

        [MBProgressHUD hideHUD];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
        [MBProgressHUD showError:@"创建失败"];
    }];
    
}
@end
