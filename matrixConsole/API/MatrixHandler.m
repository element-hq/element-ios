/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "MatrixHandler.h"
#import "AppDelegate.h"

static MatrixHandler *sharedHandler = nil;

@implementation MatrixHandler

+ (MatrixHandler *)sharedHandler {
    @synchronized(self) {
        if(sharedHandler == nil)
        {
            sharedHandler = [[super allocWithZone:NULL] init];
        }
    }
    return sharedHandler;
}

- (MXSession*)mxSession {
    // Only the first account is presently used
    MXKAccount *account = [[MXKAccountManager sharedManager].accounts firstObject];
    return account.mxSession;
}

- (MXRestClient*)mxRestClient {
    // Only the first account is presently used
    MXKAccount *account = [[MXKAccountManager sharedManager].accounts firstObject];
    return account.mxRestClient;
}


// FIXME GFO Move the following methods in SDK and Remove MatrixHandler class

#pragma mark - Room handling

- (NSString*)privateOneToOneRoomIdWithUserId:(NSString*)userId {
    
    if (self.mxSession) {
        for (MXRoom *mxRoom in self.mxSession.rooms) {
            // Consider only private room with 2 users
            if (!mxRoom.state.isPublic && mxRoom.state.members.count == 2) {
                NSArray* roomMembers = mxRoom.state.members;
                
                // Check whether the provided userId is one of them
                MXRoomMember* member = nil;
                MXRoomMember* member1 = [roomMembers objectAtIndex:0];
                if ([member1.userId isEqualToString:userId]) {
                    member = member1;
                } else {
                    MXRoomMember* member2 = [roomMembers objectAtIndex:1];
                    if ([member2.userId isEqualToString:userId]) {
                        member = member2;
                    }
                }
                
                if (member) {
                    // Check the membership of this member (Indeed the room should be ignored if the member left it)
                    if (member.membership != MXMembershipLeave && member.membership != MXMembershipBan) {
                        // We found the right room
                        return mxRoom.state.roomId;
                    }
                }
            }
        }
    }
    
    return nil;
}

- (void)startPrivateOneToOneRoomWithUserId:(NSString*)userId {
    if (self.mxRestClient) {
        NSString* roomId = [self privateOneToOneRoomIdWithUserId:userId];
        
        // if the room exists
        if (roomId) {
            // open it
            [[AppDelegate theDelegate].masterTabBarController showRoom:roomId];
        } else {
            // create a new room
            [self.mxSession createRoom:nil
                            visibility:kMXRoomVisibilityPrivate
                             roomAlias:nil
                                 topic:nil
                               success:^(MXRoom *room) {
                                           // invite the other user only if it is defined and not onself
                                           if (userId && ![self.mxSession.myUser.userId isEqualToString:userId]) {
                                               // add the user
                                               [room inviteUser:userId success:^{
                                               } failure:^(NSError *error) {
                                                   NSLog(@"[MatrixHandler] %@ invitation failed (roomId: %@): %@", userId, room.state.roomId, error);
                                                   //Alert user
                                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                                               }];
                                           }
                                           
                                           // Open created room
                                           [[AppDelegate theDelegate].masterTabBarController showRoom:room.state.roomId];
                                           
                                       } failure:^(NSError *error) {
                                           NSLog(@"[MatrixHandler] Create room failed: %@", error);
                                           //Alert user
                                           [[AppDelegate theDelegate] showErrorAsAlert:error];
                                       }];
        }
    }
}

- (CGFloat)getPowerLevel:(MXRoomMember *)roomMember inRoom:(MXRoom *)room {
    CGFloat powerLevel = 0;
    
    // Customize banned and left (kicked) members
    if (roomMember.membership == MXMembershipLeave || roomMember.membership == MXMembershipBan) {
        powerLevel = 0;
    } else {
        // Handle power level display
        //self.userPowerLevel.hidden = NO;
        MXRoomPowerLevels *roomPowerLevels = room.state.powerLevels;
        
        int maxLevel = 0;
        for (NSString *powerLevel in roomPowerLevels.users.allValues) {
            int level = [powerLevel intValue];
            if (level > maxLevel) {
                maxLevel = level;
            }
        }
        NSUInteger userPowerLevel = [roomPowerLevels powerLevelOfUserWithUserID:roomMember.userId];
        float userPowerLevelFloat = 0.0;
        if (userPowerLevel) {
            userPowerLevelFloat = userPowerLevel;
        }
        
        powerLevel = maxLevel ? userPowerLevelFloat / maxLevel : 1;
    }
    
    return powerLevel;
}

#pragma mark - Presence

// return the presence ring color
// nil means there is no ring to display
- (UIColor*)getPresenceRingColor:(MXPresence)presence {
    switch (presence) {
        case MXPresenceOnline:
            return [UIColor colorWithRed:0.2 green:0.9 blue:0.2 alpha:1.0];
        case MXPresenceUnavailable:
            return [UIColor colorWithRed:0.9 green:0.9 blue:0.0 alpha:1.0];
        case MXPresenceOffline:
            return [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:1.0];
        case MXPresenceUnknown:
        case MXPresenceFreeForChat:
        case MXPresenceHidden:
        default:
            return nil;
    }
}
@end
