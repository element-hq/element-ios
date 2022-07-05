// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "StartVideoCallIntentHandler.h"
#import "ContactResolver.h"
#import "MXKAccountManager.h"
#import "GeneratedInterface-Swift.h"

@interface StartVideoCallIntentHandler ()

@property (nonatomic) id<ContactResolving> contactResolver;

@end

@implementation StartVideoCallIntentHandler

- (instancetype)initWithContactResolver:(id<ContactResolving>)contactResolver
{
    if (self = [super init]) {
        _contactResolver = contactResolver;
    }
    
    return self;
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

@end
