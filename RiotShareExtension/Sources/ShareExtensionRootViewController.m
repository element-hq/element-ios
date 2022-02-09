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
#import "ShareManager.h"
#import "ThemeService.h"
#import "ShareItemSender.h"

#import "GeneratedInterface-Swift.h"

@interface ShareExtensionRootViewController ()

@property (nonatomic, strong, readonly) id<Configurable> configuration;

@property (nonatomic, strong, readonly) ShareManager *shareManager;

@end

@implementation ShareExtensionRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _configuration = [[CommonConfiguration alloc] init];
    [_configuration setupSettings];
    
    // NSLog -> console.log file when not debugging the app
    MXLogConfiguration *configuration = [[MXLogConfiguration alloc] init];
    configuration.logLevel = MXLogLevelVerbose;
    configuration.logFilesSizeLimit = 0;
    configuration.maxLogFilesCount = 10;
    configuration.subLogName = @"share";
    
    // Redirect NSLogs to files only if we are not debugging
    if (!isatty(STDERR_FILENO)) {
        configuration.redirectLogsToFiles = YES;
    }
    
    [MXLog configure:configuration];

    // Configure our analytics. It will start if the option is enabled
    Analytics *analytics = Analytics.shared;
    [MXSDKOptions sharedInstance].analyticsDelegate = analytics;
    [analytics startIfEnabled];
    
    [ThemeService.shared setThemeId:RiotSettings.shared.userInterfaceTheme];
    
    ShareExtensionShareItemProvider *shareItemProvider = [[ShareExtensionShareItemProvider alloc] initWithExtensionContext:self.extensionContext];
    ShareItemSender *shareItemSender = [[ShareItemSender alloc] initWithRootViewController:self
                                                                         shareItemProvider:shareItemProvider];
    
    _shareManager = [[ShareManager alloc] initWithShareItemSender:shareItemSender
                                                             type:ShareManagerTypeSend];
    
    MXWeakify(self);
    [_shareManager setCompletionCallback:^(ShareManagerResult result) {
        MXStrongifyAndReturnIfNil(self);
        
        switch (result)
        {
            case ShareManagerResultFinished:
                [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                [self dismiss];
                break;
            case ShareManagerResultCancelled:
                [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXUserCancelErrorDomain" code:4201 userInfo:nil]];
                [self dismiss];
                break;
            case ShareManagerResultFailed:
                [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXFailureErrorDomain" code:500 userInfo:nil]];
                [self dismiss];
                break;
            default:
                break;
        }
    }];
    
    [self.shareManager.mainViewController setModalInPopover:YES];
    [self presentViewController:self.shareManager.mainViewController animated:YES completion:nil];
}

#pragma mark - Private

- (void)dismiss
{
    [self dismissViewControllerAnimated:true completion:^{
        [self.presentingViewController dismissViewControllerAnimated:false completion:nil];
        
        // FIXME: Share extension memory usage increase when launched several times and then crash due to some memory leaks.
        // For now, we force the share extension to exit and free memory.
        [NSException raise:@"Kill the app extension" format:@"Free memory used by share extension"];
    }];
}

@end
