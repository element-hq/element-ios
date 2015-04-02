/*
 Copyright 2014 OpenMarket Ltd
 
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

#define RAGESHAKABLEUIRESPONDER_MINIMUM_SHAKING_DURATION 2

#import "RageShakableUIResponder.h"

#import "AppDelegate.h"
#import "MatrixSDKHandler.h"

#import "GBDeviceInfo_iOS.h"

@interface RageShakableUIResponder() {
    MXKAlert *confirmationAlert;
    double startShakingTimeStamp;
    bool isShaking;
    bool ignoreShakeEnd;
    
    UIViewController* parentViewController;
    MFMailComposeViewController* mailComposer;
}
@end

@implementation RageShakableUIResponder

static RageShakableUIResponder* sharedInstance = nil;

- (id) init {
    self = [super init];
    
    if (self) {
        mailComposer = nil;
        confirmationAlert = nil;
        startShakingTimeStamp = 0;
        isShaking = NO;
        ignoreShakeEnd = NO;
    }
    
    return self;
}

+ (void)startShaking:(UIResponder*)responder {
    if (!sharedInstance) {
        sharedInstance = [[RageShakableUIResponder alloc] init];
    }
    
    RageShakableUIResponder* rageShakableUIResponder = [responder isKindOfClass:[RageShakableUIResponder class]] ? (RageShakableUIResponder*)responder : sharedInstance;
    
    // only start if the application is in foreground
    if ([AppDelegate theDelegate].isAppForeground && !rageShakableUIResponder->confirmationAlert) {
        NSLog(@"[RageShake] Start shaking with [%@]", [responder class]);
        
        rageShakableUIResponder->startShakingTimeStamp = [[NSDate date] timeIntervalSince1970];
        
        rageShakableUIResponder->isShaking = YES;
        rageShakableUIResponder->ignoreShakeEnd = NO;
    }
}

+ (void)stopShaking:(UIResponder*)responder {
    if (!sharedInstance) {
        sharedInstance = [[RageShakableUIResponder alloc] init];
    }
    
    NSLog(@"[RageShake] Stop shaking with [%@]", [responder class]);
    
    RageShakableUIResponder* rageShakableUIResponder = [responder isKindOfClass:[RageShakableUIResponder class]] ? (RageShakableUIResponder*)responder : sharedInstance;
    
    if (rageShakableUIResponder && [AppDelegate theDelegate].isAppForeground && (([[NSDate date] timeIntervalSince1970] - rageShakableUIResponder->startShakingTimeStamp) > RAGESHAKABLEUIRESPONDER_MINIMUM_SHAKING_DURATION) && !rageShakableUIResponder->confirmationAlert) {
        if (!rageShakableUIResponder->ignoreShakeEnd) {
            rageShakableUIResponder->startShakingTimeStamp = [[NSDate date] timeIntervalSince1970];
            
            if ([responder isKindOfClass:[UIViewController class]]) {
                rageShakableUIResponder->confirmationAlert = [[MXKAlert alloc] initWithTitle:@"You seem to be shaking the phone in frustration. Would you like to submit a bug report?"  message:nil style:MXKAlertStyleAlert];
                
                [rageShakableUIResponder->confirmationAlert addActionWithTitle:@"Cancel" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    sharedInstance->confirmationAlert = nil;
                }];
                    
                [rageShakableUIResponder->confirmationAlert addActionWithTitle:@"OK" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    sharedInstance->confirmationAlert = nil;
                    [RageShakableUIResponder sendEmail:(UIViewController*)responder withSnapshot:YES];
                }];

                [rageShakableUIResponder->confirmationAlert showInViewController:(UIViewController*)responder];
            }
        } else {
            [RageShakableUIResponder sendEmail:nil withSnapshot:NO];
        }
    }
    
    rageShakableUIResponder->isShaking = NO;
    rageShakableUIResponder->ignoreShakeEnd = NO;
}

+ (void)cancel:(UIResponder*)responder {
    
    if (!sharedInstance) {
        sharedInstance = [[RageShakableUIResponder alloc] init];
    }
    
    RageShakableUIResponder* rageShakableUIResponder = [responder isKindOfClass:[RageShakableUIResponder class]] ? (RageShakableUIResponder*)responder : sharedInstance;
    
    // Arathorn succeeded to shake the device and to put the application in background at the same time (magic finders)
    // it should prevent any screenshot alert in this crazy case
    rageShakableUIResponder->startShakingTimeStamp = [[NSDate date] timeIntervalSince1970];
    
    if (rageShakableUIResponder->isShaking) {
        rageShakableUIResponder->ignoreShakeEnd = YES;
    }
}

+ (void)reportCrash:(UIViewController*)viewController {
    if ([MXLogger crashLog]) {
        if (!sharedInstance) {
            sharedInstance = [[RageShakableUIResponder alloc] init];
        }

        sharedInstance->confirmationAlert = [[MXKAlert alloc] initWithTitle:@"The application has crashed last time. Would you like to submit a crash report?"  message:nil style:MXKAlertStyleAlert];

        [sharedInstance->confirmationAlert addActionWithTitle:@"Cancel" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            // Erase the crash log (there is only chance for the user to send it)
            [MXLogger deleteCrashLog];
            sharedInstance->confirmationAlert = nil;
        }];

        [sharedInstance->confirmationAlert addActionWithTitle:@"OK" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            sharedInstance->confirmationAlert = nil;
            [RageShakableUIResponder sendEmail:viewController withSnapshot:NO];
        }];

        [sharedInstance->confirmationAlert showInViewController:viewController];
    }
}

+ (void)applicationBecomesActive {
    [RageShakableUIResponder cancel:nil];
}

// Prepare and send a report email
// If `snapshot` is YES, a screenshot of `controller` will be sent as image attachment to the email
+ (void)sendEmail:(UIViewController*)controller withSnapshot:(BOOL)snapshot {

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
        [controller.view snapshotViewAfterScreenUpdates:YES];
        
        sharedInstance->parentViewController = controller;
        sharedInstance->mailComposer = [[MFMailComposeViewController alloc] init];

        if ([MXLogger crashLog]) {
            [sharedInstance->mailComposer setSubject:@"Matrix crash report"];
        }
        else {
            [sharedInstance->mailComposer setSubject:@"Matrix bug report"];
        }

        [sharedInstance->mailComposer setToRecipients:[NSArray arrayWithObject:@"rageshake@matrix.org"]];
        
        NSString* appVersion = [AppDelegate theDelegate].appVersion;
        NSString* build = [AppDelegate theDelegate].build;
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        
        NSMutableString* message = [[NSMutableString alloc] init];
        
        [message appendFormat:@"Something went wrong on my Matrix client: \n\n\n"];
        
        [message appendFormat:@"-----> my comments <-----\n\n\n"];
        
        [message appendFormat:@"------------------------------\n"];
        [message appendFormat:@"Application info\n"];
        [message appendFormat:@"userId: %@\n", mxHandler.userId];
        [message appendFormat:@"displayname: %@\n", mxHandler.mxSession.myUser.displayname];
        [message appendFormat:@"\n"];
        [message appendFormat:@"homeServerURL: %@\n", mxHandler.homeServerURL];
        [message appendFormat:@"homeServer: %@\n", mxHandler.homeServer];
        [message appendFormat:@"\n"];
        [message appendFormat:@"matrixConsole version: %@\n", appVersion];
        [message appendFormat:@"SDK version: %@\n", MatrixSDKVersion];
        if (build.length) {
            [message appendFormat:@"Build: %@\n", build];
        }
        [message appendFormat:@"------------------------------\n"];
        [message appendFormat:@"Device info\n"];
        [message appendFormat:@"model: %@\n", [GBDeviceInfo deviceDetails].modelString];
        [message appendFormat:@"operatingSystem: %@ %@\n", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
        
        [sharedInstance->mailComposer setMessageBody:message isHTML:NO];

        // Attach image only if required
        if (image) {
            [sharedInstance->mailComposer addAttachmentData:UIImageJPEGRepresentation(image, 1.0) mimeType:@"image/jpg" fileName:@"screenshot.jpg"];
        }

        // Add logs files
        NSMutableArray *logFiles = [NSMutableArray arrayWithArray:[MXLogger logFiles]];
        if ([MXLogger crashLog]) {
            [logFiles addObject:[MXLogger crashLog]];
        }
        for (NSString *logFile in logFiles) {
            NSData *logContent = [NSData dataWithContentsOfFile:logFile];
            [sharedInstance->mailComposer addAttachmentData:logContent mimeType:@"text/plain" fileName:[logFile lastPathComponent]];
        }
        sharedInstance->mailComposer.mailComposeDelegate = sharedInstance;
        [controller presentViewController:sharedInstance->mailComposer animated:YES completion:nil];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate delegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    // Do not send this crash anymore
    [MXLogger deleteCrashLog];
    [controller dismissViewControllerAnimated:NO completion:nil];
}

@end
