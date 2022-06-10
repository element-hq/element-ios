/*
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

#import "RoomCollectionViewCell.h"

#import "AvatarGenerator.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "MXRoomSummary+Riot.h"
#import "MXRoom+Riot.h"

#import "MXTools.h"

@implementation RoomCollectionViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Disable the user interaction on the room avatar.
    self.roomAvatar.userInteractionEnabled = NO;
    
    // define arrow mask
    CAShapeLayer *arrowMaskLayer = [[CAShapeLayer alloc] init];
    arrowMaskLayer.frame = self.editionArrowView.bounds;
    CGSize viewSize = self.editionArrowView.frame.size;
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(0, viewSize.height)]; // arrow left bottom point
    [path addLineToPoint:CGPointMake(viewSize.width / 2, 0)]; // arrow head
    [path addLineToPoint:CGPointMake(viewSize.width, viewSize.height)]; // arrow right bottom point
    [path closePath]; // arrow top side
    arrowMaskLayer.path = path.CGPath;
    self.editionArrowView.layer.mask = arrowMaskLayer;
    
    self.isAccessibilityElement = YES;
}

- (void)customizeCollectionViewCellRendering
{
    [super customizeCollectionViewCellRendering];
    
    self.roomTitle.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.roomTitle1.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.roomTitle2.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.presenceIndicatorView.borderColor = ThemeService.shared.theme.backgroundColor;
    
    self.editionArrowView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    
    self.roomAvatar.defaultBackgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.roomAvatar.layer setCornerRadius:self.roomAvatar.frame.size.width / 2.0];
    [self.roomAvatar setClipsToBounds: YES];
}

- (void)render:(MXKCellData *)cellData
{
    // Hide by default missed notifications and unread widgets
    self.badgeLabel.hidden = YES;
    
    roomCellData = (id<MXKRecentCellDataStoring>)cellData;
    if (roomCellData)
    {
        // Report computed values as is
        self.roomTitle.hidden = NO;
        self.roomTitle.text = roomCellData.roomDisplayname;
        self.roomTitle1.hidden = YES;
        self.roomTitle2.hidden = YES;
        
        NSMutableString *accessibilityLabel = [self.roomTitle.text mutableCopy];
        
        // Check whether the room display name is an alias to keep visible the HS.
        if ([MXTools isMatrixRoomAlias:roomCellData.roomDisplayname])
        {
            NSRange range = [roomCellData.roomDisplayname rangeOfString:@":" options:NSBackwardsSearch];
            if (range.location != NSNotFound)
            {
                self.roomTitle.hidden = YES;
                self.roomTitle1.hidden = NO;
                self.roomTitle1.text = [roomCellData.roomDisplayname substringToIndex:range.location + 1];
                self.roomTitle2.hidden = NO;
                self.roomTitle2.text = [roomCellData.roomDisplayname substringFromIndex:range.location + 1];
                accessibilityLabel = [[NSString stringWithFormat:@"%@, %@", self.roomTitle1.text, self.roomTitle2.text] mutableCopy];
            }
        }
        
        // Notify unreads and bing
        if (roomCellData.roomSummary.membership == MXMembershipInvite
                 || roomCellData.roomSummary.sentStatus != MXRoomSummarySentStatusOk)
        {
            self.badgeLabel.hidden = NO;
            self.badgeLabel.badgeColor = ThemeService.shared.theme.noticeColor;
            self.badgeLabel.text = @"!";

            // Use bold font for the room title
            self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        }
        else if (roomCellData.hasUnread)
        {
            if (0 < roomCellData.notificationCount)
            {
                self.badgeLabel.hidden = NO;
                self.badgeLabel.badgeColor = roomCellData.highlightCount ? ThemeService.shared.theme.noticeColor : ThemeService.shared.theme.noticeSecondaryColor;
                self.badgeLabel.text = roomCellData.notificationCountStringValue;
                
                NSUInteger count = roomCellData.notificationCount;
                NSString *newMessagesLabel = count == 1 ? [VectorL10n roomNewMessageNotification:count] : [VectorL10n roomNewMessagesNotification:count];
                [accessibilityLabel appendFormat:@", %@", newMessagesLabel];
            }
            
            // Use bold font for the room title
            self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        }
        else
        {
            // The room title is not bold anymore            
            self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
            
        }
        
        self.accessibilityLabel = accessibilityLabel;
        
        [self.roomAvatar vc_setRoomAvatarImageWith:roomCellData.avatarUrl
                                            roomId:roomCellData.roomIdentifier
                                       displayName:roomCellData.roomDisplayname
                                      mediaManager:roomCellData.mxSession.mediaManager];

        if (roomCellData.directUserId)
        {
            [self.presenceIndicatorView configureWithUserId:roomCellData.directUserId presence:roomCellData.presence];
        }
        else
        {
            [self.presenceIndicatorView stopListeningPresenceUpdates];
        }
    }
}

- (MXKCellData*)renderedCellData
{
    return roomCellData;
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 115;
}

+ (CGSize)defaultCellSize
{
    return CGSizeMake(80, 115);
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self.presenceIndicatorView stopListeningPresenceUpdates];

    // Remove all gesture recognizers
    while (self.gestureRecognizers.count)
    {
        [self removeGestureRecognizer:self.gestureRecognizers[0]];
    }
    self.tag = -1;
    self.collectionViewTag = -1;
    
    self.editionArrowView.hidden = YES;
    
    roomCellData = nil;
}

- (NSString*)roomId
{
    return roomCellData.roomIdentifier;
}

@end

