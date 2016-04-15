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

#import "PreviewRoomTitleView.h"

#import "VectorDesignValues.h"

#import "MXRoom+Vector.h"

@implementation PreviewRoomTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class])
                          bundle:[NSBundle bundleForClass:[self class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.displayNameTextField.textColor = kVectorTextColorBlack;
    self.roomMembers.textColor = kVectorColorGreen;
    
    self.invitationLabel.textColor = kVectorTextColorDarkGray;
    self.invitationLabel.numberOfLines = 0;
    self.subInvitationLabel.text = nil;
    
    self.subInvitationLabel.textColor = kVectorTextColorGray;
    self.subInvitationLabel.numberOfLines = 0;
    
    self.subInvitationLabel.text = nil;// FIXME: Use NSLocalizedStringFromTable(@"room_preview_subtitle", @"Vector", nil);
    
    self.bottomBorderView.backgroundColor = kVectorColorLightGrey;
    
    [self.leftButton.layer setCornerRadius:5];
    self.leftButton.clipsToBounds = YES;
    self.leftButton.backgroundColor = kVectorColorGreen;
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil) forState:UIControlStateNormal];
    [self.leftButton setTitle:NSLocalizedStringFromTable(@"join", @"Vector", nil) forState:UIControlStateHighlighted];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.leftButton addGestureRecognizer:tap];
    self.leftButton.userInteractionEnabled = YES;
    
    [self.rightButton.layer setCornerRadius:5];
    self.rightButton.clipsToBounds = YES;
    self.rightButton.backgroundColor = kVectorColorGreen;
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateNormal];
    [self.rightButton setTitle:NSLocalizedStringFromTable(@"decline", @"Vector", nil) forState:UIControlStateHighlighted];
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.rightButton addGestureRecognizer:tap];
    self.rightButton.userInteractionEnabled = YES;
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
            self.displayNameTextField.textColor = kVectorTextColorGray;
        }
        else
        {
            self.displayNameTextField.textColor = kVectorTextColorBlack;
        }
        
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
                
                // Presently only one member is available from invited rom data
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
//                self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_multiple_active_members", @"Vector", nil), activeCount, memberCount];
//            }
//            else
//            {
//                self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_one_active_member", @"Vector", nil), activeCount, memberCount];
//            }
//        }
//        else
//        {
//            // Should not happen
//            self.roomMembers.text = nil;
//        }
        
        self.invitationLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_preview_invitation_format", @"Vector", nil), inviter];
    }
    else if (self.roomPreviewData)
    {
        self.displayNameTextField.text = self.roomPreviewData.roomName;
        self.roomMembers.text = nil;

        if (self.roomPreviewData.emailInvitation.email)
        {
            self.invitationLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_preview_invitation_format", @"Vector", nil), self.roomPreviewData.emailInvitation.inviterName];
        }
        else
        {
            // This is a room opened from a room link
            NSString *roomName = self.roomPreviewData.roomName;
            if (!roomName)
            {
                roomName = NSLocalizedStringFromTable(@"room_preview_try_join_an_unknown_room_default", @"Vector", nil);
            }
            self.invitationLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_preview_try_join_an_unknown_room", @"Vector", nil), roomName];
        }
    }
    else
    {
        self.roomMembers.text = nil;
        self.invitationLabel.text = nil;
    }
}

- (void)setRoomPreviewData:(RoomPreviewData *)roomPreviewData
{
    _roomPreviewData = roomPreviewData;
}

@end
