/*
 Copyright 2016 OpenMarket Ltd
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

#import "ExpandedRoomTitleView.h"

#import "RiotDesignValues.h"

#import "MXRoom+Vector.h"

@implementation ExpandedRoomTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class])
                          bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.displayNameTextField.textColor = kRiotTextColorBlack;
    self.roomTopic.textColor = kRiotTextColorDarkGray;
    self.roomMembers.textColor = kRiotColorGreen;
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    if (self.mxRoom)
    {
        self.displayNameTextField.text = self.mxRoom.vectorDisplayname;
        if (!self.displayNameTextField.text.length)
        {
            self.displayNameTextField.text = NSLocalizedStringFromTable(@"room_displayname_no_title", @"Vector", nil);
            self.displayNameTextField.textColor = kRiotTextColorGray;
        }
        else
        {
            self.displayNameTextField.textColor = kRiotTextColorBlack;
        }
        
        self.roomTopic.text = [MXTools stripNewlineCharacters:self.mxRoom.state.topic];
        
        // Compute active members count
        NSArray *members = [self.mxRoom.state membersWithMembership:MXMembershipJoin includeConferenceUser:NO];
        NSUInteger activeCount = 0;
        NSUInteger memberCount = 0;
        for (MXRoomMember *mxMember in members)
        {
            memberCount ++;

            // Get the user that corresponds to this member
            MXUser *user = [self.mxRoom.mxSession userWithUserId:mxMember.userId];
            // existing user ?
            if (user && user.presence == MXPresenceOnline)
            {
                activeCount ++;
            }
        }

        if (memberCount)
        {
            // Check whether the logged in user is alone in this room
            if (memberCount == 1 && self.mxRoom.state.membership == MXMembershipJoin)
            {
                self.roomMembers.text = NSLocalizedStringFromTable(@"room_title_invite_members", @"Vector", nil);
            }
            else
            {
                if (activeCount > 1)
                {
                    self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_multiple_active_members", @"Vector", nil), @(activeCount), @(memberCount)];
                }
                else
                {
                    self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_one_active_member", @"Vector", nil), @(activeCount), @(memberCount)];
                }
            }
        }
        else
        {
            // Should not happen
            self.roomMembers.text = nil;
        }
    }
    else
    {
        self.roomTopic.text = nil;
        self.roomMembers.text = nil;
    }
    
    // Force the layout of subviews to update the position of 'bottomBorderView' which is used to define the actual height of the preview container.
    [self layoutIfNeeded];
}

@end
