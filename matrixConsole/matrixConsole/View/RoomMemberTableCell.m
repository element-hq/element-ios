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
#import <MatrixKit/MXKMediaManager.h>

#import "RoomMemberTableCell.h"
#import "MatrixSDKHandler.h"

@interface RoomMemberTableCell () {
    NSString *roomMemberUserId;
    NSRange lastSeenRange;
    NSTimer* lastSeenTimer;
}

@end

@implementation RoomMemberTableCell

- (void)dealloc {
    roomMemberUserId = nil;
    
    [lastSeenTimer invalidate];
    lastSeenTimer = nil;
}

// returns the presence color
// nil if there is no valid one
- (UIColor*)getUserPresenceColor:(MXUser*)user {
    if (user) {
        return [[MatrixSDKHandler sharedHandler] getPresenceRingColor:user.presence];
    }
    
    return nil;
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

- (void)setPowerContainerValue:(CGFloat)progress {
    // no power level -> hide the pie
    if (0 == progress) {
        self.powerContainer.hidden = YES;
        return;
    }

    // display it
    self.powerContainer.hidden = NO;
    self.powerContainer.backgroundColor = [UIColor clearColor];
    
    if (!pieChartView) {
        pieChartView = [[MXKPieChartView alloc] initWithFrame:self.powerContainer.bounds];
        [self.powerContainer addSubview:pieChartView];
    }
    
    pieChartView.progress = progress;
}

- (void)setRoomMember:(MXRoomMember *)roomMember withRoom:(MXRoom *)room {
    if (lastSeenTimer) {
        [lastSeenTimer invalidate];
        lastSeenTimer = nil;
    }
    
    if (room && roomMember) {
        // Set the user info
        self.userLabel.text = [room.state memberName:roomMember.userId];
        
        // User thumbnail
        NSString *thumbnailURL = nil;
        if (roomMember.avatarUrl) {
            // Suppose this url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
            MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
            thumbnailURL = [mxHandler thumbnailURLForContent:roomMember.avatarUrl inViewSize:self.pictureView.frame.size withMethod:MXThumbnailingMethodCrop];
        }
        self.pictureView.mediaFolder = kMXKMediaManagerAvatarThumbnailFolder;
        [self.pictureView setImageURL:thumbnailURL withImageOrientation:UIImageOrientationUp andPreviewImage:[UIImage imageNamed:@"default-profile"]];
        
        // Round image view
        [self.pictureView.layer setCornerRadius:self.pictureView.frame.size.width / 2];
        self.pictureView.clipsToBounds = YES;
        
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

        // user info
        CGFloat powerLevel = 0;
        NSString* presenceText = nil;
        UIColor* thumbnailBorderColor = nil;
        
        // Customize banned and left (kicked) members
        if (roomMember.membership == MXMembershipLeave || roomMember.membership == MXMembershipBan) {
            self.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
            presenceText = (roomMember.membership == MXMembershipLeave) ? @"left" : @"banned";
        } else {
            self.backgroundColor = [UIColor whiteColor];
            
            powerLevel = [[MatrixSDKHandler sharedHandler] getPowerLevel:roomMember inRoom:room];

            // get the user presence and his thumbnail border color
            if (roomMember.membership == MXMembershipInvite) {
                thumbnailBorderColor = [UIColor lightGrayColor];
                presenceText = @"invited";
            } else {
                roomMemberUserId = roomMember.userId;
                
                // Get the user that corresponds to this member
                MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
                MXUser *user = [mxHandler.mxSession userWithUserId:roomMemberUserId];
                
                // existing user ?
                if (user) {
                    thumbnailBorderColor = [self getUserPresenceColor:user];
                    presenceText = [self getLastPresenceText:user];
                    if (presenceText) {
                        // Trigger a timer to update last seen information
                        lastSeenRange = NSMakeRange(self.userLabel.text.length + 2, presenceText.length);
                        lastSeenTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateLastSeen:) userInfo:self repeats:NO];
                    }
                }
            }
        }

        // display the power level pie
        [self setPowerContainerValue:powerLevel];
        
        // if the thumbnail is defined
        if (thumbnailBorderColor) {
            self.pictureView.layer.borderWidth = 2;
            self.pictureView.layer.borderColor = thumbnailBorderColor.CGColor;
        } else {
            // remove the border
            // else it draws black border
            self.pictureView.layer.borderWidth = 0;
        }

        // and the presence text (if any)
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
                                      [UIColor lightGrayColor], NSForegroundColorAttributeName, nil];
            
            // Create the attributed string (text + attributes)
            NSMutableAttributedString *attributedText =[[NSMutableAttributedString alloc] initWithString:self.userLabel.text attributes:attrs];
            [attributedText setAttributes:subAttrs range:range];
            
            // Set it in our UILabel and we are done!
            [self.userLabel setAttributedText:attributedText];
        }
    }
}

- (void)updateLastSeen:(id)sender {
    [lastSeenTimer invalidate];
    lastSeenTimer = nil;
    
    // Get the user that corresponds to this member
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    MXUser *user = [mxHandler.mxSession userWithUserId:roomMemberUserId];
    
    // existing user ?
    if (user) {
        NSString *presenceText = [self getLastPresenceText:user];
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.userLabel.attributedText];
        if (presenceText.length) {
            [attributedText replaceCharactersInRange:lastSeenRange withString:presenceText];
            // Trigger a timer to update last seen information
            lastSeenRange.length = presenceText.length;
            lastSeenTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateLastSeen:) userInfo:self repeats:NO];
        } else {
            // remove presence info
            lastSeenRange.location -= 1;
            lastSeenRange.length += 2;
            [attributedText deleteCharactersInRange:lastSeenRange];
        }
        [self.userLabel setAttributedText:attributedText];
    }
}
@end