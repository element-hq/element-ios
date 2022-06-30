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

#if __has_include(<MatrixSDK/MXJingleCallStack.h>)
#define CALL_STACK_JINGLE
#endif

@interface IntentHandler () <INStartAudioCallIntentHandling, INStartVideoCallIntentHandling, INSendMessageIntentHandling>

// Build Settings
@property (nonatomic) id<Configurable> configuration;

/**
 The room that is currently being used to send a message. This is to ensure a
 strong ref is maintained on the `MXRoom` until sending has completed.
 */
@property (nonatomic) MXRoom *selectedRoom;

@property (nonatomic) id<ContactResolving> contactResolver;

@end

@implementation IntentHandler

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _contactResolver = [[ContactResolver alloc] init];
        
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
    }
    return self;
}

- (id)handlerForIntent:(INIntent *)intent
{
    return self;
}

#pragma mark - INStartAudioCallIntentHandling

- (void)resolveContactsForStartAudioCall:(INStartAudioCallIntent *)intent withCompletion:(void (^)(NSArray<INPersonResolutionResult *> * _Nonnull))completion
{
    [self.contactResolver resolveContacts:intent.contacts withCompletion:completion];
}

- (void)confirmStartAudioCall:(INStartAudioCallIntent *)intent completion:(void (^)(INStartAudioCallIntentResponse * _Nonnull))completion
{
    INStartAudioCallIntentResponse *response = nil;
    
    MXKAccount *account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    if (account)
    {
#if defined MX_CALL_STACK_OPENWEBRTC || defined MX_CALL_STACK_ENDPOINT || defined CALL_STACK_JINGLE
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INStartAudioCallIntent class])];
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeReady userActivity:userActivity];
#else
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeFailureCallingServiceNotAvailable userActivity:nil];
#endif
    }
    else
    {
        // User hasn't logged in
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeFailureAppConfigurationRequired userActivity:nil];
    }
    
    completion(response);
}

- (void)handleStartAudioCall:(INStartAudioCallIntent *)intent completion:(void (^)(INStartAudioCallIntentResponse * _Nonnull))completion
{
    INStartAudioCallIntentResponse *response = nil;
    
    INPerson *person = intent.contacts.firstObject;
    if (person && person.customIdentifier)
    {
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass(INStartAudioCallIntent.class)];
        userActivity.userInfo = @{ @"roomID" : person.customIdentifier };
        
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeContinueInApp
                                                           userActivity:userActivity];
    }
    else
    {
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeFailure userActivity:nil];
    }

    completion(response);
}

#pragma mark - INStartVideoCallIntentHandling

- (void)resolveContactsForStartVideoCall:(INStartVideoCallIntent *)intent withCompletion:(void (^)(NSArray<INPersonResolutionResult *> * _Nonnull))completion
{
    [self.contactResolver resolveContacts:intent.contacts withCompletion:completion];
}

- (void)confirmStartVideoCall:(INStartVideoCallIntent *)intent completion:(void (^)(INStartVideoCallIntentResponse * _Nonnull))completion
{
    INStartVideoCallIntentResponse *response = nil;
    
    MXKAccount *account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    if (account)
    {
#if defined MX_CALL_STACK_OPENWEBRTC || defined MX_CALL_STACK_ENDPOINT || defined CALL_STACK_JINGLE
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INStartVideoCallIntent class])];
        response = [[INStartVideoCallIntentResponse alloc] initWithCode:INStartVideoCallIntentResponseCodeReady userActivity:userActivity];
#else
        response = [[INStartVideoCallIntentResponse alloc] initWithCode:INStartVideoCallIntentResponseCodeFailureCallingServiceNotAvailable userActivity:nil];
#endif
    }
    else
    {
        // User hasn't logged in
        response = [[INStartVideoCallIntentResponse alloc] initWithCode:INStartVideoCallIntentResponseCodeFailureRequiringAppLaunch userActivity:nil];
    }
    
    completion(response);
}

- (void)handleStartVideoCall:(INStartVideoCallIntent *)intent completion:(void (^)(INStartVideoCallIntentResponse * _Nonnull))completion
{
    INStartVideoCallIntentResponse *response = nil;
    
    INPerson *person = intent.contacts.firstObject;
    if (person && person.customIdentifier)
    {
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass(INStartVideoCallIntent.class)];
        userActivity.userInfo = @{ @"roomID" : person.customIdentifier };
        
        response = [[INStartVideoCallIntentResponse alloc] initWithCode:INStartVideoCallIntentResponseCodeContinueInApp
                                                           userActivity:userActivity];
    }
    else
    {
        response = [[INStartVideoCallIntentResponse alloc] initWithCode:INStartVideoCallIntentResponseCodeFailure userActivity:nil];
    }
    
    completion(response);
}

#pragma mark - INSendMessageIntentHandling

- (void)resolveRecipientsForSendMessage:(INSendMessageIntent *)intent completion:(void (^)(NSArray<INSendMessageRecipientResolutionResult *> * _Nonnull))completion
{
    [self.contactResolver resolveContacts:intent.recipients withCompletion:completion];
}

- (void)resolveContentForSendMessage:(INSendMessageIntent *)intent withCompletion:(void (^)(INStringResolutionResult * _Nonnull))completion
{
    NSString *message = intent.content;
    if (message && ![message isEqualToString:@""])
        completion([INStringResolutionResult successWithResolvedString:message]);
    else
        completion([INStringResolutionResult needsValue]);
}

- (void)confirmSendMessage:(INSendMessageIntent *)intent completion:(void (^)(INSendMessageIntentResponse * _Nonnull))completion
{
    INSendMessageIntentResponse *response = nil;
    
    MXKAccount *account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    if (account)
    {
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INSendMessageIntent class])];
        response = [[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeReady userActivity:userActivity];
    }
    else
    {
        // User hasn't logged in
        response = [[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeFailureRequiringAppLaunch userActivity:nil];
    }
    
    completion(response);
}

- (void)handleSendMessage:(INSendMessageIntent *)intent completion:(void (^)(INSendMessageIntentResponse * _Nonnull))completion
{
    void (^completeWithCode)(INSendMessageIntentResponseCode) = ^(INSendMessageIntentResponseCode code) {
        NSUserActivity *userActivity = nil;
        if (code == INSendMessageIntentResponseCodeSuccess)
            userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INSendMessageIntent class])];
        INSendMessageIntentResponse *response = [[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeSuccess
                                                                                     userActivity:userActivity];
        completion(response);
    };
    
    INPerson *person = intent.recipients.firstObject;
    if (person && person.customIdentifier)
    {
        MXKAccount *account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        MXFileStore *fileStore = [[MXFileStore alloc] initWithCredentials:account.mxCredentials];
        [fileStore.roomSummaryStore fetchAllSummaries:^(NSArray<id<MXRoomSummaryProtocol>> * _Nonnull summaries) {
            NSString *roomID = person.customIdentifier;
            
            BOOL isEncrypted = NO;
            for (id<MXRoomSummaryProtocol> summary in summaries)
            {
                if ([summary.roomId isEqualToString:roomID])
                {
                    isEncrypted = summary.isEncrypted;
                    break;
                }
            }

            if (isEncrypted)
            {
                [MXFileStore setPreloadOptions:0];

                MXSession *session = [[MXSession alloc] initWithMatrixRestClient:account.mxRestClient];
                MXWeakify(session);
                [session setStore:fileStore success:^{
                    MXStrongifyAndReturnIfNil(session);

                    self.selectedRoom = [MXRoom loadRoomFromStore:fileStore withRoomId:roomID matrixSession:session];

                    // Do not warn for unknown devices. We have cross-signing now
                    session.crypto.warnOnUnknowDevices = NO;

                    MXWeakify(self);
                    [self.selectedRoom sendTextMessage:intent.content
                                              threadId:nil
                                               success:^(NSString *eventId) {
                        completeWithCode(INSendMessageIntentResponseCodeSuccess);
                        MXStrongifyAndReturnIfNil(self);
                        self.selectedRoom = nil;
                    } failure:^(NSError *error) {
                        completeWithCode(INSendMessageIntentResponseCodeFailure);
                        MXStrongifyAndReturnIfNil(self);
                        self.selectedRoom = nil;
                    }];

                } failure:^(NSError *error) {
                    completeWithCode(INSendMessageIntentResponseCodeFailure);
                }];

                return;
            }
            
            [account.mxRestClient sendTextMessageToRoom:roomID
                                               threadId:nil
                                                   text:intent.content
                                                success:^(NSString *eventId) {
                completeWithCode(INSendMessageIntentResponseCodeSuccess);
            }
                                                failure:^(NSError *error) {
                completeWithCode(INSendMessageIntentResponseCodeFailure);
            }];
            
        }];
    }
    else
    {
        completeWithCode(INSendMessageIntentResponseCodeFailure);
    }
}

@end
