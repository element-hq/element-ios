/*
 Copyright 2017 Aram Sargsyan
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ShareExtensionRootViewController.h"
#import "ShareViewController.h"
#import "ShareExtensionManager.h"
#import "ThemeService.h"

#ifdef IS_SHARE_EXTENSION
#import "RiotShareExtension-Swift.h"
#else
#import "Riot-Swift.h"
#endif

@interface ShareExtensionRootViewController ()

@property (nonatomic, strong, readonly) ShareExtensionManager *shareExtensionManager;

@end

@implementation ShareExtensionRootViewController

- (instancetype)init
{
    if(self = [super init]) {
        
        [ThemeService.shared setThemeId:RiotSettings.shared.userInterfaceTheme];
        
        _shareExtensionManager = [[ShareExtensionManager alloc] initWithShareExtensionContext:self.extensionContext
                                                                               extensionItems:self.extensionContext.inputItems];
        
        MXWeakify(self);
        [_shareExtensionManager setCompletionCallback:^(ShareExtensionManagerResult result) {
            MXStrongifyAndReturnIfNil(self);
            
            switch (result)
            {
                case ShareExtensionManagerResultFinished:
                    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                    [self _dismiss];
                    break;
                case ShareExtensionManagerResultCancelled:
                    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXUserCancelErrorDomain" code:4201 userInfo:nil]];
                    [self _dismiss];
                    break;
                case ShareExtensionManagerResultFailed:
                    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXFailureErrorDomain" code:500 userInfo:nil]];
                    [self _dismiss];
                    break;
                default:
                    break;
            }
        }];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self presentViewController:self.shareExtensionManager.mainViewController animated:YES completion:nil];
}

#pragma mark - Private

- (void)_dismiss
{
    [self dismissViewControllerAnimated:true completion:^{
        [self.presentingViewController dismissViewControllerAnimated:false completion:nil];
        
//        // FIXME: Share extension memory usage increase when launched several times and then crash due to some memory leaks.
//        // For now, we force the share extension to exit and free memory.
//        [NSException raise:@"Kill the app extension" format:@"Free memory used by share extension"];
    }];
}

@end
