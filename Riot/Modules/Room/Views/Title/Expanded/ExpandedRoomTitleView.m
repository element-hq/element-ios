/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "ExpandedRoomTitleView.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "MXRoomSummary+Riot.h"

@implementation ExpandedRoomTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class])
                          bundle:[NSBundle bundleForClass:[self class]]];
}

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.roomTopic.textColor = ThemeService.shared.theme.baseTextSecondaryColor;
    self.roomMembers.textColor = ThemeService.shared.theme.tintColor;
    self.membersListIcon.tintColor = ThemeService.shared.theme.tintColor;
    self.addParticipantIcon.tintColor = ThemeService.shared.theme.tintColor;
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    if (self.mxRoom)
    {
        [self.mxRoom.summary setRoomAvatarImageIn:self.roomAvatar];
        
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
                    self.roomMembers.text = [VectorL10n roomTitleInviteMembers];
                }
                else
                {
                    if (activeCount > 1)
                    {
                        self.roomMembers.text = [VectorL10n roomTitleMultipleActiveMembers:@(activeCount).stringValue :@(memberCount).stringValue];
                    }
                    else
                    {
                        self.roomMembers.text = [VectorL10n roomTitleOneActiveMember:@(activeCount).stringValue :@(memberCount).stringValue];
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
            MXLogDebug(@"[ExpandedRoomTitleView] refreshDisplay: Cannot get all room members");
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
    
    self.roomAvatar.defaultBackgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    
    // Force the layout of subviews to update the position of 'bottomBorderView' which is used to define the actual height of the preview container.
    [self layoutIfNeeded];
}

@end
