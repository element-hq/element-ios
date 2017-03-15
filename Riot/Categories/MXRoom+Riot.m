/*
 Copyright 2015 OpenMarket Ltd
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

#import "MXRoom+Riot.h"

#import "AvatarGenerator.h"

#import <objc/runtime.h>

@implementation MXRoom (Riot)

#pragma mark - Room avatar

- (void)setRoomAvatarImageIn:(MXKImageView*)mxkImageView
{
    NSString* roomAvatarUrl = self.state.avatar;
    
    if (!roomAvatarUrl)
    {
        // If the room has only two members, use the avatar of the second member.
        NSArray* members = self.state.members;
        
        if (members.count == 2)
        {
            NSString* myUserId = self.mxSession.myUser.userId;
            
            for (MXRoomMember *roomMember in members)
            {
                if (![roomMember.userId isEqualToString:myUserId])
                {
                    // Use the avatar of this member only if he joined or he is invited.
                    if (MXMembershipJoin == roomMember.membership || MXMembershipInvite == roomMember.membership)
                    {
                        roomAvatarUrl = roomMember.avatarUrl;
                    }
                    break;
                }
            }
        }
    }
    
    // Retrieve the Riot room display name to prepare the default avatar image.
    // Note: this display name is nil for an "empty room" without display name (We name "empty room" a room in which the current user is the only active member).
    NSString *avatarDisplayName = self.riotDisplayname;
    UIImage* avatarImage = [AvatarGenerator generateAvatarForMatrixItem:self.state.roomId withDisplayName:avatarDisplayName];
    
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

#pragma mark - Room display name
// @TODO: May worth to refactor to use MXRoomSummary
- (NSString *)riotDisplayname
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
    
    // check if there is non empty alias.
    if ([alias length] > 0)
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

#pragma mark - Room tags

- (void)setRoomTag:(NSString*)tag completion:(void (^)())completion
{
    NSString* oldTag = nil;
    
    if (self.accountData.tags && self.accountData.tags.count)
    {
        oldTag = [self.accountData.tags.allKeys objectAtIndex:0];
    }
    
    // support only kMXRoomTagFavourite or kMXRoomTagLowPriority tags by now
    if (![tag isEqualToString:kMXRoomTagFavourite] && ![tag isEqualToString:kMXRoomTagLowPriority])
    {
        tag = nil;
    }
    
    NSString* tagOrder = [self.mxSession tagOrderToBeAtIndex:0 from:NSNotFound withTag:tag];
    
    NSLog(@"[MXRoom+Riot] Update the room %@ tag from %@ to %@ with tag order %@", self.state.roomId, oldTag, tag, tagOrder);
    
    [self replaceTag:oldTag
               byTag:tag
           withOrder:tagOrder
             success: ^{
                 
                 if (completion)
                 {
                     completion();
                 }
                 
             } failure:^(NSError *error) {
                 
                 NSLog(@"[MXRoom+Riot] Failed to update the tag %@ of room (%@)", tag, self.state.roomId);
                 
                 // Notify user
                 [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                 
                 if (completion)
                 {
                     completion();
                 }
             }];
}

#pragma mark - Room notification mode

- (BOOL)isMute
{
    // Check whether an override rule has been defined with the roomm id as rule id.
    // This kind of rule is created to mute the room
    MXPushRule* rule = [self getOverrideRoomPushRule];
    if (rule)
    {
        for (MXPushRuleAction *ruleAction in rule.actions)
        {
            if (ruleAction.actionType == MXPushRuleActionTypeDontNotify)
            {
                for (MXPushRuleCondition *ruleCondition in rule.conditions)
                {
                    if (ruleCondition.kindType == MXPushRuleConditionTypeEventMatch)
                    {
                        NSString *key;
                        NSString *pattern;
                        
                        MXJSONModelSetString(key, ruleCondition.parameters[@"key"]);
                        MXJSONModelSetString(pattern, ruleCondition.parameters[@"pattern"]);
                        
                        if (key && pattern && [key isEqualToString:@"room_id"] && [pattern isEqualToString:self.state.roomId])
                        {
                            return rule.enabled;
                        }
                    }
                }
            }
        }
    }
    
    return NO;
}

- (BOOL)isMentionsOnly
{
    // Check push rules at room level
    MXPushRule *rule = [self getRoomPushRule];
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

- (void)mute:(void (^)())completion
{
    // Check the current notification mode
    if (self.isMute)
    {
        if (completion)
        {
            completion();
        }
        return;
    }
    
    // Check whether a rule at room level must be removed first
    if (self.isMentionsOnly)
    {
        MXPushRule* rule = [self getRoomPushRule];
        
        [self removePushRule:rule completion:^{
            
            [self mute:completion];
            
        }];
        
        return;
    }
    
    // The user does not want to have push at all
    MXPushRule* rule = [self getOverrideRoomPushRule];
    
    // Check if no rule is already defined.
    if (!rule)
    {
        // Add a new one
        [self addPushRuleToMute:completion];
    }
    else
    {
        // Check whether there is no pending update for this room
        if (self.notificationCenterDidUpdateObserver)
        {
            NSLog(@"[MXRoom+Riot] Request in progress: ignore push rule update");
            if (completion)
            {
                completion();
            }
            return;
        }
        
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
            [self enablePushRule:rule completion:completion];
        }
        else
        {
            // If the user has defined a room rule, the rule is deleted before adding new one.
            [self removePushRule:rule completion:^{
                
                // Add new rule to disable notification
                [self addPushRuleToMute:completion];
                
            }];
        }
    }
}

- (void)mentionsOnly:(void (^)())completion
{
    // Check the current notification mode
    if (self.isMentionsOnly)
    {
        if (completion)
        {
            completion();
        }
        return;
    }
    
    // Check whether an override rule must be removed first
    if (self.mute)
    {
        MXPushRule* rule = [self getOverrideRoomPushRule];
        
        [self removePushRule:rule completion:^{
            
            [self mentionsOnly:completion];
            
        }];
        
        return;
    }
    
    // The user wants to have push only for highlighted notifications
    MXPushRule* rule = [self getRoomPushRule];
    
    // Check if no rule is already defined.
    if (!rule)
    {
        // Add a new one
        [self addPushRuleToMentionsOnly:completion];
    }
    else
    {
        // Check whether there is no pending update for this room
        if (self.notificationCenterDidUpdateObserver)
        {
            NSLog(@"[MXRoom+Riot] Request in progress: ignore push rule update");
            if (completion)
            {
                completion();
            }
            return;
        }
        
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
            [self enablePushRule:rule completion:completion];
        }
        else
        {
            // If the user has defined a room rule, the rule is deleted before adding new one.
            [self removePushRule:rule completion:^{
                
                // Add new rule to disable notification
                [self addPushRuleToMentionsOnly:completion];
                
            }];
        }
    }
}

- (void)allMessages:(void (^)())completion
{
    // Check the current notification mode
    if (!self.isMentionsOnly && !self.isMute)
    {
        // Nothing to do
        if (completion)
        {
            completion();
        }
        return;
    }
    
    // Check whether an override rule must be removed first
    if (self.isMute)
    {
        MXPushRule* rule = [self getOverrideRoomPushRule];
        
        [self removePushRule:rule completion:^{
            
            // Check the push rule at room level now
            [self allMessages:completion];
            
        }];
        
        return;
    }
    
    // Check whether a rule at room level must be removed
    if (self.isMentionsOnly)
    {
        MXPushRule* rule = [self getRoomPushRule];
        
        [self removePushRule:rule completion:^{
            
            // let the other notification rules manage the pushes.
            [self removePushRule:rule completion:completion];
            
        }];
    }
}

#pragma mark -

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

- (MXPushRule*)getOverrideRoomPushRule
{
    NSArray* rules = self.mxSession.notificationCenter.rules.global.override;
    
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

- (void)addPushRuleToMentionsOnly:(void (^)())completion
{
    MXNotificationCenter* notificationCenter = self.mxSession.notificationCenter;
    
    // Define notificationCenter observers if a completion block is defined.
    if (completion)
    {
        __weak typeof(self) weakSelf = self;
        
        self.notificationCenterDidUpdateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidUpdateRules object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            // Check whether the rule has been added
            BOOL isAdded = ([self getRoomPushRule] != nil);
            if (isAdded)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                
                if (strongSelf.notificationCenterDidUpdateObserver)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                    strongSelf.notificationCenterDidUpdateObserver = nil;
                }
                
                if (strongSelf.notificationCenterDidFailObserver)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidFailObserver];
                    strongSelf.notificationCenterDidFailObserver = nil;
                }
                
                completion();
            }
        }];
        
        self.notificationCenterDidFailObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidFailRulesUpdate object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            if (strongSelf.notificationCenterDidUpdateObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                strongSelf.notificationCenterDidUpdateObserver = nil;
            }
            
            if (strongSelf.notificationCenterDidFailObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidFailObserver];
                strongSelf.notificationCenterDidFailObserver = nil;
            }
            
            completion();
        }];
    }
    
    [notificationCenter addRoomRule:self.state.roomId
                             notify:NO
                              sound:NO
                          highlight:NO];
}

- (void)addPushRuleToMute:(void (^)())completion
{
    MXNotificationCenter* notificationCenter = self.mxSession.notificationCenter;
    
    // Define notificationCenter observers if a completion block is defined.
    if (completion)
    {
        __weak typeof(self) weakSelf = self;
        
        self.notificationCenterDidUpdateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidUpdateRules object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            // Check whether the rule has been added
            BOOL isAdded = ([self getOverrideRoomPushRule] != nil);
            if (isAdded)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                
                if (strongSelf.notificationCenterDidUpdateObserver)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                    strongSelf.notificationCenterDidUpdateObserver = nil;
                }
                
                if (strongSelf.notificationCenterDidFailObserver)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidFailObserver];
                    strongSelf.notificationCenterDidFailObserver = nil;
                }
                
                completion();
            }
        }];
        
        self.notificationCenterDidFailObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidFailRulesUpdate object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            if (strongSelf.notificationCenterDidUpdateObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                strongSelf.notificationCenterDidUpdateObserver = nil;
            }
            
            if (strongSelf.notificationCenterDidFailObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidFailObserver];
                strongSelf.notificationCenterDidFailObserver = nil;
            }
            
            completion();
        }];
    }
    
    [notificationCenter addOverrideRuleWithId:self.state.roomId
                                   conditions:@[@{@"kind":@"event_match", @"key":@"room_id", @"pattern":self.state.roomId}]
                                       notify:NO
                                        sound:NO
                                    highlight:NO];
}

- (void)removePushRule:(MXPushRule *)rule completion:(void (^)())completion
{
    MXNotificationCenter* notificationCenter = self.mxSession.notificationCenter;
    
    // Define notificationCenter observers if a completion block is defined.
    if (completion)
    {
        __weak typeof(self) weakSelf = self;
        
        self.notificationCenterDidUpdateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidUpdateRules object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            // Check whether the rule has been removed
            BOOL isRemoved = ([notificationCenter ruleById:rule.ruleId] == nil);
            if (isRemoved)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                
                if (strongSelf.notificationCenterDidUpdateObserver)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                    strongSelf.notificationCenterDidUpdateObserver = nil;
                }
                
                if (strongSelf.notificationCenterDidFailObserver)
                {
                    [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidFailObserver];
                    strongSelf.notificationCenterDidFailObserver = nil;
                }
                
                completion();
            }
        }];
        
        self.notificationCenterDidFailObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidFailRulesUpdate object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            if (strongSelf.notificationCenterDidUpdateObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                strongSelf.notificationCenterDidUpdateObserver = nil;
            }
            
            if (strongSelf.notificationCenterDidFailObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidFailObserver];
                strongSelf.notificationCenterDidFailObserver = nil;
            }
            
            completion();
        }];
    }
    
    [notificationCenter removeRule:rule];
}

- (void)enablePushRule:(MXPushRule *)rule completion:(void (^)())completion
{
    MXNotificationCenter* notificationCenter = self.mxSession.notificationCenter;
    
    // Define notificationCenter observers if a completion block is defined.
    if (completion)
    {
        __weak typeof(self) weakSelf = self;
        
        self.notificationCenterDidUpdateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidUpdateRules object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            // No way to check whether this notification concerns the push rule. Consider the change is applied.
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            if (strongSelf.notificationCenterDidUpdateObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                strongSelf.notificationCenterDidUpdateObserver = nil;
            }
            
            if (strongSelf.notificationCenterDidFailObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidFailObserver];
                strongSelf.notificationCenterDidFailObserver = nil;
            }
            
            completion();
        }];
        
        self.notificationCenterDidFailObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidFailRulesUpdate object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            if (strongSelf.notificationCenterDidUpdateObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidUpdateObserver];
                strongSelf.notificationCenterDidUpdateObserver = nil;
            }
            
            if (strongSelf.notificationCenterDidFailObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:strongSelf.notificationCenterDidFailObserver];
                strongSelf.notificationCenterDidFailObserver = nil;
            }
            
            completion();
        }];
    }
    
    [notificationCenter enableRule:rule isEnabled:YES];
}

- (void)setNotificationCenterDidFailObserver:(id)anObserver
{
    objc_setAssociatedObject(self, @selector(notificationCenterDidFailObserver), anObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)notificationCenterDidFailObserver
{
    return objc_getAssociatedObject(self, @selector(notificationCenterDidFailObserver));
}

- (void)setNotificationCenterDidUpdateObserver:(id)anObserver
{
    objc_setAssociatedObject(self, @selector(notificationCenterDidUpdateObserver), anObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)notificationCenterDidUpdateObserver
{
    return objc_getAssociatedObject(self, @selector(notificationCenterDidUpdateObserver));
}

@end
