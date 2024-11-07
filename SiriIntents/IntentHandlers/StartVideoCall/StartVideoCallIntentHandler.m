// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
