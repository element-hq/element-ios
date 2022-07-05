/*
 Copyright 2017 Vector Creations Ltd
 
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
