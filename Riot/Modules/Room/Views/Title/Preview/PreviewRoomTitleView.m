/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "PreviewRoomTitleView.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

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
    
    [self.leftButton setTitle:[VectorL10n decline] forState:UIControlStateNormal];
    [self.leftButton setTitle:[VectorL10n decline] forState:UIControlStateHighlighted];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.leftButton addGestureRecognizer:tap];
    self.leftButton.userInteractionEnabled = YES;
    
    [self.rightButton setTitle:[VectorL10n join] forState:UIControlStateNormal];
    [self.rightButton setTitle:[VectorL10n join] forState:UIControlStateHighlighted];
    
    [self.reportButton setTitle:[VectorL10n roomActionReport] forState:UIControlStateNormal];
    [self.reportButton setTitle:[VectorL10n roomActionReport] forState:UIControlStateHighlighted];
    
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.rightButton addGestureRecognizer:tap];
    self.rightButton.userInteractionEnabled = YES;
    
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.reportButton addGestureRecognizer:tap];
    self.reportButton.userInteractionEnabled = YES;
}

-(void)customizeViewRendering
{
    [super customizeViewRendering];

    // Use same color as navigation bar
    self.mainHeaderBackground.backgroundColor = ThemeService.shared.theme.baseColor;

    
    self.roomTopic.textColor = ThemeService.shared.theme.baseTextSecondaryColor;
    
    self.roomMembers.textColor = ThemeService.shared.theme.tintColor;
    
    self.previewLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.previewLabel.numberOfLines = 0;
    
    self.subNoticeLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    self.subNoticeLabel.numberOfLines = 0;
    
    self.bottomBorderView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    
    [self.leftButton.layer setCornerRadius:5];
    self.leftButton.clipsToBounds = YES;
    self.leftButton.backgroundColor = ThemeService.shared.theme.tintColor;
    
    [self.rightButton.layer setCornerRadius:5];
    self.rightButton.clipsToBounds = YES;
    self.rightButton.backgroundColor = ThemeService.shared.theme.tintColor;
    
    [self.reportButton setTitleColor:ThemeService.shared.theme.warningColor forState:UIControlStateNormal];
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    // Consider in priority the preview data (if any)
    if (self.roomPreviewData)
    {
        if (self.roomAvatarURL)
        {
            [self.roomAvatar setImageURI:self.roomAvatarURL
                                withType:nil
                     andImageOrientation:UIImageOrientationUp
                           toFitViewSize:self.roomAvatar.frame.size
                              withMethod:MXThumbnailingMethodCrop
                            previewImage:[MXKTools paintImage:AssetImages.placeholder.image
                                                    withColor:ThemeService.shared.theme.tintColor]
                            mediaManager:self.mxRoom.mxSession.mediaManager];
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
            NSString *numJoinedMembers = [@(self.roomPreviewData.numJoinedMembers) description];
            self.roomMembers.text = [VectorL10n roomTitleMembers:numJoinedMembers];
        }
        else if (self.roomPreviewData.numJoinedMembers == 1)
        {
            self.roomMembers.text = [VectorL10n roomTitleOneMember];
        }
        else
        {
            self.roomMembers.text = nil;
        }
        
        // Preview subtitle
        if (self.roomPreviewData.roomDataSource)
        {
            // Display the default preview subtitle in case of peeking
            self.subNoticeLabel.text = [VectorL10n roomPreviewSubtitle];
        }
        else
        {
            self.subNoticeLabel.text = nil;
        }
        
        if (self.roomPreviewData.emailInvitation.email)
        {
            // The user has been invited to join this room by email
            self.previewLabel.text = [VectorL10n roomPreviewInvitationFormat:self.roomPreviewData.emailInvitation.inviterName];
            
            // Warn the user that the email is not bound to his matrix account
            self.subNoticeLabel.text = [VectorL10n roomPreviewUnlinkedEmailWarning:self.roomPreviewData.emailInvitation.email];
        }
        else
        {
            // This is a room opened from a room link, or from the room search.
            NSString *roomName = self.roomPreviewData.roomName;
            if (!roomName)
            {
                roomName = [VectorL10n roomPreviewTryJoinAnUnknownRoomDefault];
            }
            else if (roomName.length > 20)
            {
                // Would have been nice to get the cropped string displayed by
                // self.displayNameTextField but the value is not accessible.
                // Cut it off by hand
                roomName = [NSString stringWithFormat:@"%@…",[roomName substringToIndex:20]];
            }

            self.previewLabel.text = [VectorL10n roomPreviewTryJoinAnUnknownRoom:roomName];
        }
    }
    else if (self.mxRoom)
    {
        [self.mxRoom.summary setRoomAvatarImageIn:self.roomAvatar];
        
        // Display room topic
        self.roomTopic.text = [MXTools stripNewlineCharacters:self.mxRoom.summary.topic];
        
        // Compute active members count, and look for the inviter
        MXWeakify(self);
        void (^onRoomMembers)(MXRoomMembers *roomMembers, BOOL allMembers) = ^void(MXRoomMembers *roomMembers, BOOL allMembers)
        {
            MXStrongifyAndReturnIfNil(self);

            MXSession *mxSession = self.mxRoom.mxSession;
            MXRoomMember *myMember = [roomMembers memberWithUserId:mxSession.myUserId];
            NSString *inviterUserId = myMember.originalEvent.sender;
            NSString *inviter = [roomMembers memberName:inviterUserId];
            //  if not found, check the user in session
            if (inviter.length == 0)
            {
                inviter = [mxSession userWithUserId:inviterUserId].displayname;
            }
            //  if still not found, use the user ID
            if (inviter.length == 0)
            {
                inviter = inviterUserId;
            }
            
            // FIXME: Display members status when it will be available
            self.roomMembers.text = nil;
            //                    if (memberCount)
            //                    {
            //                        if (activeCount > 1)
            //                        {
            //                            self.roomMembers.text = [VectorL10n roomTitleMultipleActiveMembers:@(activeCount).stringValue :@(memberCount).stringValue];
            //                        }
            //                        else
            //                        {
            //                            self.roomMembers.text = [VectorL10n roomTitleOneActiveMember:@(activeCount).stringValue :@(memberCount).stringValue];
            //                        }
            //                    }
            //                    else
            //                    {
            //                        // Should not happen
            //                        self.roomMembers.text = nil;
            //                    }

            NSString *displayName = [inviter isEqualToString:inviterUserId] ? inviter : [NSString stringWithFormat:@"%@ (%@)", inviter, inviterUserId];
            self.previewLabel.text = [VectorL10n roomPreviewInvitationFormat:displayName];
        };

        [self.mxRoom members:^(MXRoomMembers *roomMembers) {
            onRoomMembers(roomMembers, YES);
        }lazyLoadedMembers:^(MXRoomMembers *lazyLoadedMembers) {
            onRoomMembers(lazyLoadedMembers, NO);
        } failure:^(NSError *error) {
            MXLogDebug(@"[PreviewRoomTitleView] refreshDisplay: Cannot get all room members");
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
    
    self.roomAvatar.defaultBackgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    
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
