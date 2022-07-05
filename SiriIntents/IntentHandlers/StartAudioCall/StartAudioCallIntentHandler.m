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

#import "StartAudioCallIntentHandler.h"
#import "MXKAccountManager.h"
#import "ContactResolver.h"
#import "GeneratedInterface-Swift.h"

@interface StartAudioCallIntentHandler ()

@property (nonatomic) id<ContactResolving> contactResolver;

@end

@implementation StartAudioCallIntentHandler

- (instancetype)initWithContactResolver:(id<ContactResolving>)contactResolver
{
    if (self = [super init]) {
        _contactResolver = contactResolver;
    }
    
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

@end
