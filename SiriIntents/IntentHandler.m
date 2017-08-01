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

#import "MXKAccount.h"
#import "MXKAccountManager.h"
#import "MXFileStore.h"
#import "MXSession.h"

@interface IntentHandler () <INStartAudioCallIntentHandling>

@end

@implementation IntentHandler

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [MXSDKOptions sharedInstance].applicationGroupIdentifier = @"group.org.matrix";
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
    NSArray<INPerson *> *contacts = intent.contacts;
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
        
        // Check if the user has selected right callee among several candidates from previous resolution process run
        if (callee.customIdentifier && callee.customIdentifier.length)
        {
            completion(@[[INPersonResolutionResult successWithResolvedPerson:callee]]);
            return;
        }
        
        MXKAccount *account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        if (account)
        {
            MXFileStore *fileStore = [[MXFileStore alloc] initWithCredentials:account.mxCredentials];
            [fileStore asyncRoomsSummaries:^(NSArray<MXRoomSummary *> * _Nonnull roomsSummaries) {
                
                // Find all users with whom direct chats are existed
                NSMutableSet<NSString *> *directUserIDs = [NSMutableSet set];
                for (MXRoomSummary *summary in roomsSummaries)
                {
                    if (summary.isDirect)
                        [directUserIDs addObject:summary.directUserId];
                }
                
                [fileStore asyncUsers:^(NSArray<MXUser *> * _Nonnull users) {
                    
                    // Find users with whom we have a direct chat and whose display name contains string presented us by Siri
                    NSMutableArray<INPerson *> *matchingPersons = [NSMutableArray array];
                    for (MXUser *user in users)
                    {
                        if ([directUserIDs containsObject:user.userId])
                        {
                            if (!user.displayname)
                                continue;
                            
                            if (!NSEqualRanges([user.displayname rangeOfString:callee.displayName options:NSCaseInsensitiveSearch], (NSRange){NSNotFound,0}))
                            {
                                INPersonHandle *personHandle = [[INPersonHandle alloc] initWithValue:user.userId type:INPersonHandleTypeUnknown];
                                INPerson *person = [[INPerson alloc] initWithPersonHandle:personHandle
                                                                           nameComponents:nil
                                                                              displayName:user.displayname
                                                                                    image:nil
                                                                        contactIdentifier:nil
                                                                         customIdentifier:user.userId];
                                
                                [matchingPersons addObject:person];
                            }
                        }
                    }
                    
                    if (matchingPersons.count == 0)
                    {
                        completion(@[[INPersonResolutionResult unsupported]]);
                    }
                    else if (matchingPersons.count == 1)
                    {
                        completion(@[[INPersonResolutionResult successWithResolvedPerson:matchingPersons.firstObject]]);
                    }
                    else
                    {
                        completion(@[[INPersonResolutionResult disambiguationWithPeopleToDisambiguate:matchingPersons]]);
                    }
                    
                } failure:nil];
            } failure:nil];
        }
        else
        {
            // If user hasn't logged in yet just pass a blank INPerson instance and handle this situation in confirmStartAudioCall:completion:
            completion(@[[INPersonResolutionResult successWithResolvedPerson:[INPerson new]]]);
        }
    }
}

- (void)confirmStartAudioCall:(INStartAudioCallIntent *)intent completion:(void (^)(INStartAudioCallIntentResponse * _Nonnull))completion
{
    INStartAudioCallIntentResponse *response = nil;
    
    MXKAccount *account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    if (account)
    {
#if defined MX_CALL_STACK_OPENWEBRTC || defined MX_CALL_STACK_ENDPOINT || defined MX_CALL_STACK_JINGLE
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass(INStartAudioCallIntent.class)];
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeReady userActivity:userActivity];
#else
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeFailureCallingServiceNotAvailable userActivity:nil];
#endif
    }
    else
    {
        // User hasn't logged in
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeFailureRequiringAppLaunch userActivity:nil];
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
        userActivity.userInfo = @{ @"userID" : person.customIdentifier };
        
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeContinueInApp
                                                           userActivity:userActivity];
    }
    else
    {
        response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeFailure userActivity:nil];
    }

    completion(response);
}

@end
