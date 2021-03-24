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
#import "Riot-Swift.h"

#import "MXRoomSummary+Riot.h"
#import "MXRoom+Riot.h"

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
    
    self.roomTitle.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.roomTitle1.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.roomTitle2.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    // Prepare direct room border
    CGColorRef directRoomBorderColor = CGColorCreateCopyWithAlpha(ThemeService.shared.theme.tintColor.CGColor, kDirectRoomBorderColorAlpha);
    
    [self.directRoomBorderView.layer setCornerRadius:self.directRoomBorderView.frame.size.width / 2];
    self.directRoomBorderView.clipsToBounds = YES;
    self.directRoomBorderView.layer.borderColor = directRoomBorderColor;
    self.directRoomBorderView.layer.borderWidth = kDirectRoomBorderWidth;
    
    CFRelease(directRoomBorderColor);
    
    self.editionArrowView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    
    self.roomAvatar.defaultBackgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
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
        if (roomCellData.roomSummary.room.summary.membership == MXMembershipInvite
                 || roomCellData.roomSummary.room.sentStatus != RoomSentStatusOk)
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
            }
            
            // Use bold font for the room title
            self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        }
        else
        {
            // The room title is not bold anymore            
            self.roomTitle.font = self.roomTitle1.font = self.roomTitle2.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
            
        }
        
        self.directRoomBorderView.hidden = !roomCellData.roomSummary.room.isDirect;
        
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

