/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MXRoom+Vector.h"

#import "AvatarGenerator.h"

@interface MXRoom ()

// create property for the extensions

// rule events observer
@property id notificationCenterDidFailObserver;
@property id notificationCenterDidUpdateObserver;

@end

@implementation MXRoom (Vector)

/**
 Returns the room rule notifition.
 
 @return the dedicated push rule
 */
- (MXPushRule*)getRoomPushRule
{
    NSArray* rules = self.mxSession.notificationCenter.rules.global.room;
    
    // sanity checks
    if (rules)
    {
        for(MXPushRule* rule in rules)
        {
            // the rule id is the room Id
            // it is the server trick to avoid duplicated rule on the same room.
            if ([rule.ruleId isEqualToString:self.state.roomId])
            {
                return rule;
            }
        }
    }
    
    return nil;
}

- (BOOL)areRoomNotificationsMuted
{
    MXPushRule* rule = [self getRoomPushRule];
    
    if (rule)
    {
        for (MXPushRuleAction *ruleAction in rule.actions)
        {
            if (ruleAction.actionType == MXPushRuleActionTypeDontNotify)
            {
                return rule.enabled;
            }
        }
    }
    
    return NO;
}

- (BOOL)isModerator
{
    // Check whether the user has enough power to rename the room or update the avatar
    MXRoomPowerLevels *powerLevels = [self.state powerLevels];
    
    NSUInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mxSession.myUser.userId];
    
    return (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomName]);
}

- (void)toggleRoomNotifications:(BOOL)mute
{
    BOOL isNotified = ![self areRoomNotificationsMuted];
    
    // check if the state is already in the right state
    if (isNotified == !mute)
    {
        return;
    }
    
    MXNotificationCenter* notificationCenter = self.mxSession.notificationCenter;
    MXPushRule* rule = [self getRoomPushRule];
    
    if (!mute)
    {
        // let the other notification rules manage the pushes.
        [notificationCenter removeRule:rule];
    }
    else
    {
        // user does not want to have push
        
        // if there is no rule
        if (!rule)
        {
            // add one
            [notificationCenter addRoomRule:self.state.roomId
                                     notify:NO
                                      sound:NO
                                  highlight:NO];
        }
        else
        {
            
            // check if the user did not define one
            BOOL hasDontNotifyRule = NO;
            
            for (MXPushRuleAction *ruleAction in rule.actions)
            {
                if (ruleAction.actionType == MXPushRuleActionTypeDontNotify)
                {
                    hasDontNotifyRule = YES;
                    break;
                }
            }
            
            // if the user defined one, use it
            if (hasDontNotifyRule)
            {
                [notificationCenter enableRule:rule isEnabled:YES];
            }
            else
            {
                __weak typeof(self) weakSelf = self;
                
                // if the user defined a room rule
                // the rule is deleted before adding new one
                
                id localNotificationCenterDidUpdateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidUpdateRules object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                    
                    MXPushRule* rule = [self getRoomPushRule];
                    
                    // check if the rule has been deleted
                    // there is no way to know if the notif is really for this rule..
                    if (!rule)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        if (strongSelf.notificationCenterDidUpdateObserver)
                        {
                            [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                            strongSelf.notificationCenterDidUpdateObserver = nil;
                        }
                        
                        if (strongSelf.notificationCenterDidFailObserver)
                        {
                            [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                            strongSelf.notificationCenterDidUpdateObserver = nil;
                        }
                        
                        // add one dedicated rule
                        [notificationCenter addRoomRule:self.state.roomId
                                                 notify:NO
                                                  sound:NO
                                              highlight:NO];
                    }
                }];
                
                id localNotificationCenterDidFailObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidFailRulesUpdate object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                    
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    if (strongSelf.notificationCenterDidUpdateObserver)
                    {
                        [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                        strongSelf.notificationCenterDidUpdateObserver = nil;
                    }
                    
                    if (strongSelf.notificationCenterDidFailObserver)
                    {
                        [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                        strongSelf.notificationCenterDidUpdateObserver = nil;
                    }
                }];
                
                self.notificationCenterDidUpdateObserver = localNotificationCenterDidUpdateObserver;
                self.notificationCenterDidFailObserver = localNotificationCenterDidFailObserver;
                
                // remove the rule notification
                // the notifications are used to tell
                [notificationCenter removeRule:rule];
            }
        }
    }
}

- (void)setRoomAvatarImageIn:(MXKImageView*)mxkImageView
{
    NSString* roomAvatarUrl = self.state.avatar;
    
    // detect if it is a room with no more than 2 members (i.e. an alone or a 1:1 chat)
    if (!roomAvatarUrl)
    {
        NSString* myUserId = self.mxSession.myUser.userId;
        
        NSArray* members = self.state.members;
        
        if (members.count < 3)
        {
            // use the member avatar only it is an active member
            for (MXRoomMember *roomMember in members)
            {
                if ((MXMembershipJoin == roomMember.membership) && ((members.count == 1) || ![roomMember.userId isEqualToString:myUserId]))
                {
                    roomAvatarUrl = roomMember.avatarUrl;
                    break;
                }
            }
        }
    }
    
    UIImage* avatarImage = [AvatarGenerator generateRoomAvatar:self];
    
    if (roomAvatarUrl)
    {
        mxkImageView.enableInMemoryCache = YES;
        
        [mxkImageView setImageURL:[self.mxSession.matrixRestClient urlOfContentThumbnail:roomAvatarUrl toFitViewSize:mxkImageView.frame.size withMethod:MXThumbnailingMethodCrop] withType:nil andImageOrientation:UIImageOrientationUp previewImage:avatarImage];
    }
    else
    {
        mxkImageView.image = avatarImage;
    }
    
    mxkImageView.contentMode = UIViewContentModeScaleAspectFill;
}

- (NSString *)vectorDisplayname
{
    // this algo is the one defined in
    // https://github.com/matrix-org/matrix-js-sdk/blob/develop/lib/models/room.js#L617
    // calculateRoomName(room, userId)
    
    MXRoomState* roomState = self.state;
    
    if (roomState.name.length > 0)
    {
        return roomState.name;
    }
    
    NSString *alias = roomState.canonicalAlias;
    
    if (!alias)
    {
        // For rooms where canonical alias is not defined, we use the 1st alias as a workaround
        NSArray *aliases = roomState.aliases;
        
        if (aliases.count)
        {
            alias = [aliases[0] copy];
        }
    }
    
    if (alias)
    {
        return alias;
    }
    
    NSString* myUserId = self.mxSession.myUser.userId;
    
    NSArray* members = roomState.members;
    NSMutableArray* othersActiveMembers = [[NSMutableArray alloc] init];
    NSMutableArray* activeMembers = [[NSMutableArray alloc] init];
    
    for(MXRoomMember* member in members)
    {
        if (member.membership != MXMembershipLeave)
        {
            if (![member.userId isEqualToString:myUserId])
            {
                [othersActiveMembers addObject:member];
            }
            
            [activeMembers addObject:member];
        }
    }
    
    // sort the members by their creation (oldest first)
    othersActiveMembers = [[othersActiveMembers sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        uint64_t originServerTs1 = 0;
        uint64_t originServerTs2 = 0;
        
        MXRoomMember* member1 = (MXRoomMember*)obj1;
        MXRoomMember* member2 = (MXRoomMember*)obj2;
        
        if (member1.originalEvent)
        {
            originServerTs1 = member1.originalEvent.originServerTs;
        }
        
        if (member2.originalEvent)
        {
            originServerTs2 = member2.originalEvent.originServerTs;
        }
        
        if (originServerTs1 == originServerTs2)
        {
            return NSOrderedSame;
        }
        else
        {
            return originServerTs1 > originServerTs2 ? NSOrderedDescending : NSOrderedAscending;
        }
    }] mutableCopy];
    
    
    NSString* displayName = @"";
    
    // TODO: Localisation
    if (othersActiveMembers.count == 0)
    {
        if (activeMembers.count == 1)
        {
            MXRoomMember* member = [activeMembers objectAtIndex:0];
            
            if (member.membership == MXMembershipInvite)
            {
                if (member.originalEvent.sender)
                {
                    // extract who invited us to the room
                    displayName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_displayname_invite_from", @"Vector", nil), [roomState memberName:member.originalEvent.sender]];
                }
                else
                {
                    displayName = NSLocalizedStringFromTable(@"room_displayname_room_invite", @"Vector", nil);
                }
            }
            else
            {
                displayName = myUserId;
            }
        }
    }
    else if (othersActiveMembers.count == 1)
    {
        MXRoomMember* member = [othersActiveMembers objectAtIndex:0];
        
        displayName = [roomState memberName:member.userId];
    }
    else if (othersActiveMembers.count == 2)
    {
        MXRoomMember* member1 = [othersActiveMembers objectAtIndex:0];
        MXRoomMember* member2 = [othersActiveMembers objectAtIndex:1];
        
        displayName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_displayname_two_members", @"Vector", nil), [roomState memberName:member1.userId], [roomState memberName:member2.userId]];
    }
    else
    {
        MXRoomMember* member = [othersActiveMembers objectAtIndex:0];
        displayName = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_displayname_more_than_two_members", @"Vector", nil), [roomState memberName:member.userId], othersActiveMembers.count - 1];
    }
    
    return displayName;
}

@end
