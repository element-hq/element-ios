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

#import "RiotDesignValues.h"

#import "MXRoomSummary+Riot.h"

#import "MXTools.h"

#pragma mark - Defines & Constants

static const CGFloat kDirectRoomBorderColorAlpha = 0.75;
static const CGFloat kDirectRoomBorderWidth = 3.0;

@implementation RoomCollectionViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Round room image view
    [_roomAvatar.layer setCornerRadius:_roomAvatar.frame.size.width / 2];
    _roomAvatar.clipsToBounds = YES;
    
    // Initialize unread count badge
    [_missedNotifAndUnreadBadgeBgView.layer setCornerRadius:10];
    _missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = 0;
    
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
}

- (void)customizeCollectionViewCellRendering
{
    [super customizeCollectionViewCellRendering];
    
    self.roomTitle.textColor = kRiotPrimaryTextColor;
    self.roomTitle1.textColor = kRiotPrimaryTextColor;
    self.roomTitle2.textColor = kRiotPrimaryTextColor;
    self.missedNotifAndUnreadBadgeLabel.textColor = kRiotPrimaryBgColor;
    
    // Prepare direct room border
    CGColorRef directRoomBorderColor = CGColorCreateCopyWithAlpha(kRiotColorGreen.CGColor, kDirectRoomBorderColorAlpha);
    
    [self.directRoomBorderView.layer setCornerRadius:self.directRoomBorderView.frame.size.width / 2];
    self.directRoomBorderView.clipsToBounds = YES;
    self.directRoomBorderView.layer.borderColor = directRoomBorderColor;
    self.directRoomBorderView.layer.borderWidth = kDirectRoomBorderWidth;
    
    CFRelease(directRoomBorderColor);
    
    self.editionArrowView.backgroundColor = kRiotSecondaryBgColor;
    
    self.roomAvatar.defaultBackgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)render:(MXKCellData *)cellData
{
    // Hide by default missed notifications and unread widgets
    self.missedNotifAndUnreadBadgeBgView.hidden = YES;
    self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = 0;
    
    roomCellData = (id<MXKRecentCellDataStoring>)cellData;
    if (roomCellData)
    {
        // Report computed values as is
        self.roomTitle.hidden = NO;
        self.roomTitle.text = roomCellData.roomDisplayname;
        self.roomTitle1.hidden = YES;
        self.roomTitle2.hidden = YES;
        
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
            }
        }
        
        // Notify unreads and bing
        if (roomCellData.hasUnread)
        {
            if (0 < roomCellData.notificationCount)
            {
                self.missedNotifAndUnreadBadgeBgView.hidden = NO;
                self.missedNotifAndUnreadBadgeBgView.backgroundColor = roomCellData.highlightCount ? kRiotColorPinkRed : kRiotColorGreen;
                
                self.missedNotifAndUnreadBadgeLabel.text = roomCellData.notificationCountStringValue;
                [self.missedNotifAndUnreadBadgeLabel sizeToFit];
                
                self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = self.missedNotifAndUnreadBadgeLabel.frame.size.width + 18;
            }
            
            // Use bold font for the room title
            if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
            {
                self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
            }
            else
            {
                self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont boldSystemFontOfSize:13];
            }
        }
        else if (roomCellData.roomSummary.room.summary.membership == MXMembershipInvite)
        {
            self.missedNotifAndUnreadBadgeBgView.hidden = NO;
            self.missedNotifAndUnreadBadgeBgView.backgroundColor = kRiotColorPinkRed;
            
            self.missedNotifAndUnreadBadgeLabel.text = @"!";
            [self.missedNotifAndUnreadBadgeLabel sizeToFit];
            
            self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = self.missedNotifAndUnreadBadgeLabel.frame.size.width + 18;
            
            // Use bold font for the room title
            if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
            {
                self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
            }
            else
            {
                self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont boldSystemFontOfSize:13];
            }
        }
        else
        {
            // The room title is not bold anymore
            if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
            {
                self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
            }
            else
            {
                self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont systemFontOfSize:13];
            }
        }
        
        self.directRoomBorderView.hidden = !roomCellData.roomSummary.room.isDirect;
        
        self.encryptedRoomIcon.hidden = !roomCellData.roomSummary.isEncrypted;
        
        [roomCellData.roomSummary setRoomAvatarImageIn:self.roomAvatar];
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
    if (roomCellData)
    {
        return roomCellData.roomSummary.roomId;
    }
    return nil;
}

@end

