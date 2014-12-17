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

#import "RoomMemberTableCell.h"
#import "MatrixHandler.h"

@implementation RoomMemberTableCell

// returns the presence color
- (UIColor*) getUserPresenceColor:(MXUser*) user
{
    switch (user.presence) {
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
            return [UIColor clearColor];
    }
}

- (NSString*)getLastPresenceText:(MXUser*)user {

    NSString* presenceText = nil;
    
    // Prepare last active ago string
    NSUInteger lastActiveAgoInSec = user.lastActiveAgo / 1000;
    if (lastActiveAgoInSec < 60) {
        presenceText = [NSString stringWithFormat:@"%lus", (unsigned long)lastActiveAgoInSec];
    } else if (lastActiveAgoInSec < 3600) {
        presenceText = [NSString stringWithFormat:@"%lum", (unsigned long)(lastActiveAgoInSec / 60)];
    } else if (lastActiveAgoInSec < 86400) {
        presenceText = [NSString stringWithFormat:@"%luh", (unsigned long)(lastActiveAgoInSec / 3600)];
    } else {
        presenceText = [NSString stringWithFormat:@"%lud", (unsigned long)(lastActiveAgoInSec / 86400)];
    }
    
    // Check presence
    switch (user.presence) {
        case MXPresenceOffline: {
            presenceText = @"offline";
            break;
        }
        case MXPresenceHidden:
        case MXPresenceUnknown:
        case MXPresenceFreeForChat: {
            presenceText = nil;
            break;
        }
        case MXPresenceOnline:
        case MXPresenceUnavailable:
        default:
            break;
    }
    
    return presenceText;
}

- (void)setRoomMember:(MXRoomMember *)roomMember withRoom:(MXRoom *)room {
    if (room && roomMember) {
        
        // set the user info
        self.userLabel.text = [room.state memberName:roomMember.userId];
        
        // user
        self.pictureView.placeholder = @"default-profile";
        self.pictureView.imageURL = roomMember.avatarUrl;
        
        // Round image view
        [self.pictureView.layer setCornerRadius:self.pictureView.frame.size.width / 2];
        self.pictureView.clipsToBounds = YES;
        self.pictureView.layer.borderWidth = 2;
        
        // Shade invited users
        if (roomMember.membership == MXMembershipInvite) {
            for (UIView *view in self.subviews) {
                view.alpha = 0.3;
            }
        } else {
            for (UIView *view in self.subviews) {
                view.alpha = 1;
            }
        }
        
        NSString* presenceText = nil;
        
        
        // Customize banned and left (kicked) members
        if (roomMember.membership == MXMembershipLeave || roomMember.membership == MXMembershipBan) {
            self.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
            presenceText = (roomMember.membership == MXMembershipLeave) ? @"left" : @"banned";
        } else {
            self.backgroundColor = [UIColor whiteColor];
            
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
            //self.userPowerLevel.progress = maxLevel ? userPowerLevelFloat / maxLevel : 1;
            
            if (roomMember.membership == MXMembershipInvite) {
                self.pictureView.layer.borderColor = [UIColor lightGrayColor].CGColor;
                presenceText = @"invited";
            } else {
                // Get the user that corresponds to this member
                MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
                MXUser *user = [mxHandler.mxSession userWithUserId:roomMember.userId];
                
                self.pictureView.layer.borderColor = [self getUserPresenceColor:user].CGColor;
                presenceText = [self getLastPresenceText:user];
            }
        }
        
        
        if (presenceText) {
            NSString* extraText = [NSString stringWithFormat:@"(%@)", presenceText];
            self.userLabel.text = [NSString stringWithFormat:@"%@ %@", self.userLabel.text, extraText];
            
            NSRange range = [self.userLabel.text rangeOfString:extraText];
            UIFont* font = self.userLabel.font;
            
            // Create the attributes
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   font, NSFontAttributeName,
                                   self.userLabel.textColor, NSForegroundColorAttributeName, nil];
            
            NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                      font, NSFontAttributeName,
                                      [UIColor grayColor], NSForegroundColorAttributeName, nil];
            
            // Create the attributed string (text + attributes)
            NSMutableAttributedString *attributedText =[[NSMutableAttributedString alloc] initWithString:self.userLabel.text attributes:attrs];
            [attributedText setAttributes:subAttrs range:range];
            
            // Set it in our UILabel and we are done!
            [self.userLabel setAttributedText:attributedText];
        }
    }
}
@end