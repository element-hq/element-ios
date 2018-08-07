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

#import "MXRoomSummary+Riot.h"

@implementation ExpandedRoomTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class])
                          bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.displayNameTextField.textColor = (self.mxRoom.summary.displayname.length ? kRiotPrimaryTextColor : kRiotSecondaryTextColor);
    self.roomTopic.textColor = kRiotTopicTextColor;
    self.roomMembers.textColor = kRiotColorGreen;
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    if (self.mxRoom)
    {
        [self.mxRoom.summary setRoomAvatarImageIn:self.roomAvatar];
        
        self.displayNameTextField.text = self.mxRoom.summary.displayname;
        if (!self.displayNameTextField.text.length)
        {
            self.displayNameTextField.text = NSLocalizedStringFromTable(@"room_displayname_no_title", @"Vector", nil);
            self.displayNameTextField.textColor = kRiotSecondaryTextColor;
        }
        else
        {
            self.displayNameTextField.textColor = kRiotPrimaryTextColor;
        }
        
        self.roomTopic.text = [MXTools stripNewlineCharacters:self.mxRoom.summary.topic];
        
        // Compute active members count
        MXWeakify(self);
        void (^onRoomMembers)(MXRoomMembers *roomMembers, BOOL allMembers) = ^void(MXRoomMembers *roomMembers, BOOL allMembers)
        {
            MXStrongifyAndReturnIfNil(self);

            NSArray *members = [roomMembers membersWithMembership:MXMembershipJoin includeConferenceUser:NO];
            NSUInteger activeCount = 0;
            NSUInteger memberCount = self.mxRoom.summary.membersCount.joined;
            for (MXRoomMember *mxMember in members)
            {
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
                if (memberCount == 1 && self.mxRoom.summary.membership == MXMembershipJoin)
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
        };

        [self.mxRoom members:^(MXRoomMembers *roomMembers) {
            onRoomMembers(roomMembers, YES);
        } lazyLoadedMembers:^(MXRoomMembers *lazyLoadedMembers) {
            onRoomMembers(lazyLoadedMembers, NO);
        } failure:^(NSError *error) {
            NSLog(@"[ExpandedRoomTitleView] refreshDisplay: Cannot get all room members");
        }];
    }
    else
    {
        self.roomAvatar.image = nil;
        
        self.roomTopic.text = nil;
        self.roomMembers.text = nil;
    }
    
    // Round image view for thumbnail
    self.roomAvatar.layer.cornerRadius = self.roomAvatar.frame.size.width / 2;
    self.roomAvatar.clipsToBounds = YES;
    
    self.roomAvatar.defaultBackgroundColor = kRiotSecondaryBgColor;
    
    // Force the layout of subviews to update the position of 'bottomBorderView' which is used to define the actual height of the preview container.
    [self layoutIfNeeded];
}

@end
