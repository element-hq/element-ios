/*
 Copyright 2016 OpenMarket Ltd
 
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

#import "VectorDesignValues.h"

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
    
    self.displayNameTextField.textColor = kVectorTextColorBlack;
    self.roomTopic.textColor = kVectorTextColorDarkGray;
    self.roomMembers.textColor = kVectorColorGreen;
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    if (self.mxRoom)
    {
        self.displayNameTextField.text = self.mxRoom.vectorDisplayname;
        
        self.roomTopic.text = self.mxRoom.state.topic;
        
        // Compute active members count
        NSArray *members = self.mxRoom.state.members;
        NSUInteger activeCount = 0;
        NSUInteger memberCount = 0;
        for (MXRoomMember *mxMember in members)
        {
            if (mxMember.membership == MXMembershipJoin)
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
            else if (mxMember.membership == MXMembershipJoin)
            {
                memberCount ++;
            }
        }
        
        if (memberCount)
        {
            if (activeCount > 1)
            {
                self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_multiple_active_members", @"Vector", nil), activeCount, memberCount];
            }
            else
            {
                self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_one_active_member", @"Vector", nil), activeCount, memberCount];
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
}

@end
