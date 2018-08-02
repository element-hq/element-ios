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

#import <MatrixKit/MatrixKit.h>

#if __has_include(<MatrixSDK/MXJingleCallStack.h>)
#define CALL_STACK_JINGLE
#endif

@interface IntentHandler () <INStartAudioCallIntentHandling, INStartVideoCallIntentHandling, INSendMessageIntentHandling>

@end

@implementation IntentHandler

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [MXSDKOptions sharedInstance].applicationGroupIdentifier = @"group.im.vector";

        // NSLog -> console.log file when not debugging the app
        if (!isatty(STDERR_FILENO))
        {
            [MXLogger setSubLogName:@"siri"];
            [MXLogger redirectNSLogToFiles:YES];
        }
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
    [self resolveContacts:intent.contacts withCompletion:completion];
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
    [self resolveContacts:intent.contacts withCompletion:completion];
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

- (void)resolveRecipientsForSendMessage:(INSendMessageIntent *)intent withCompletion:(void (^)(NSArray<INPersonResolutionResult *> * _Nonnull))completion
{
    [self resolveContacts:intent.recipients withCompletion:completion];
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
        [fileStore asyncRoomsSummaries:^(NSArray<MXRoomSummary *> * _Nonnull roomsSummaries) {
                                    NSString *roomID = person.customIdentifier;
            
                                    BOOL isEncrypted = NO;
                                    for (MXRoomSummary *roomSummary in roomsSummaries)
                                    {
                                        if ([roomSummary.roomId isEqualToString:roomID])
                                        {
                                            isEncrypted = roomSummary.isEncrypted;
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
                                            
                                            MXRoom *room = [MXRoom loadRoomFromStore:fileStore withRoomId:roomID matrixSession:session];

                                            [room sendTextMessage:intent.content
                                                          success:^(NSString *eventId) {
                                                              completeWithCode(INSendMessageIntentResponseCodeSuccess);
                                                          } failure:^(NSError *error) {
                                                              completeWithCode(INSendMessageIntentResponseCodeFailure);
                                                          }];

                                        } failure:^(NSError *error) {
                                            completeWithCode(INSendMessageIntentResponseCodeFailure);
                                        }];

                                        return;
                                    }
            
                                    [account.mxRestClient sendTextMessageToRoom:roomID
                                                                           text:intent.content
                                                                        success:^(NSString *eventId) {
                                                                            completeWithCode(INSendMessageIntentResponseCodeSuccess);
                                                                        }
                                                                        failure:^(NSError *error) {
                                                                            completeWithCode(INSendMessageIntentResponseCodeFailure);
                                                                        }];
            
                               }
                               failure:nil];
    }
    else
    {
        completeWithCode(INSendMessageIntentResponseCodeFailure);
    }
}

#pragma mark - Private

- (void)resolveContacts:(nullable NSArray<INPerson *> *)contacts withCompletion:(void (^)(NSArray<INPersonResolutionResult *> * _Nonnull))completion
{
    if (contacts.count == 0)
    {
        completion(@[[INPersonResolutionResult needsValue]]);
        return;
    }
    else
    {
        // We don't iterate over array of contacts from passed intent
        // since it's hard to imagine scenario with several callee
        // so we just extract the first one
        INPerson *callee = contacts.firstObject;
        
        // If this method is called after selection of the appropriate user, it will hold userId of an user to whom we must call
        NSString *selectedUserId;
        
        // Check if the user has selected right room among several direct rooms from previous resolution process run
        if (callee.customIdentifier.length)
        {
            // If callee will have the same name as one of the contact in the system contacts app
            // Siri will pass us this contact in the intent.contacts array and we must provide the same count of
            // resolution results as elements count in the intent.contact.
            // So we just pass the same result at all iterations
            NSMutableArray *resolutionResults = [NSMutableArray array];
            for (NSInteger i = 0; i < contacts.count; ++i)
                [resolutionResults addObject:[INPersonResolutionResult successWithResolvedPerson:callee]];
            completion(resolutionResults);
            return;
        }
        else
        {
            // This resolution process run after selecting appropriate user among suggested user list
            selectedUserId = callee.personHandle.value;
        }
        
        MXKAccount *account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        if (account)
        {
            MXFileStore *fileStore = [[MXFileStore alloc] initWithCredentials:account.mxCredentials];
            [fileStore asyncRoomsSummaries:^(NSArray<MXRoomSummary *> * _Nonnull roomsSummaries) {
                
                // Contains userIds of all users with whom the current user has direct chats
                // Use set to avoid duplicates
                NSMutableSet<NSString *> *directUserIds = [NSMutableSet set];
                
                // Contains room summaries for all direct rooms connected with particular userId
                NSMutableDictionary<NSString *, NSMutableArray<MXRoomSummary *> *> *roomSummaries = [NSMutableDictionary dictionary];
                
                for (MXRoomSummary *summary in roomsSummaries)
                {
                    // TODO: We also need to check if joined room members count equals 2
                    // It is pointlessly to save rooms with 1 joined member or room with more than 2 joined members
                    if (summary.isDirect)
                    {
                        NSString *diretUserId = summary.directUserId;
                        
                        // Collect room summaries only for specified user
                        if (selectedUserId && ![diretUserId isEqualToString:selectedUserId])
                            continue;
                        
                        // Save userId
                        [directUserIds addObject:diretUserId];
                        
                        // Save associated with diretUserId room summary
                        NSMutableArray<MXRoomSummary *> *userRoomSummaries = roomSummaries[diretUserId];
                        if (userRoomSummaries)
                            [userRoomSummaries addObject:summary];
                        else
                            roomSummaries[diretUserId] = [NSMutableArray arrayWithObject:summary];
                    }
                }
                
                [fileStore asyncUsersWithUserIds:directUserIds.allObjects success:^(NSArray<MXUser *> * _Nonnull users) {
                    
                    // Find users whose display name contains string presented us by Siri
                    NSMutableArray<MXUser *> *matchingUsers = [NSMutableArray array];
                    for (MXUser *user in users)
                    {
                        if (!user.displayname)
                            continue;
                        
                        if (!NSEqualRanges([callee.displayName rangeOfString:user.displayname options:NSCaseInsensitiveSearch], (NSRange){NSNotFound,0}))
                        {
                            [matchingUsers addObject:user];
                        }
                    }

                    NSMutableArray<INPerson *> *persons = [NSMutableArray array];
                    
                    if (matchingUsers.count == 1)
                    {
                        MXUser *user = matchingUsers.firstObject;
                        
                        // Provide to the user a list of direct rooms to choose from
                        NSArray<MXRoomSummary *> *summaries = roomSummaries[user.userId];
                        for (MXRoomSummary *summary in summaries)
                        {
                            INPersonHandle *personHandle = [[INPersonHandle alloc] initWithValue:user.userId type:INPersonHandleTypeUnknown];
                            
                            // For rooms we try to use room display name
                            NSString *displayName = summary.displayname ? summary.displayname : user.displayname;
                            
                            INPerson *person = [[INPerson alloc] initWithPersonHandle:personHandle
                                                                       nameComponents:nil
                                                                          displayName:displayName
                                                                                image:nil
                                                                    contactIdentifier:nil
                                                                     customIdentifier:summary.roomId];
                            
                            [persons addObject:person];
                        }
                    }
                    else if (matchingUsers.count > 1)
                    {
                        // Provide to the user a list of users to choose from
                        // This is the case when there are several users with the same name
                        for (MXUser *user in matchingUsers)
                        {
                            INPersonHandle *personHandle = [[INPersonHandle alloc] initWithValue:user.userId type:INPersonHandleTypeUnknown];
                            INPerson *person = [[INPerson alloc] initWithPersonHandle:personHandle
                                                                       nameComponents:nil
                                                                          displayName:user.displayname
                                                                                image:nil
                                                                    contactIdentifier:nil
                                                                     customIdentifier:nil];
                            
                            [persons addObject:person];
                        }
                    }
                    
                    if (persons.count == 0)
                    {
                        completion(@[[INPersonResolutionResult unsupported]]);
                    }
                    else if (persons.count == 1)
                    {
                        completion(@[[INPersonResolutionResult successWithResolvedPerson:persons.firstObject]]);
                    }
                    else
                    {
                        completion(@[[INPersonResolutionResult disambiguationWithPeopleToDisambiguate:persons]]);
                    }
                } failure:nil];
            } failure:nil];
        }
        else
        {
            completion(@[[INPersonResolutionResult notRequired]]);
        }
    }
}

@end
