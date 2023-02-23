/*
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

#import "RoomSelectedStickerBubbleCell.h"

#import "RoomEncryptedDataBubbleCell.h"

#import "RoomIncomingAttachmentBubbleCell.h"
#import "RoomIncomingAttachmentWithoutSenderInfoBubbleCell.h"
#import "RoomIncomingAttachmentWithPaginationTitleBubbleCell.h"
#import "RoomIncomingEncryptedAttachmentBubbleCell.h"
#import "RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@implementation RoomSelectedStickerBubbleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // define arrow mask
    CAShapeLayer *arrowMaskLayer = [[CAShapeLayer alloc] init];
    arrowMaskLayer.frame = self.arrowView.bounds;
    CGSize viewSize = self.arrowView.frame.size;
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:CGPointMake(0, viewSize.height)]; // arrow left bottom point
    [path addLineToPoint:CGPointMake(viewSize.width / 2, 0)]; // arrow head
    [path addLineToPoint:CGPointMake(viewSize.width, viewSize.height)]; // arrow right bottom point
    [path closePath]; // arrow top side
    arrowMaskLayer.path = path.CGPath;
    self.arrowView.layer.mask = arrowMaskLayer;
    
    self.arrowView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    self.descriptionView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    [self.descriptionView.layer setCornerRadius:10];
}

- (void)render:(MXKCellData *)cellData
{
    [self prepareRender:cellData];
    
    if (bubbleData)
    {
        // Retrieve the component which stores the sticker (Only one component is handled by the bubble in case of sticker).
        MXKRoomBubbleComponent *component = bubbleData.bubbleComponents.firstObject;
        
        // Handle the pagination and the sender information
        // Look for the original cell class to extract the constraints value.
        Class<MXKCellRendering> modelCellViewClass = nil;
        if (bubbleData.shouldHideSenderInformation)
        {
            modelCellViewClass = bubbleData.isEncryptedRoom ? RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.class : RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class;
            
            self.paginationTitleView.hidden = YES;
            self.pictureView.hidden = YES;
            self.userNameLabel.hidden = YES;
            self.userNameTapGestureMaskView.userInteractionEnabled = NO;
        }
        else
        {
            if (bubbleData.isPaginationFirstBubble)
            {
                modelCellViewClass = bubbleData.isEncryptedRoom ? RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.class : RoomIncomingAttachmentWithPaginationTitleBubbleCell.class;
                
                self.paginationTitleView.hidden = NO;
                self.paginationLabel.text = [[bubbleData.eventFormatter dateStringFromDate:bubbleData.date withTime:NO] uppercaseString];
            }
            else
            {
                modelCellViewClass = bubbleData.isEncryptedRoom ? RoomIncomingEncryptedAttachmentBubbleCell.class : RoomIncomingAttachmentBubbleCell.class;
                
                self.paginationTitleView.hidden = YES;
            }
            
            // Hanlde sender avatar (Supposed his avatar is stored unencrypted on Matrix media repo)
            self.pictureView.hidden = NO;
            
            self.pictureView.enableInMemoryCache = YES;
            [self.pictureView setImageURI:bubbleData.senderAvatarUrl
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                            toFitViewSize:self.pictureView.frame.size
                               withMethod:MXThumbnailingMethodCrop
                             previewImage:bubbleData.senderAvatarPlaceholder ? bubbleData.senderAvatarPlaceholder : self.picturePlaceholder
                             mediaManager:bubbleData.mxSession.mediaManager];
            
            // Display sender's name except if the name appears in the displayed text (see emote and membership events)
            if (bubbleData.shouldHideSenderName == NO)
            {
                self.userNameLabel.text = bubbleData.senderDisplayName;
                self.userNameLabel.hidden = NO;
                self.userNameTapGestureMaskView.userInteractionEnabled = YES;
            }
            else
            {
                self.userNameLabel.hidden = YES;
                self.userNameTapGestureMaskView.userInteractionEnabled = NO;
            }
        }
        
        RoomTimelineConfiguration *timelineConfiguration = [RoomTimelineConfiguration shared];
        
        [timelineConfiguration.currentStyle.cellLayoutUpdater updateLayoutForSelectedStickerCell:self];
        
        // Retrieve the suitable content size for the attachment thumbnail
        CGSize contentSize = bubbleData.contentSize;
        // Update image view frame in order to center loading wheel (if any)
        CGRect frame = self.attachmentView.frame;
        frame.size.width = contentSize.width;
        frame.size.height = contentSize.height;
        self.attachmentView.frame = frame;
        // Retrieve the MIME type
        NSString *mimetype = nil;
        if (bubbleData.attachment.thumbnailInfo)
        {
            mimetype = bubbleData.attachment.thumbnailInfo[@"mimetype"];
        }
        else if (bubbleData.attachment.contentInfo)
        {
            mimetype = bubbleData.attachment.contentInfo[@"mimetype"];
        }
        
        // Display the sticker
        self.attachmentView.backgroundColor = [UIColor clearColor];
        [self.attachmentView setAttachmentThumb:bubbleData.attachment];
        
        // Set the description
        NSAttributedString *description = component.attributedTextMessage;
        if (description.length)
        {
            self.descriptionContainerView.hidden = NO;
            self.descriptionLabel.attributedText = description;
        }
        else
        {
            self.descriptionContainerView.hidden = YES;
        }
        
        // Adjust Attachment width constant
        self.attachViewWidthConstraint.constant = contentSize.width;
        
        // Handle the encryption view
        if (bubbleData.isEncryptedRoom)
        {
            // Set the right device info icon
            self.encryptionStatusView.hidden = NO;
            self.encryptionStatusView.image = [RoomEncryptedDataBubbleCell encryptionIconForBubbleComponent:component];
        }
        else
        {
            self.encryptionStatusView.hidden = YES;
        }
        
        // Hide by default the info container
        self.bubbleInfoContainer.hidden = YES;
        
        // Adjust the layout according to the original cell, the one used to display the sticker unselected.
        if ([modelCellViewClass nib])
        {
            MXKRoomBubbleTableViewCell* cell= (MXKRoomBubbleTableViewCell*)[[modelCellViewClass nib] instantiateWithOwner:nil options:nil].firstObject;
            
            if (cell.userNameLabel)
            {
                frame = cell.userNameLabel.frame;
                self.userNameLabelTopConstraint.constant = frame.origin.y;
            }
            frame = cell.attachmentView.frame;
            self.attachViewLeadingConstraint.constant = frame.origin.x;
            self.attachViewTopConstraint.constant = cell.attachViewTopConstraint.constant;
            self.attachViewBottomConstraint.constant = cell.attachViewBottomConstraint.constant;
            self.bubbleInfoContainerTopConstraint.constant = cell.bubbleInfoContainerTopConstraint.constant;
        }
    }
}

+ (CGFloat)heightForCellData:(MXKCellData*)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // Sanity check: accept only object of MXKRoomBubbleCellData classes or sub-classes
    NSParameterAssert([cellData isKindOfClass:[MXKRoomBubbleCellData class]]);
    MXKRoomBubbleCellData *bubbleData = (MXKRoomBubbleCellData*)cellData;
    
    // Look for the original cell class to extract the constraints value.
    Class modelCellViewClass = nil;
    if (bubbleData.shouldHideSenderInformation)
    {
        modelCellViewClass = bubbleData.isEncryptedRoom ? RoomIncomingEncryptedAttachmentWithoutSenderInfoBubbleCell.class : RoomIncomingAttachmentWithoutSenderInfoBubbleCell.class;
    }
    else
    {
        if (bubbleData.isPaginationFirstBubble)
        {
            modelCellViewClass = bubbleData.isEncryptedRoom ? RoomIncomingEncryptedAttachmentWithPaginationTitleBubbleCell.class : RoomIncomingAttachmentWithPaginationTitleBubbleCell.class;
        }
        else
        {
            modelCellViewClass = bubbleData.isEncryptedRoom ? RoomIncomingEncryptedAttachmentBubbleCell.class : RoomIncomingAttachmentBubbleCell.class;
        }
    }
    
    CGFloat rowHeight = [modelCellViewClass heightForCellData:cellData withMaximumWidth:maxWidth];
    
    // Finalize the cell height by adding the height of the description.
    // Retrieve the component which stores the sticker (Only one component is handled by the bubble in case of sticker).
    MXKRoomBubbleComponent *component = bubbleData.bubbleComponents.firstObject;
    NSAttributedString *description = component.attributedTextMessage;
    if (description.length)
    {
        RoomSelectedStickerBubbleCell* cell = (RoomSelectedStickerBubbleCell*)[self cellWithOriginalXib];
        CGRect frame = cell.frame;
        frame.size.width = maxWidth;
        frame.size.height = 300;
        cell.frame = frame;
        
        cell.descriptionLabel.attributedText = description;
        [cell layoutIfNeeded];
        
        rowHeight += cell.descriptionContainerView.frame.size.height + cell.descriptionContainerViewBottomConstraint.constant;
    }
    
    return rowHeight;
}

@end
