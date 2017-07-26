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

#import "MXKAccountManager.h"
#import "MXKAccount.h"
#import "MXSession.h"
#import "MXFileStore.h"
//#import <MatrixKit/MXKAccountManager.h>

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

@interface IntentHandler () <INStartAudioCallIntentHandling>

@end

@implementation IntentHandler

- (id)handlerForIntent:(INIntent *)intent {
    id handler = nil;
    
    if ([intent isKindOfClass:INStartAudioCallIntent.class])
    {
        handler = self;
    }
    
    return handler;
}

#pragma mark - INStartAudioCallIntentHandling

- (void)resolveContactsForStartAudioCall:(INStartAudioCallIntent *)intent withCompletion:(void (^)(NSArray<INPersonResolutionResult *> * _Nonnull))completion
{
    MXKAccount *account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    MXSession *session = [[MXSession alloc] initWithMatrixRestClient:account.mxRestClient];
    [session setStore:[[MXFileStore alloc] init] success:^{
        NSLog(@"Super");
    } failure:^(NSError *error) {
        NSLog(@"Fail");
    }];
    
    //    NSArray<INPerson *> *recipients = intent.contacts;
    //    // If no recipients were provided we'll need to prompt for a value.
    //    if (recipients.count == 0) {
    //        completion(@[[INPersonResolutionResult needsValue]]);
    //        return;
    //    }
    //    NSMutableArray<INPersonResolutionResult *> *resolutionResults = [NSMutableArray array];
    //
    //    for (INPerson *recipient in recipients) {
    //        NSArray<INPerson *> *matchingContacts = @[recipient]; // Implement your contact matching logic here to create an array of matching contacts
    //        if (matchingContacts.count > 1) {
    //            // We need Siri's help to ask user to pick one from the matches.
    //            [resolutionResults addObject:[INPersonResolutionResult disambiguationWithPeopleToDisambiguate:matchingContacts]];
    //
    //        } else if (matchingContacts.count == 1) {
    //            // We have exactly one matching contact
    //            [resolutionResults addObject:[INPersonResolutionResult successWithResolvedPerson:recipient]];
    //        } else {
    //            // We have no contacts matching the description provided
    //            [resolutionResults addObject:[INPersonResolutionResult unsupported]];
    //        }
    //    }
    //
    //    completion(resolutionResults);
}

- (void)confirmStartAudioCall:(INStartAudioCallIntent *)intent completion:(void (^)(INStartAudioCallIntentResponse * _Nonnull))completion
{
    INStartAudioCallIntentResponse *response = nil;
    
#if defined MX_CALL_STACK_OPENWEBRTC || defined MX_CALL_STACK_ENDPOINT || defined MX_CALL_STACK_JINGLE
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass(INStartAudioCallIntent.class)];
    response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeReady userActivity:userActivity];
#else
    response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeFailureCallingServiceNotAvailable userActivity:nil];
#endif
    
    completion(response);
}

- (void)handleStartAudioCall:(INStartAudioCallIntent *)intent completion:(void (^)(INStartAudioCallIntentResponse * _Nonnull))completion
{
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass(INStartAudioCallIntent.class)];
    //    userActivity.userInfo = @{ @"handle": [NSString stringWithFormat:@"TGCA%d", next.firstObject.userId] };
    INStartAudioCallIntentResponse *response = [[INStartAudioCallIntentResponse alloc] initWithCode:INStartAudioCallIntentResponseCodeContinueInApp userActivity:userActivity];
    completion(response);
}

@end
