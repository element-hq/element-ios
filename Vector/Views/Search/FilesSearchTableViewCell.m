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

#import "FilesSearchTableViewCell.h"

#import "VectorDesignValues.h"

@implementation FilesSearchTableViewCell
@synthesize delegate, mxkCellData;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.title.textColor = kVectorTextColorBlack;
    
    self.message.textColor = kVectorTextColorGray;
    
    self.date.tintColor = kVectorTextColorGray;
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
            self.date.text = [bubbleData.eventFormatter dateStringFromEvent:bubbleData.attachment.event withTime:NO];
            self.message.text = bubbleData.senderDisplayName;
            
            self.attachmentImageView.image = nil;
            self.attachmentImageView.backgroundColor = [UIColor clearColor];
            
            if (bubbleData.isAttachmentWithThumbnail)
            {
                // Set attached media folders
                self.attachmentImageView.mediaFolder = bubbleData.roomId;
                
                NSString *mimetype = nil;
                if (bubbleData.attachment.thumbnailInfo)
                {
                    mimetype = bubbleData.attachment.thumbnailInfo[@"mimetype"];
                }
                else if (bubbleData.attachment.contentInfo)
                {
                    mimetype = bubbleData.attachment.contentInfo[@"mimetype"];
                }
                
                NSString *url = bubbleData.attachment.thumbnailURL;
                
                UIImage *preview = nil;
                if (bubbleData.attachment.previewURL)
                {
                    NSString *cacheFilePath = [MXMediaManager cachePathForMediaWithURL:bubbleData.attachment.previewURL andType:mimetype inFolder:self.attachmentImageView.mediaFolder];
                    preview = [MXMediaManager loadPictureFromFilePath:cacheFilePath];
                }
                
                if (url.length || preview)
                {
                    self.attachmentImageView.enableInMemoryCache = YES;
                    [self.attachmentImageView setImageURL:url withType:mimetype andImageOrientation:bubbleData.attachment.thumbnailOrientation previewImage:preview];
                    
                    self.attachmentImageView.backgroundColor = [UIColor whiteColor];
                }
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
            image = [UIImage imageNamed:@"file_photo_icon"];
            break;
        case MXKAttachmentTypeAudio:
            image = [UIImage imageNamed:@"file_audio_icon"];
            break;
        case MXKAttachmentTypeVideo:
            image = [UIImage imageNamed:@"file_video_icon"];
            break;
        case MXKAttachmentTypeFile:
            image = [UIImage imageNamed:@"file_doc_icon"];
            break;
        default:
            break;
    }
    
    return image;
}


@end
