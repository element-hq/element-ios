/*
 Copyright 2016 OpenMarket Ltd
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

#import "FilesSearchTableViewCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation FilesSearchTableViewCell
@synthesize delegate, mxkCellData;

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.title.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    self.message.textColor = ThemeService.shared.theme.textSecondaryColor;
    
    self.date.tintColor = ThemeService.shared.theme.textSecondaryColor;
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 74;
}

- (void)render:(MXKCellData*)cellData
{    
    self.attachmentImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    if ([cellData conformsToProtocol:@protocol(MXKSearchCellDataStoring)])
    {
        [super render:cellData];
    }
    else if ([cellData isKindOfClass:[MXKRoomBubbleCellData class]])
    {
        MXKRoomBubbleCellData *bubbleData = (MXKRoomBubbleCellData*)cellData;
        mxkCellData = cellData;
        
        if (bubbleData.attachment)
        {
            self.title.text = bubbleData.attachment.originalFileName;
            
            // In case of attachment, the bubble data is composed by only one component.
            if (bubbleData.bubbleComponents.count)
            {
                MXKRoomBubbleComponent *component = bubbleData.bubbleComponents.firstObject;
                self.date.text = [bubbleData.eventFormatter dateStringFromEvent:component.event withTime:NO];
            }
            else
            {
                self.date.text = nil;
            }
            
            self.message.text = bubbleData.senderDisplayName;
            
            self.attachmentImageView.image = nil;
            self.attachmentImageView.backgroundColor = [UIColor clearColor];
            
            if (bubbleData.isAttachmentWithThumbnail)
            {
                self.attachmentImageView.backgroundColor = ThemeService.shared.theme.backgroundColor;
                [self.attachmentImageView setAttachmentThumb:bubbleData.attachment];
            }
            
            self.iconImage.image = [self attachmentIcon:bubbleData.attachment.type];
            
            // Disable any interactions defined in the cell
            // because we want [tableView didSelectRowAtIndexPath:] to be called
            self.contentView.userInteractionEnabled = NO;
        }
        else
        {
            self.title.text = nil;
            self.date.text = nil;
            self.message.text = @"";
            
            self.attachmentImageView.image = nil;
            self.iconImage.image = nil;
        }
    }
}

#pragma mark -

- (UIImage*)attachmentIcon: (MXKAttachmentType)type
{
    UIImage *image = nil;
    
    switch (type)
    {
        case MXKAttachmentTypeImage:
            image = AssetImages.filePhotoIcon.image;
            break;
        case MXKAttachmentTypeAudio:
            image = AssetImages.fileMusicIcon.image;
            break;
        case MXKAttachmentTypeVoiceMessage:
            image = AssetImages.fileMusicIcon.image;
            break;
        case MXKAttachmentTypeVideo:
            image = AssetImages.fileVideoIcon.image;
            break;
        case MXKAttachmentTypeFile:
            image = AssetImages.fileDocIcon.image;
            break;
        default:
            break;
    }
    
    return image;
}


@end
