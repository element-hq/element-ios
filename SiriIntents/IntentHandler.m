/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "IntentHandler.h"

#import "GeneratedInterface-Swift.h"
#import "MXKAccountManager.h"
#import "ContactResolver.h"
#import "StartAudioCallIntentHandler.h"
#import "StartVideoCallIntentHandler.h"
#import "SendMessageIntentHandler.h"

#if __has_include(<MatrixSDK/MXJingleCallStack.h>)
#define CALL_STACK_JINGLE
#endif

@interface IntentHandler ()

// Build Settings
@property (nonatomic) id<Configurable> configuration;

@property (nonatomic) id<INStartAudioCallIntentHandling> startAudioCallIntentHandler;
@property (nonatomic) id<INStartVideoCallIntentHandling> startVideoCallIntentHandler;
@property (nonatomic) id<INSendMessageIntentHandling> sendMessageIntentHandler;

@end

@implementation IntentHandler

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Set static application settings
        _configuration = [CommonConfiguration new];
        [_configuration setupSettings];

        // NSLog -> console.log file when not debugging the app
        MXLogConfiguration *configuration = [[MXLogConfiguration alloc] init];
        configuration.logLevel = MXLogLevelVerbose;
        configuration.logFilesSizeLimit = 0;
        configuration.maxLogFilesCount = 10;
        configuration.subLogName = @"siri";
        
        // Redirect NSLogs to files only if we are not debugging
        if (!isatty(STDERR_FILENO)) {
            configuration.redirectLogsToFiles = YES;
        }
        
        [MXLog configure:configuration];
        
        // Configure our analytics. It will start if the option is enabled
        Analytics *analytics = Analytics.shared;
        [MXSDKOptions sharedInstance].analyticsDelegate = analytics;
        [analytics startIfEnabled];
        
        id<ContactResolving> contactResolver = [[ContactResolver alloc] init];
        _startAudioCallIntentHandler = [[StartAudioCallIntentHandler alloc] initWithContactResolver:contactResolver];
        _startVideoCallIntentHandler = [[StartVideoCallIntentHandler alloc] initWithContactResolver:contactResolver];
        _sendMessageIntentHandler = [[SendMessageIntentHandler alloc] initWithContactResolver:contactResolver];
    }
    return self;
}

- (id)handlerForIntent:(INIntent *)intent
{
    if ([intent isKindOfClass:[INStartAudioCallIntent class]]) {
        return self.startAudioCallIntentHandler;
    } else if ([intent isKindOfClass:[INStartVideoCallIntent class]]) {
        return self.startVideoCallIntentHandler;
    } else if ([intent isKindOfClass:[INSendMessageIntent class]]) {
        return self.sendMessageIntentHandler;
    }
    
    return nil;
}

@end
