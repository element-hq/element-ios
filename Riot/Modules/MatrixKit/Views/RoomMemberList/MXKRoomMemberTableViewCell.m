/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
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

#import "MXKRoomMemberTableViewCell.h"

@import MatrixSDK;

#import "MXKAccount.h"
#import "MXKImageView.h"
#import "MXKPieChartView.h"
#import "MXKRoomMemberCellDataStoring.h"
#import "MXKRoomMemberListDataSource.h"
#import "MXKTools.h"

#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@interface MXKRoomMemberTableViewCell ()
{
    NSRange lastSeenRange;
    
    MXKPieChartView* pieChartView;
}

@end

@implementation MXKRoomMemberTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.typingBadge.image = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_keyboard"];
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.pictureView.defaultBackgroundColor = [UIColor clearColor];
}

- (UIImage*)picturePlaceholder
{
    return [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"default-profile"];
}

- (void)render:(MXKCellData *)cellData
{
    // Sanity check: accept only object of MXKRoomMemberCellData classes or sub-classes
    NSParameterAssert([cellData isKindOfClass:[MXKRoomMemberCellData class]]);
    
    MXKRoomMemberCellData *memberCellData = (MXKRoomMemberCellData*)cellData;
    if (memberCellData)
    {
        mxSession = memberCellData.mxSession;
        memberId = memberCellData.roomMember.userId;
        
        self.userLabel.text = memberCellData.memberDisplayName;
        
        // Disable by default activity update mechanism (This is required in case of a reused cell).
        shouldUpdateActivityInfo = NO;
        
        // User thumbnail
        self.pictureView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder;
        self.pictureView.enableInMemoryCache = YES;
        // Consider here the member avatar is stored unencrypted on Matrix media repo
        [self.pictureView setImageURI:memberCellData.roomMember.avatarUrl
                             withType:nil
                  andImageOrientation:UIImageOrientationUp
                        toFitViewSize:self.pictureView.frame.size
                           withMethod:MXThumbnailingMethodCrop
                         previewImage:self.picturePlaceholder
                         mediaManager:mxSession.mediaManager];
        
        // Shade invited users
        if (memberCellData.roomMember.membership == MXMembershipInvite)
        {
            for (UIView *view in self.subviews)
            {
                view.alpha = 0.3;
            }
        }
        else
        {
            for (UIView *view in self.subviews)
            {
                view.alpha = 1;
            }
        }
        
        // Display the power level pie
        [self setPowerContainerValue:memberCellData.powerLevel];
        
        // Prepare presence string and thumbnail border color
        NSString* presenceText = nil;
        UIColor* thumbnailBorderColor = nil;
        
        // Customize banned and left (kicked) members
        if (memberCellData.roomMember.membership == MXMembershipLeave || memberCellData.roomMember.membership == MXMembershipBan)
        {
            self.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
            presenceText = (memberCellData.roomMember.membership == MXMembershipLeave) ? [VectorL10n membershipLeave] : [VectorL10n membershipBan];
        }
        else
        {
            self.backgroundColor = [UIColor whiteColor];
            
            // get the user presence and his thumbnail border color
            if (memberCellData.roomMember.membership == MXMembershipInvite)
            {
                thumbnailBorderColor = [UIColor lightGrayColor];
                presenceText = [VectorL10n membershipInvite];
            }
            else
            {
                // Get the user that corresponds to this member
                MXUser *user = [mxSession userWithUserId:memberId];
                // existing user ?
                if (user)
                {
                    thumbnailBorderColor = [MXKAccount presenceColor:user.presence];
                    presenceText = [self lastActiveTime];
                    // Keep last seen range to update it
                    lastSeenRange = NSMakeRange(self.userLabel.text.length + 2, presenceText.length);
                    shouldUpdateActivityInfo = (presenceText.length != 0);
                }
            }
        }
        
        // if the thumbnail is defined
        if (thumbnailBorderColor)
        {
            self.pictureView.layer.borderWidth = 2;
            self.pictureView.layer.borderColor = thumbnailBorderColor.CGColor;
        }
        else
        {
            // remove the border
            // else it draws black border
            self.pictureView.layer.borderWidth = 0;
        }
        
        // and the presence text (if any)
        if (presenceText)
        {
            NSString* extraText = [NSString stringWithFormat:@"(%@)", presenceText];
            self.userLabel.text = [NSString stringWithFormat:@"%@ %@", self.userLabel.text, extraText];
            
            NSRange range = [self.userLabel.text rangeOfString:extraText];
            UIFont* font = self.userLabel.font;
            
            // Create the attributes
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   font, NSFontAttributeName,
                                   self.userLabel.textColor, NSForegroundColorAttributeName, nil];
            
            NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                      font, NSFontAttributeName,
                                      [UIColor lightGrayColor], NSForegroundColorAttributeName, nil];
            
            // Create the attributed string (text + attributes)
            NSMutableAttributedString *attributedText =[[NSMutableAttributedString alloc] initWithString:self.userLabel.text attributes:attrs];
            [attributedText setAttributes:subAttrs range:range];
            
            // Set it in our UILabel and we are done!
            [self.userLabel setAttributedText:attributedText];
        }
        
        // Set typing badge visibility
        if (memberCellData.isTyping)
        {
            self.typingBadge.hidden = NO;
            [self.typingBadge.superview bringSubviewToFront:self.typingBadge];
        }
        else
        {
            self.typingBadge.hidden = YES;
        }
    }
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 50;
}

- (NSString*)lastActiveTime
{
    NSString* lastActiveTime = nil;
    
    // Get the user that corresponds to this member
    MXUser *user = [mxSession userWithUserId:memberId];
    if (user)
    {
        // Prepare last active ago string
        lastActiveTime = [MXKTools formatSecondsIntervalFloored:(user.lastActiveAgo / 1000)];
        
        // Check presence
        switch (user.presence)
        {
            case MXPresenceOffline:
            {
                lastActiveTime = [VectorL10n offline];
                break;
            }
            case MXPresenceUnknown:
            {
                lastActiveTime = nil;
                break;
            }
            case MXPresenceOnline:
            case MXPresenceUnavailable:
            default:
                break;
        }
        
    }
    
    return lastActiveTime;
}

- (void)setPowerContainerValue:(CGFloat)progress
{
    // no power level -> hide the pie
    if (0 == progress)
    {
        self.powerContainer.hidden = YES;
        return;
    }
    
    // display it
    self.powerContainer.hidden = NO;
    self.powerContainer.backgroundColor = [UIColor clearColor];
    
    if (!pieChartView)
    {
        pieChartView = [[MXKPieChartView alloc] initWithFrame:self.powerContainer.bounds];
        [self.powerContainer addSubview:pieChartView];
    }
    
    pieChartView.progress = progress;
}

- (void)updateActivityInfo
{
    // Check whether update is required.
    if (shouldUpdateActivityInfo)
    {
        NSString *lastSeen = [self lastActiveTime];
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.userLabel.attributedText];
        if (lastSeen.length)
        {
            [attributedText replaceCharactersInRange:lastSeenRange withString:lastSeen];
            
            // Update last seen range
            lastSeenRange.length = lastSeen.length;
        }
        else
        {
            // remove presence info
            lastSeenRange.location -= 1;
            lastSeenRange.length += 2;
            [attributedText deleteCharactersInRange:lastSeenRange];
            
            shouldUpdateActivityInfo = NO;
        }
        
        [self.userLabel setAttributedText:attributedText];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    [_pictureView.layer setCornerRadius:_pictureView.frame.size.width / 2];
    _pictureView.clipsToBounds = YES;
}

@end
