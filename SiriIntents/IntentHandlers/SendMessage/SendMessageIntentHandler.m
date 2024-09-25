// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

#import "SendMessageIntentHandler.h"
#import "ContactResolver.h"
#import "MXKAccountManager.h"
#import "GeneratedInterface-Swift.h"

@interface SendMessageIntentHandler ()

@property (nonatomic) id<ContactResolving> contactResolver;

/**
 The room that is currently being used to send a message. This is to ensure a
 strong ref is maintained on the `MXRoom` until sending has completed.
 */
@property (nonatomic) MXRoom *selectedRoom;

@end

@implementation SendMessageIntentHandler

- (instancetype)initWithContactResolver:(id<ContactResolving>)contactResolver
{
    if (self = [super init]) {
        _contactResolver = contactResolver;
    }
    
    return self;
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
