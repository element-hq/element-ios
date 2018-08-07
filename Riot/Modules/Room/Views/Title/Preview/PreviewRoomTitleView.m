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

#import "MXRoomSummary+Riot.h"

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
    
    self.backgroundColor = kRiotPrimaryBgColor;
    self.mainHeaderBackground.backgroundColor = kRiotSecondaryBgColor;
    
    self.displayNameTextField.textColor = (self.mxRoom.summary.displayname.length ? kRiotPrimaryTextColor : kRiotSecondaryTextColor);
    
    self.roomTopic.textColor = kRiotTopicTextColor;
    
    self.roomMembers.textColor = kRiotColorGreen;
    
    self.previewLabel.textColor = kRiotTopicTextColor;
    self.previewLabel.numberOfLines = 0;
    
    self.subNoticeLabel.textColor = kRiotSecondaryTextColor;
    self.subNoticeLabel.numberOfLines = 0;
    
    self.bottomBorderView.backgroundColor = kRiotSecondaryBgColor;
    
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
        if (self.roomAvatarURL)
        {
            [self.roomAvatar setImageURL:self.roomAvatarURL withType:nil andImageOrientation:UIImageOrientationUp previewImage:[UIImage imageNamed:@"placeholder"]];
        }
        else
        {
            self.roomAvatar.image = self.roomAvatarPlaceholder;
        }
        
        // Room topic
        self.roomTopic.text = self.roomPreviewData.roomTopic;

        [UIView setAnimationsEnabled:NO];
        [self.roomTopic scrollRangeToVisible:NSMakeRange(0, 0)];
        [UIView setAnimationsEnabled:YES];
        
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
            else if (roomName.length > 20)
            {
                // Would have been nice to get the cropped string displayed by
                // self.displayNameTextField but the value is not accessible.
                // Cut it off by hand
                roomName = [NSString stringWithFormat:@"%@…",[roomName substringToIndex:20]];
            }

            self.previewLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_preview_try_join_an_unknown_room", @"Vector", nil), roomName];
        }
    }
    else if (self.mxRoom)
    {
        [self.mxRoom.summary setRoomAvatarImageIn:self.roomAvatar];
        
        // The user is here invited to join a room (This invitation has been received from server sync)
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
        
        // Display room topic
        self.roomTopic.text = [MXTools stripNewlineCharacters:self.mxRoom.summary.topic];
        
        // Compute active members count, and look for the inviter
        MXWeakify(self);
        void (^onRoomMembers)(MXRoomMembers *roomMembers, BOOL allMembers) = ^void(MXRoomMembers *roomMembers, BOOL allMembers)
        {
            MXStrongifyAndReturnIfNil(self);

            NSArray *members = roomMembers.members;
            NSUInteger activeCount = 0;
            NSUInteger memberCount = self.mxRoom.summary.membersCount.joined;
            NSString *inviter = nil;

            for (MXRoomMember *mxMember in members)
            {
                if (mxMember.membership == MXMembershipJoin)
                {
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
            //                    if (memberCount)
            //                    {
            //                        if (activeCount > 1)
            //                        {
            //                            self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_multiple_active_members", @"Vector", nil), @(activeCount), @(memberCount)];
            //                        }
            //                        else
            //                        {
            //                            self.roomMembers.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_title_one_active_member", @"Vector", nil), @(activeCount), @(memberCount)];
            //                        }
            //                    }
            //                    else
            //                    {
            //                        // Should not happen
            //                        self.roomMembers.text = nil;
            //                    }

            self.previewLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_preview_invitation_format", @"Vector", nil), inviter];
        };

        [self.mxRoom members:^(MXRoomMembers *roomMembers) {
            onRoomMembers(roomMembers, YES);
        }lazyLoadedMembers:^(MXRoomMembers *lazyLoadedMembers) {
            onRoomMembers(lazyLoadedMembers, NO);
        } failure:^(NSError *error) {
            NSLog(@"[PreviewRoomTitleView] refreshDisplay: Cannot get all room members");
        }];
    }
    else
    {
        self.roomAvatar.image = self.roomAvatarPlaceholder;
        
        self.roomMembers.text = nil;
        self.roomTopic.text = nil;
        self.previewLabel.text = nil;
    }
    
    // Round image view for thumbnail
    self.roomAvatar.layer.cornerRadius = self.roomAvatar.frame.size.width / 2;
    self.roomAvatar.clipsToBounds = YES;
    
    self.roomAvatar.defaultBackgroundColor = kRiotSecondaryBgColor;
    
    // Force the layout of subviews to update the position of 'bottomBorderView' which is used to define the actual height of the preview container.
    [self layoutIfNeeded];
}

- (void)setRoomAvatarURL:(NSString *)roomAvatarURL
{
    _roomAvatarURL = roomAvatarURL;
    
    [self refreshDisplay];
}

- (void)setRoomAvatarPlaceholder:(UIImage *)roomAvatarPlaceholder
{
    _roomAvatarPlaceholder = roomAvatarPlaceholder;
    
    [self refreshDisplay];
}

@end
