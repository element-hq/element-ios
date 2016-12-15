/*
 Copyright 2015 OpenMarket Ltd
 
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

#define RAGESHAKEMANAGER_MINIMUM_SHAKING_DURATION 2

#import "RageShakeManager.h"

#import "AppDelegate.h"

#import "GBDeviceInfo_iOS.h"

#import "NSBundle+MatrixKit.h"

static RageShakeManager* sharedInstance = nil;

@interface RageShakeManager() {
    bool isShaking;
    double startShakingTimeStamp;
    
    MXKAlert *confirmationAlert;
    
    MFMailComposeViewController* mailComposer;
}
@end

@implementation RageShakeManager

#pragma mark Singleton Method

+ (id)sharedManager {
    @synchronized(self) {
        if(sharedInstance == nil)
            sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

#pragma mark -

- (instancetype)init {
    
    self = [super init];
    if (self) {
        isShaking = NO;
        startShakingTimeStamp = 0;
        
        mailComposer = nil;
        confirmationAlert = nil;
    }
    
    return self;
}

- (void)promptCrashReportInViewController:(UIViewController*)viewController {
    if ([MXLogger crashLog] && [MFMailComposeViewController canSendMail]) {
        
        confirmationAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"bug_report_prompt", @"Vector", nil)  message:nil style:MXKAlertStyleAlert];
        
        __weak typeof(self) weakSelf = self;
        [confirmationAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            typeof(self) self = weakSelf;
            self->confirmationAlert = nil;
            
            // Erase the crash log (there is only chance for the user to send it)
            [MXLogger deleteCrashLog];
        }];
        
        [confirmationAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            typeof(self) self = weakSelf;
            self->confirmationAlert = nil;
            
            [self sendEmail:viewController withSnapshot:NO];
        }];
        
        [confirmationAlert showInViewController:viewController];
    }
}

#pragma mark - MXKResponderRageShaking

- (void)startShaking:(UIResponder*)responder {
    
    // Start only if the application is in foreground
    if ([AppDelegate theDelegate].isAppForeground && !confirmationAlert) {
        NSLog(@"[RageShakeManager] Start shaking with [%@]", [responder class]);
        
        startShakingTimeStamp = [[NSDate date] timeIntervalSince1970];
        isShaking = YES;
    }
}

- (void)stopShaking:(UIResponder*)responder {
    
    NSLog(@"[RageShakeManager] Stop shaking with [%@]", [responder class]);
    
    if (isShaking && [AppDelegate theDelegate].isAppForeground && !confirmationAlert
        && (([[NSDate date] timeIntervalSince1970] - startShakingTimeStamp) > RAGESHAKEMANAGER_MINIMUM_SHAKING_DURATION)) {
        
        if ([responder isKindOfClass:[UIViewController class]] && [MFMailComposeViewController canSendMail]) {
            confirmationAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"rage_shake_prompt", @"Vector", nil)  message:nil style:MXKAlertStyleAlert];
            
            __weak typeof(self) weakSelf = self;
            [confirmationAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                typeof(self) self = weakSelf;
                self->confirmationAlert = nil;
            }];
            
            [confirmationAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                typeof(self) self = weakSelf;
                self->confirmationAlert = nil;
                [self sendEmail:(UIViewController*)responder withSnapshot:YES];
            }];
            
            [confirmationAlert showInViewController:(UIViewController*)responder];
        }
    }
    
    isShaking = NO;
}

- (void)cancel:(UIResponder*)responder {
    
    isShaking = NO;
}

/**
 Prepare and send a report email. The mail composer is presented by the provided view controller.
 
 @param controller the view controller which presents the alert.
 @param snapshot if this boolean value is YES, a screenshot of `controller` is sent as email attachment
 */
- (void)sendEmail:(UIViewController*)controller withSnapshot:(BOOL)snapshot {

    UIImage *image;

    if (snapshot) {
        AppDelegate* theDelegate = [AppDelegate theDelegate];
        UIGraphicsBeginImageContextWithOptions(theDelegate.window.bounds.size, NO, [UIScreen mainScreen].scale);

        // Iterate over every window from back to front
        for (UIWindow *window in [[UIApplication sharedApplication] windows])
        {
            if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
            {
                // -renderInContext: renders in the coordinate space of the layer,
                // so we must first apply the layer's geometry to the graphics context
                CGContextSaveGState(UIGraphicsGetCurrentContext());
                // Center the context around the window's anchor point
                CGContextTranslateCTM(UIGraphicsGetCurrentContext(), [window center].x, [window center].y);
                // Apply the window's transform about the anchor point
                CGContextConcatCTM(UIGraphicsGetCurrentContext(), [window transform]);
                // Offset by the portion of the bounds left of and above the anchor point
                CGContextTranslateCTM(UIGraphicsGetCurrentContext(),
                                      -[window bounds].size.width * [[window layer] anchorPoint].x,
                                      -[window bounds].size.height * [[window layer] anchorPoint].y);

                // Render the layer hierarchy to the current context
                [[window layer] renderInContext:UIGraphicsGetCurrentContext()];

                // Restore the context
                CGContextRestoreGState(UIGraphicsGetCurrentContext());
            }
        }
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        // the image is copied in the clipboard
        [UIPasteboard generalPasteboard].image = image;
    }
    
    if (controller) {

        NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

        mailComposer = [[MFMailComposeViewController alloc] init];

        NSString* appVersion = [AppDelegate theDelegate].appVersion;
        NSString* build = [AppDelegate theDelegate].build;

        NSMutableString* subject;
        if ([MXLogger crashLog]) {
            subject = [NSMutableString stringWithFormat:@"[iOS] %@ crash report - %@", appDisplayName, appVersion];
        }
        else {
            subject = [NSMutableString stringWithFormat:@"[iOS] %@ bug report - %@", appDisplayName, appVersion];
        }

        // Add the build version to the subject if the app does not come from app store
        if (![build containsString:@"master"]) {
            [subject appendFormat:@" (%@)", build];
        }

        [mailComposer setSubject:subject];

        [mailComposer setToRecipients:[NSArray arrayWithObject:@"rageshake@riot.im"]];

        NSMutableString* message = [[NSMutableString alloc] init];
        
        [message appendFormat:@"Something went wrong on my Matrix client: \n\n\n"];
        
        [message appendFormat:@"-----> my comments <-----\n\n\n"];
        
        [message appendFormat:@"------------------------------\n"];
        [message appendFormat:@"Account info\n"];
        
        NSArray *mxAccounts = [MXKAccountManager sharedManager].accounts;
        for (MXKAccount* account in mxAccounts) {
            NSString *disabled = account.disabled ? @" (disabled)" : @"";
            
            [message appendFormat:@"user id: %@%@\n", account.mxCredentials.userId, disabled];
            if (account.mxSession.myUser.displayname)
            {
                [message appendFormat:@"displayname: %@\n", account.mxSession.myUser.displayname];
            }
            
            [message appendFormat:@"homeServerURL: %@\n", account.mxCredentials.homeServer];

            // e2e information
            [message appendFormat:@"e2e device id: %@\n", account.mxCredentials.deviceId];
       }
        
        [message appendFormat:@"------------------------------\n"];
        [message appendFormat:@"Application info\n"];
        [message appendString:appDisplayName];[message appendFormat:@" version: %@\n", appVersion];
        [message appendFormat:@"MatrixKit version: %@\n", MatrixKitVersion];
        [message appendFormat:@"MatrixSDK version: %@\n", MatrixSDKVersion];
        if (build.length) {
            [message appendFormat:@"Build: %@\n", build];
        }
        [message appendFormat:@"------------------------------\n"];
        [message appendFormat:@"Device info\n"];
        [message appendFormat:@"model: %@\n", [GBDeviceInfo deviceInfo].modelString];
        [message appendFormat:@"operatingSystem: %@ %@\n", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];

        [mailComposer setMessageBody:message isHTML:NO];

        // Attach image only if required
        if (image) {
            [mailComposer addAttachmentData:UIImageJPEGRepresentation(image, 1.0) mimeType:@"image/jpg" fileName:@"screenshot.jpg"];
        }

        // Add logs files
        NSMutableArray *logFiles = [NSMutableArray arrayWithArray:[MXLogger logFiles]];
        if ([MXLogger crashLog]) {
            [logFiles addObject:[MXLogger crashLog]];
        }
        for (NSString *logFile in logFiles) {
            NSData *logContent = [NSData dataWithContentsOfFile:logFile];
            [mailComposer addAttachmentData:logContent mimeType:@"text/plain" fileName:[logFile lastPathComponent]];
        }
        mailComposer.mailComposeDelegate = self;
        [controller presentViewController:mailComposer animated:YES completion:nil];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    // Do not send this crash anymore
    [MXLogger deleteCrashLog];
    
    [controller dismissViewControllerAnimated:NO completion:nil];
}

@end
