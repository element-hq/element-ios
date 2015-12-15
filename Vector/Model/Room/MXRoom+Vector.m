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

- (BOOL)isSuperUser
{
    // Check whether the user has enough power to rename the room
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

@end
