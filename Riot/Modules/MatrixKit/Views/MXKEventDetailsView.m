/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2018 New Vector Ltd
 
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

#import "MXKEventDetailsView.h"

#import "NSBundle+MatrixKit.h"

#import "MXKConstants.h"

#import "MXKSwiftHeader.h"

@interface MXKEventDetailsView ()
{
    /**
     The displayed event
     */
    MXEvent *mxEvent;
    
    /**
     The matrix session.
     */
    MXSession *mxSession;
}
@end

@implementation MXKEventDetailsView

+ (UINib *)nib
{
    // Check whether a nib file is available
    NSBundle *mainBundle = [NSBundle mxk_bundleForClass:self.class];
    
    NSString *path = [mainBundle pathForResource:NSStringFromClass([self class]) ofType:@"nib"];
    if (path)
    {
        return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:mainBundle];
    }
    return [UINib nibWithNibName:NSStringFromClass([MXKEventDetailsView class]) bundle:[NSBundle mxk_bundleForClass:[MXKEventDetailsView class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Localize string
    [_redactButton setTitle:[VectorL10n redact] forState:UIControlStateNormal];
    [_redactButton setTitle:[VectorL10n redact] forState:UIControlStateHighlighted];
    [_closeButton setTitle:[VectorL10n close] forState:UIControlStateNormal];
    [_closeButton setTitle:[VectorL10n close] forState:UIControlStateHighlighted];
}

- (instancetype)initWithEvent:(MXEvent*)event andMatrixSession:(MXSession*)session
{
    self = [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
    if (self)
    {
        mxEvent = event;
        mxSession = session;
        
        [self setTranslatesAutoresizingMaskIntoConstraints: NO];
        
        // Disable redact button by default
        _redactButton.enabled = NO;
        
        if (mxEvent)
        {
            NSMutableDictionary *eventDict = [NSMutableDictionary dictionaryWithDictionary:mxEvent.JSONDictionary];
            
            // Remove event type added by SDK
            [eventDict removeObjectForKey:@"event_type"];
            // Remove null values and empty dictionaries
            for (NSString *key in eventDict.allKeys)
            {
                if ([[eventDict objectForKey:key] isEqual:[NSNull null]])
                {
                    [eventDict removeObjectForKey:key];
                }
                else if ([[eventDict objectForKey:key] isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *dict = [eventDict objectForKey:key];
                    if (!dict.count)
                    {
                        [eventDict removeObjectForKey:key];
                    }
                    else
                    {
                        NSMutableDictionary *updatedDict = [NSMutableDictionary dictionaryWithDictionary:dict];
                        for (NSString *subKey in dict.allKeys)
                        {
                            if ([[dict objectForKey:subKey] isEqual:[NSNull null]])
                            {
                                [updatedDict removeObjectForKey:subKey];
                            }
                        }
                        [eventDict setObject:updatedDict forKey:key];
                    }
                }
            }
            
            // Set text view content
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventDict
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:&error];
            _textView.text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            // Check whether the user can redact this event
            // Do not allow to redact the event that enabled encryption (m.room.encryption)
            // because it breaks everything
            if (!mxEvent.isRedactedEvent && mxEvent.eventType != MXEventTypeRoomEncryption)
            {
                // Here the event has not been already redacted, check the user's power level
                MXRoom *mxRoom = [mxSession roomWithRoomId:mxEvent.roomId];
                if (mxRoom)
                {
                    MXWeakify(self);
                    [mxRoom state:^(MXRoomState *roomState) {
                        MXStrongifyAndReturnIfNil(self);

                        MXRoomPowerLevels *powerLevels = [roomState powerLevels];
                        NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self->mxSession.myUser.userId];
                        if (powerLevels.redact)
                        {
                            if (userPowerLevel >= powerLevels.redact)
                            {
                                self.redactButton.enabled = YES;
                            }
                        }
                        else if (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsMessage:kMXEventTypeStringRoomRedaction])
                        {
                            self.redactButton.enabled = YES;
                        }
                    }];
                }
            }
        }
        else
        {
            _textView.text = nil;
        }
        
        // Hide potential activity indicator
        [_activityIndicator stopAnimating];
    }
    
    return self;
}

- (void)dealloc
{
    mxEvent = nil;
    mxSession = nil;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == _redactButton)
    {
        MXRoom *mxRoom = [mxSession roomWithRoomId:mxEvent.roomId];
        if (mxRoom)
        {
            [_activityIndicator startAnimating];
            [mxRoom redactEvent:mxEvent.eventId reason:nil success:^{
                
                [self->_activityIndicator stopAnimating];
                [self removeFromSuperview];
                
            } failure:^(NSError *error) {
                
                MXLogDebug(@"[MXKEventDetailsView] Redact event (%@) failed", self->mxEvent.eventId);
                
                // Notify MatrixKit user
                NSString *myUserId = mxRoom.mxSession.myUser.userId;
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                
                [self->_activityIndicator stopAnimating];
                
            }];
        }
        
    }
    else if (sender == _closeButton)
    {
        [self removeFromSuperview];
    }
}

@end
