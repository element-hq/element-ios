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

#import "RageShakableUIResponder.h"

#import "AppDelegate.h"

#import "MXCAlert.h"

#import "MatrixSDKHandler.h"

@interface RageShakableUIResponder() {
    MXCAlert *confirmationAlert;
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
        rageShakableUIResponder->startShakingTimeStamp = [[NSDate date] timeIntervalSince1970];
        
        rageShakableUIResponder->isShaking = YES;
        rageShakableUIResponder->ignoreShakeEnd = NO;
    }
}

+ (void)stopShaking:(UIResponder*)responder
{
    if (!sharedInstance) {
        sharedInstance = [[RageShakableUIResponder alloc] init];
    }
    
    NSLog(@"stopShaking with [%@]", [responder class]);
    
    RageShakableUIResponder* rageShakableUIResponder = [responder isKindOfClass:[RageShakableUIResponder class]] ? (RageShakableUIResponder*)responder : sharedInstance;
    
    if (rageShakableUIResponder && [AppDelegate theDelegate].isAppForeground && (([[NSDate date] timeIntervalSince1970] - rageShakableUIResponder->startShakingTimeStamp) > 1) && !rageShakableUIResponder->confirmationAlert) {
        if (!rageShakableUIResponder->ignoreShakeEnd) {
            rageShakableUIResponder->startShakingTimeStamp = [[NSDate date] timeIntervalSince1970];
            
            if ([responder isKindOfClass:[UIViewController class]]) {
                rageShakableUIResponder->confirmationAlert = [[MXCAlert alloc] initWithTitle:@"You seem to be shaking the phone in frustration. Would you like to submit a bug report?"  message:nil style:MXCAlertStyleAlert];
                
                [rageShakableUIResponder->confirmationAlert addActionWithTitle:@"Cancel" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                    sharedInstance->confirmationAlert = nil;
                }];
                    
                [rageShakableUIResponder->confirmationAlert addActionWithTitle:@"OK" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                    sharedInstance->confirmationAlert = nil;
                    [RageShakableUIResponder takeScreenshot:(UIViewController*)responder];
                }];

                [rageShakableUIResponder->confirmationAlert showInViewController:(UIViewController*)responder];
            }
        } else {
            [RageShakableUIResponder takeScreenshot:nil];
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

+ (void)applicationBecomesActive {
    [RageShakableUIResponder cancel:nil];
}

+ (void)takeScreenshot:(UIViewController*)controller {
    
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
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // the image is copied in the clipboard
    [UIPasteboard generalPasteboard].image = image;
    
    if (controller) {
        
        [controller.view snapshotViewAfterScreenUpdates:YES];
        
        sharedInstance->parentViewController = controller;
        sharedInstance->mailComposer = [[MFMailComposeViewController alloc] init];
        
        [sharedInstance->mailComposer setSubject:@"Matrix bug report"];
        [sharedInstance->mailComposer setToRecipients:[NSArray arrayWithObject:@"rageshake@matrix.org"]];
        
        NSString* appVersion = [AppDelegate theDelegate].appVersion;
        NSString* build = [AppDelegate theDelegate].build;
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        
        NSMutableString* message = [[NSMutableString alloc] init];
        
        [message appendFormat:@"Something went wrong on my Matrix client : \n\n\n"];
        
        [message appendFormat:@"-----> my comments <-----\n\n\n"];
        
        [message appendFormat:@"------------------------------\n"];
        [message appendFormat:@"Application info\n"];
        [message appendFormat:@"userId : %@\n", mxHandler.userId];
        [message appendFormat:@"displayname : %@\n", mxHandler.mxSession.myUser.displayname];
        [message appendFormat:@"\n"];
        [message appendFormat:@"homeServerURL : %@\n", mxHandler.homeServerURL];
        [message appendFormat:@"homeServer : %@\n", mxHandler.homeServer];
        [message appendFormat:@"\n"];
        [message appendFormat:@"matrixConsole version: %@\n", appVersion];
        [message appendFormat:@"SDK version: %@\n", MatrixSDKVersion];
        if (build.length) {
            [message appendFormat:@"Build: %@\n", build];
        }
        
        [sharedInstance->mailComposer setMessageBody:message isHTML:NO];
        [sharedInstance->mailComposer addAttachmentData:UIImageJPEGRepresentation(image, 1.0) mimeType:@"image/jpg" fileName:@"screenshot.jpg"];
        sharedInstance->mailComposer.mailComposeDelegate = sharedInstance;
        [controller presentViewController:sharedInstance->mailComposer animated:YES completion:nil];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate delegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:NO completion:nil];
}

@end
