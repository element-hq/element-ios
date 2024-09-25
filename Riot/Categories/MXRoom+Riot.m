/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXRoom+Riot.h"

#import "AvatarGenerator.h"
#import "MatrixKit.h"
#import "GeneratedInterface-Swift.h"
#import <objc/runtime.h>

@implementation MXRoom (Riot)

#pragma mark - Room tags

- (void)setRoomTag:(NSString*)tag completion:(void (^)(void))completion
{
    NSString* oldTag = nil;
    
    if (self.accountData.tags && self.accountData.tags.count)
    {
        oldTag = self.accountData.tags.allKeys[0];
    }
    
    // support only kMXRoomTagFavourite or kMXRoomTagLowPriority tags by now
    if (![tag isEqualToString:kMXRoomTagFavourite] && ![tag isEqualToString:kMXRoomTagLowPriority])
    {
        tag = nil;
    }
    
    NSString* tagOrder = [self.mxSession tagOrderToBeAtIndex:0 from:NSNotFound withTag:tag];
    
    MXLogDebug(@"[MXRoom+Riot] Update the room %@ tag from %@ to %@ with tag order %@", self.roomId, oldTag, tag, tagOrder);
    
    [self replaceTag:oldTag
               byTag:tag
           withOrder:tagOrder
             success: ^{
                 
                 if (completion)
                 {
                     completion();
                 }
                 
             } failure:^(NSError *error) {
                 
                 MXLogDebug(@"[MXRoom+Riot] Failed to update the tag %@ of room (%@)", tag, self.roomId);
                 NSString *userId = self.mxSession.myUser.userId;
                 
                 // Notify user
                 [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification
                                                                     object:error
                                                                   userInfo:userId ? @{kMXKErrorUserIdKey: userId} : nil];
                 
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
    if (rule && rule.enabled)
    {
        // Support for MSC3987: The dont_notify push rule action is deprecated.
        if (rule.actions.count == 0)
        {
            return true;
        }
        
        // Support deprecated dont_notify push rule action for compatibility purposes.
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
                        
                        if (key && pattern && [key isEqualToString:@"room_id"] && [pattern isEqualToString:self.roomId])
                        {
                            return true;
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
    if (rule && rule.enabled)
    {
        // Support for MSC3987: The dont_notify push rule action is deprecated.
        if (rule.actions.count == 0)
        {
            return true;
        }
        
        // Support deprecated dont_notify push rule action for compatibility purposes.
        for (MXPushRuleAction *ruleAction in rule.actions)
        {
            if (ruleAction.actionType == MXPushRuleActionTypeDontNotify)
            {
                return true;
            }
        }
    }
    
    return NO;
}

- (void)mute:(void (^)(void))completion
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
            MXLogDebug(@"[MXRoom+Riot] Request in progress: ignore push rule update");
            if (completion)
            {
                completion();
            }
            return;
        }
        
        // check if the user did not define one
        BOOL hasDontNotifyRule = NO;
        
        // Support for MSC3987: The dont_notify push rule action is deprecated.
        if (rule.actions.count == 0)
        {
            hasDontNotifyRule = YES;
        }
        else
        {
            // Support deprecated dont_notify push rule action for compatibility purposes.
            for (MXPushRuleAction *ruleAction in rule.actions)
            {
                if (ruleAction.actionType == MXPushRuleActionTypeDontNotify)
                {
                    hasDontNotifyRule = YES;
                    break;
                }
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

- (void)mentionsOnly:(void (^)(void))completion
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
            MXLogDebug(@"[MXRoom+Riot] Request in progress: ignore push rule update");
            if (completion)
            {
                completion();
            }
            return;
        }
        
        // check if the user did not define one
        BOOL hasDontNotifyRule = NO;
        
        // Support for MSC3987: The dont_notify push rule action is deprecated.
        if (rule.actions.count == 0)
        {
            hasDontNotifyRule = YES;
        }
        else
        {
            // Support deprecated dont_notify push rule action for compatibility purposes.
            for (MXPushRuleAction *ruleAction in rule.actions)
            {
                if (ruleAction.actionType == MXPushRuleActionTypeDontNotify)
                {
                    hasDontNotifyRule = YES;
                    break;
                }
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

- (void)allMessages:(void (^)(void))completion
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

- (void)encryptionTrustLevelForUserId:(NSString*)userId onComplete:(void (^)(UserEncryptionTrustLevel userEncryptionTrustLevel))onComplete
{
    if (self.mxSession.crypto)
    {
        [self.mxSession.crypto trustLevelSummaryForUserIds:@[userId] forceDownload:NO success:^(MXUsersTrustLevelSummary *usersTrustLevelSummary) {
            
            MXCrossSigningInfo *crossSigningInfo = [self.mxSession.crypto.crossSigning crossSigningKeysForUser:userId];
            EncryptionTrustLevel *encryption = [[EncryptionTrustLevel alloc] init];
            UserEncryptionTrustLevel userEncryptionTrustLevel = [encryption userTrustLevelWithCrossSigning:crossSigningInfo
                                                                                    trustedDevicesProgress:usersTrustLevelSummary.trustedDevicesProgress];
            onComplete(userEncryptionTrustLevel);
            
        } failure:^(NSError *error) {
            MXLogErrorDetails(@"[MXRoom+Riot] Error fetching trust level summary", error);
            onComplete(UserEncryptionTrustLevelUnknown);
        }];
    }
    else
    {
        onComplete(UserEncryptionTrustLevelNone);
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
            if ([rule.ruleId isEqualToString:self.roomId])
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
            if ([rule.ruleId isEqualToString:self.roomId])
            {
                return rule;
            }
        }
    }
    
    return nil;
}

- (void)addPushRuleToMentionsOnly:(void (^)(void))completion
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
    
    [notificationCenter addRoomRule:self.roomId
                             notify:NO
                              sound:NO
                          highlight:NO];
}

- (void)addPushRuleToMute:(void (^)(void))completion
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
    
    [notificationCenter addOverrideRuleWithId:self.roomId
                                   conditions:@[@{@"kind":@"event_match", @"key":@"room_id", @"pattern":self.roomId}]
                                       notify:NO
                                        sound:NO
                                    highlight:NO];
}

- (void)removePushRule:(MXPushRule *)rule completion:(void (^)(void))completion
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

- (void)enablePushRule:(MXPushRule *)rule completion:(void (^)(void))completion
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
    
    [notificationCenter enableRule:rule isEnabled:YES completion:nil];
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
