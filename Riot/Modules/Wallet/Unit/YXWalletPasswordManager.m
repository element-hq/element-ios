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
#import <MatrixKit/MatrixKit.h>
#import "YXWalletPasswordManager.h"
#import "MXKTools.h"
@implementation YXWalletPasswordModel
@end

@implementation YXWalletPasswordManager
singleton_implementation(YXWalletPasswordManager)

-(BOOL)isHavePassword{
    if (self.model.status == 200) {
        return YES;
    }
    return NO;
}

-(NSString *)phomeNum{
    
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    
    if (account.linkedPhoneNumbers.count == 0) return @"";
    
    NSString *userPhomeNum = [MXKTools readableMSISDN:account.linkedPhoneNumbers.firstObject];
    return userPhomeNum;
}

-(NSString *)userId{
    NSString *phomeNum = self.phomeNum;
    if (phomeNum.length > 0) {
        //去除所有非数字的字符串
        NSCharacterSet *setToRemove = [[ NSCharacterSet characterSetWithCharactersInString:@"0123456789"]
                                               invertedSet ];
        NSArray *str2Array = [phomeNum componentsSeparatedByCharactersInSet:setToRemove];
        NSString *str2 = [NSString stringWithFormat:@"%@%@%@",str2Array[2],str2Array[3],str2Array[4]];
        phomeNum = str2;
    }
    return phomeNum;
}

-(void)setModel:(YXWalletPasswordModel *)model{
    _model = model;
}

@end
