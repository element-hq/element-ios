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

#import "ContactResolver.h"
@import Intents;
#import "MXKAccountManager.h"

@implementation ContactResolver

- (void)resolveContacts:(nullable NSArray<INPerson *> *)contacts
         withCompletion:(void (^)(NSArray<INPersonResolutionResult *> * _Nonnull))completion
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
            [fileStore.roomSummaryStore fetchAllSummaries:^(NSArray<id<MXRoomSummaryProtocol>> * _Nonnull summaries) {
                
                // Contains userIds of all users with whom the current user has direct chats
                // Use set to avoid duplicates
                NSMutableSet<NSString *> *directUserIds = [NSMutableSet set];
                
                // Contains room summaries for all direct rooms connected with particular userId
                NSMutableDictionary<NSString *, NSMutableArray<id<MXRoomSummaryProtocol>> *> *roomSummaries = [NSMutableDictionary dictionary];
                
                for (id<MXRoomSummaryProtocol> summary in summaries)
                {
                    // TODO: We also need to check if joined room members count equals 2
                    // It is pointlessly to save rooms with 1 joined member or room with more than 2 joined members
                    if (summary.isDirect)
                    {
                        NSString *directUserId = summary.directUserId;
                        
                        // Collect room summaries only for specified user
                        if (selectedUserId && ![directUserId isEqualToString:selectedUserId])
                            continue;
                        
                        // Save userId
                        [directUserIds addObject:directUserId];
                        
                        // Save associated with diretUserId room summary
                        NSMutableArray<id<MXRoomSummaryProtocol>> *userRoomSummaries = roomSummaries[directUserId];
                        if (userRoomSummaries)
                            [userRoomSummaries addObject:summary];
                        else
                            roomSummaries[directUserId] = [NSMutableArray arrayWithObject:summary];
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
                        NSArray<id<MXRoomSummaryProtocol>> *summaries = roomSummaries[user.userId];
                        for (id<MXRoomSummaryProtocol> summary in summaries)
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
            }];
        }
        else
        {
            completion(@[[INPersonResolutionResult notRequired]]);
        }
    }
}

@end
