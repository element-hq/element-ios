/*
 Copyright 2015 OpenMarket Ltd
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

#import "RecentTableViewCell.h"

#import "AvatarGenerator.h"

#import "MXEvent.h"
#import "MXRoom+Riot.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "MXRoomSummary+Riot.h"
#import "UIKit/UIKit.h"

@implementation RecentTableViewCell

#pragma mark - Class methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Initialize unread count badge
    [_missedNotifAndUnreadBadgeBgView.layer setCornerRadius:10];
    _missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = 0;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.contentView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.roomTitle.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.lastEventDescription.textColor = ThemeService.shared.theme.textSecondaryColor;
    self.lastEventDate.textColor = ThemeService.shared.theme.textSecondaryColor;
    self.missedNotifAndUnreadBadgeLabel.textColor = ThemeService.shared.theme.baseTextPrimaryColor;
    self.presenceIndicatorView.borderColor = ThemeService.shared.theme.backgroundColor;
    
    self.roomAvatar.defaultBackgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    [_roomAvatar.layer setCornerRadius:_roomAvatar.frame.size.width / 2];
    _roomAvatar.clipsToBounds = YES;
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (void)render:(MXKCellData *)cellData
{
    // Hide by default missed notifications and unread widgets
    self.missedNotifAndUnreadIndicator.hidden = YES;
    self.missedNotifAndUnreadBadgeBgView.hidden = YES;
    self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = 0;
    self.missedNotifAndUnreadBadgeLabel.text = @"";
    
    roomCellData = (id<MXKRecentCellDataStoring>)cellData;
    if (roomCellData)
    {
        NSString *text = roomCellData.roomDisplayname;
        NSString *placeholder = @"[TG]";
        NSString *dollarPlaceHolder = @"$";

        if ([text containsString:placeholder]) {
            // Replace "[TG]" with a placeholder character (e.g., a space) to maintain spacing
            text = [text stringByReplacingOccurrencesOfString:placeholder withString:@""];

            // Assuming image is a UIImage you want to set along with the text
            UIImage *originalImage = [UIImage imageNamed:@"chatimg"];

            // Adjust the size of the image
            CGSize imageSize = CGSizeMake(originalImage.size.width * 0.8, originalImage.size.height * 0.8); // Adjust the scaling factor as needed
            UIImage *scaledImage = [self resizeImage:originalImage toSize:imageSize];

            // Create an NSMutableAttributedString
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];

            UIImageView *imageView = [[UIImageView alloc] initWithImage:scaledImage];
            imageView.tintColor = [UIColor blueColor];

            // Create an NSTextAttachment with baseline alignment
            NSTextAttachment *imageAttachment = [[NSTextAttachment alloc] init];
            imageAttachment.image = scaledImage;

            // Get the font of the label to determine the baseline offset
            UIFont *font = self.roomTitle.font;
            CGFloat baselineOffset = (font.capHeight - scaledImage.size.height) / 2;

            // Set the baseline offset for proper alignment
            imageAttachment.bounds = CGRectMake(0, baselineOffset, scaledImage.size.width, scaledImage.size.height );

            NSAttributedString *imageAttributedString = [NSAttributedString attributedStringWithAttachment:imageAttachment];
            [attributedString appendAttributedString:imageAttributedString];

            // Append a space between image and text (adjust as needed)
            NSAttributedString *space = [[NSAttributedString alloc] initWithString:@""];
            [attributedString appendAttributedString:space];

            // Append the text to the attributed string
            NSAttributedString *textAttributedString = [[NSAttributedString alloc] initWithString:text];
            [attributedString appendAttributedString:textAttributedString];

            // Set the attributed string to the UILabel
            self.roomTitle.attributedText = attributedString;
        } else if ([text containsString:dollarPlaceHolder]) {
            // Replace "[TG]" with a placeholder character (e.g., a space) to maintain spacing
            text = [text stringByReplacingOccurrencesOfString:dollarPlaceHolder withString:@" "];

            // Assuming image is a UIImage you want to set along with the text
            UIImage *originalImage = [UIImage imageNamed:@"dollar"];

            // Adjust the size of the image
            CGSize imageSize = CGSizeMake(originalImage.size.width * 0.8, originalImage.size.height * 0.8); // Adjust the scaling factor as needed
            UIImage *scaledImage = [self resizeImage:originalImage toSize:imageSize];

            // Create an NSMutableAttributedString
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];

            UIImageView *imageView = [[UIImageView alloc] initWithImage:scaledImage];
            imageView.tintColor = [UIColor blueColor];

            // Create an NSTextAttachment with baseline alignment
            NSTextAttachment *imageAttachment = [[NSTextAttachment alloc] init];
            imageAttachment.image = scaledImage;

            // Get the font of the label to determine the baseline offset
            UIFont *font = self.roomTitle.font;
            CGFloat baselineOffset = (font.capHeight - scaledImage.size.height) / 2 - 2;

            // Set the baseline offset for proper alignment
            imageAttachment.bounds = CGRectMake(0, baselineOffset, scaledImage.size.width, scaledImage.size.height );

            NSAttributedString *imageAttributedString = [NSAttributedString attributedStringWithAttachment:imageAttachment];
            [attributedString appendAttributedString:imageAttributedString];

            // Append a space between image and text (adjust as needed)
            NSAttributedString *space = [[NSAttributedString alloc] initWithString:@""];
            [attributedString appendAttributedString:space];

            // Append the text to the attributed string
            NSAttributedString *textAttributedString = [[NSAttributedString alloc] initWithString:text];
            [attributedString appendAttributedString:textAttributedString];

            // Set the attributed string to the UILabel
            self.roomTitle.attributedText = attributedString;
        } else {
            self.roomTitle.text = text;
        }

      



        // Report computed values as is
//        self.roomTitle.text = roomCellData.roomDisplayname;
        self.lastEventDate.text = roomCellData.lastEventDate;
        
        // Manage lastEventAttributedTextMessage optional property
        if (!roomCellData.roomSummary.spaceChildInfo && [roomCellData respondsToSelector:@selector(lastEventAttributedTextMessage)])
        {
            // Attempt to correct the attributed string colors to match the current theme
            self.lastEventDescription.attributedText = [roomCellData.lastEventAttributedTextMessage fixForegroundColor];
        }
        else
        {
            self.lastEventDescription.text = roomCellData.lastEventTextMessage;
        }

        self.unsentImageView.hidden = roomCellData.roomSummary.sentStatus == MXRoomSummarySentStatusOk;
        self.lastEventDecriptionLabelTrailingConstraint.constant = self.unsentImageView.hidden ? 10 : 30;

        // Notify unreads and bing
        if (roomCellData.isRoomMarkedAsUnread)
        {
            self.missedNotifAndUnreadBadgeBgView.hidden = NO;
            self.missedNotifAndUnreadBadgeBgView.backgroundColor = ThemeService.shared.theme.tintColor;
            self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = 20;
        }
        else if (roomCellData.hasUnread)
        {
            self.missedNotifAndUnreadIndicator.hidden = NO;
            if (0 < roomCellData.notificationCount)
            {
                self.missedNotifAndUnreadIndicator.backgroundColor = roomCellData.highlightCount ? ThemeService.shared.theme.noticeColor : ThemeService.shared.theme.noticeSecondaryColor;

                self.missedNotifAndUnreadBadgeBgView.hidden = NO;
                self.missedNotifAndUnreadBadgeBgView.backgroundColor = self.missedNotifAndUnreadIndicator.backgroundColor;

                self.missedNotifAndUnreadBadgeLabel.text = roomCellData.notificationCountStringValue;
                [self.missedNotifAndUnreadBadgeLabel sizeToFit];

                self.missedNotifAndUnreadBadgeBgViewWidthConstraint.constant = self.missedNotifAndUnreadBadgeLabel.frame.size.width + 18;
            }
            else
            {
                self.missedNotifAndUnreadIndicator.backgroundColor = ThemeService.shared.theme.unreadRoomIndentColor;
            }

            // Use bold font for the room title
            self.roomTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
        }
        else
        {
            self.lastEventDate.textColor = ThemeService.shared.theme.textSecondaryColor;

            // The room title is not bold anymore
            self.roomTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        }

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
    else
    {
        self.lastEventDescription.text = @"";
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self.presenceIndicatorView stopListeningPresenceUpdates];
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 74;
}

@end
