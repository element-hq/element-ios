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

#import "PreviewRoomTitleView.h"

#import "RiotDesignValues.h"

#import "MXRoom+Riot.h"

@implementation PreviewRoomTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class])
                          bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.previewLabel.text = nil;
    self.subNoticeLabel.text = nil;
    
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateNormal];
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateHighlighted];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.leftButton addGestureRecognizer:tap];
    self.leftButton.userInteractionEnabled = YES;
    
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil) forState:UIControlStateNormal];
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil) forState:UIControlStateHighlighted];
    
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.rightButton addGestureRecognizer:tap];
    self.rightButton.userInteractionEnabled = YES;
}

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.mainHeaderBackground.backgroundColor = kRiotColorLightGrey;
    
    self.displayNameTextField.textColor = kRiotTextColorBlack;
    
    self.roomTopic.textColor = kRiotTextColorDarkGray;
    self.roomTopic.numberOfLines = 0;
    
    self.roomMembers.textColor = kRiotColorGreen;
    
    self.previewLabel.textColor = kRiotTextColorDarkGray;
    self.previewLabel.numberOfLines = 0;
    
    self.subNoticeLabel.textColor = kRiotTextColorGray;
    self.subNoticeLabel.numberOfLines = 0;
    
    self.bottomBorderView.backgroundColor = kRiotColorLightGrey;
    
    [self.leftButton.layer setCornerRadius:5];
    self.leftButton.clipsToBounds = YES;
    self.leftButton.backgroundColor = kRiotColorGreen;
    
    [self.rightButton.layer setCornerRadius:5];
    self.rightButton.clipsToBounds = YES;
    self.rightButton.backgroundColor = kRiotColorGreen;
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    // Consider in priority the preview data (if any)
    if (self.roomPreviewData)
    {
        // Room topic
        self.roomTopic.text = self.roomPreviewData.roomTopic;
        
        // Joined members count
        if (self.roomPreviewData.numJoinedMembers > 1)
        {
            self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_members", @"Vector", nil), @(self.roomPreviewData.numJoinedMembers)];
        }
        else if (self.roomPreviewData.numJoinedMembers == 1)
        {
            self.roomMembers.text = NSLocalizedStringFromTable(@"room_title_one_member", @"Vector", nil);
        }
        else
        {
            self.roomMembers.text = nil;
        }
        
        // Preview subtitle
        if (self.roomPreviewData.roomDataSource)
        {
            // Display the default preview subtitle in case of peeking
            self.subNoticeLabel.text = NSLocalizedStringFromTable(@"room_preview_subtitle", @"Vector", nil);
        }
        else
        {
            self.subNoticeLabel.text = nil;
        }
        
        if (self.roomPreviewData.emailInvitation.email)
        {
            // The user has been invited to join this room by email
            self.previewLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_preview_invitation_format", @"Vector", nil), self.roomPreviewData.emailInvitation.inviterName];
            
            // Warn the user that the email is not bound to his matrix account
            self.subNoticeLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_preview_unlinked_email_warning", @"Vector", nil), self.roomPreviewData.emailInvitation.email];
        }
        else
        {
            // This is a room opened from a room link, or from the room search.
            NSString *roomName = self.roomPreviewData.roomName;
            if (!roomName)
            {
                roomName = NSLocalizedStringFromTable(@"room_preview_try_join_an_unknown_room_default", @"Vector", nil);
            }
            self.previewLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_preview_try_join_an_unknown_room", @"Vector", nil), roomName];
        }
    }
    else if (self.mxRoom)
    {
        // The user is here invited to join a room (This invitation has been received from server sync)
        self.displayNameTextField.text = self.mxRoom.riotDisplayname;
        if (!self.displayNameTextField.text.length)
        {
            self.displayNameTextField.text = NSLocalizedStringFromTable(@"room_displayname_no_title", @"Vector", nil);
            self.displayNameTextField.textColor = kRiotTextColorGray;
        }
        else
        {
            self.displayNameTextField.textColor = kRiotTextColorBlack;
        }
        
        // Display room topic
        self.roomTopic.text = [MXTools stripNewlineCharacters:self.mxRoom.state.topic];
        
        // Compute active members count, and look for the inviter
        NSArray *members = self.mxRoom.state.members;
        NSUInteger activeCount = 0;
        NSUInteger memberCount = 0;
        NSString *inviter = nil;
        
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
                
                // Presently only one member is available from invited room data
                // This is the inviter
                inviter = mxMember.displayname.length ? mxMember.displayname : mxMember.userId;
            }
        }
        
        // FIXME: Display members status when it will be available
        self.roomMembers.text = nil;
//        if (memberCount)
//        {
//            if (activeCount > 1)
//            {
//                self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_multiple_active_members", @"Vector", nil), @(activeCount), @(memberCount)];
//            }
//            else
//            {
//                self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_one_active_member", @"Vector", nil), @(activeCount), @(memberCount)];
//            }
//        }
//        else
//        {
//            // Should not happen
//            self.roomMembers.text = nil;
//        }
        
        self.previewLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_preview_invitation_format", @"Vector", nil), inviter];
    }
    else
    {
        self.roomMembers.text = nil;
        self.roomTopic.text = nil;
        self.previewLabel.text = nil;
    }
    
    // Force the layout of subviews to update the position of 'bottomBorderView' which is used to define the actual height of the preview container.
    [self layoutIfNeeded];
}

@end
