/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
