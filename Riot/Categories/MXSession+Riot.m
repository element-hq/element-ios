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

#import "MXSession+Riot.h"

#import "MXRoom+Riot.h"
#import "GeneratedInterface-Swift.h"

@implementation MXSession (Riot)

- (NSUInteger)vc_missedDiscussionsCount
{
    NSUInteger missedDiscussionsCount = 0;
    
    // Sum all the rooms with missed notifications.
    for (MXRoom *room in self.rooms)
    {
        NSUInteger notificationCount = room.summary.notificationCount;
        
        // Ignore the regular notification count if the room is in 'mentions only" mode at the Riot level.
        if (room.isMentionsOnly)
        {
            // Only the highlighted missed messages must be considered here.
            notificationCount = room.summary.highlightCount;
        }
        
        if (notificationCount)
        {
            missedDiscussionsCount++;
        }
    }
    
    // Add the invites count
    missedDiscussionsCount += [self invitedRooms].count;
    
    return missedDiscussionsCount;
}

- (HomeserverConfiguration*)vc_homeserverConfiguration
{
    HomeserverConfigurationBuilder *configurationBuilder = [HomeserverConfigurationBuilder new];
    return [configurationBuilder buildFrom:self.homeserverWellknown];
}

- (MXHTTPOperation*)vc_canEnableE2EByDefaultInNewRoomWithUsers:(NSArray<NSString*>*)userIds
                                                         success:(void (^)(BOOL canEnableE2E))success
                                                         failure:(void (^)(NSError *error))failure;
{
    if ([self vc_homeserverConfiguration].encryption.isE2EEByDefaultEnabled)
    {
        return [self canEnableE2EByDefaultInNewRoomWithUsers:userIds success:success failure:failure];
    }
    else
    {
        MXLogWarning(@"[MXSession] E2EE is disabled by default on this homeserver.\nWellknown content: %@", self.homeserverWellknown.JSONDictionary);
        success(NO);
        return [MXHTTPOperation new];
    }
}

- (BOOL)vc_canSetupSecureBackup
{
    MXRecoveryService *recoveryService = self.crypto.recoveryService;
    
    if (recoveryService.hasRecovery)
    {
        // Can't create secure backup if SSSS has already been set.
        return NO;
    }
    
    // Accept to create a setup only if we have the 3 cross-signing keys
    // This is the path to have a sane state
    // TODO: What about missing MSK that was not gossiped before?
    NSArray *crossSigningServiceSecrets = @[
                                            MXSecretId.crossSigningMaster,
                                            MXSecretId.crossSigningSelfSigning,
                                            MXSecretId.crossSigningUserSigning];
    
    return ([recoveryService.secretsStoredLocally mx_intersectArray:crossSigningServiceSecrets].count
            == crossSigningServiceSecrets.count);
}

- (MXRoom*)vc_roomWithIdOrAlias:(NSString*)roomIdOrAlias
{
    if ([MXTools isMatrixRoomIdentifier:roomIdOrAlias]) {
        return [self roomWithRoomId:roomIdOrAlias];
    } else if ([MXTools isMatrixRoomAlias:roomIdOrAlias]) {
        return [self roomWithAlias:roomIdOrAlias];
    } else {
        return nil;
    }
}

@end
