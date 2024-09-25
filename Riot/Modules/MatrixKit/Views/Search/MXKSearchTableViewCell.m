/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKSearchTableViewCell.h"

@import MatrixSDK.MXMediaManager;

#import "MXKSearchCellDataStoring.h"

@implementation MXKSearchTableViewCell

#pragma mark - Class methods

- (void)render:(MXKCellData *)cellData
{
    // Sanity check: accept only object of MXKRoomBubbleCellData classes or sub-classes
    NSParameterAssert([cellData conformsToProtocol:@protocol(MXKSearchCellDataStoring)]);
    
    id<MXKSearchCellDataStoring> searchCellData = (id<MXKSearchCellDataStoring>)cellData;
    if (searchCellData)
    {
        _title.text = searchCellData.title;
        _date.text = searchCellData.date;
        _message.text = searchCellData.message;
        
        if (_attachmentImageView)
        {
            _attachmentImageView.image = nil;
            self.attachmentImageView.defaultBackgroundColor = [UIColor clearColor];
            
            if (searchCellData.isAttachmentWithThumbnail)
            {
                [self.attachmentImageView setAttachmentThumb:searchCellData.attachment];
                self.attachmentImageView.defaultBackgroundColor = [UIColor whiteColor];
            }
        }
        
        if (_iconImage)
        {
            _iconImage.image = searchCellData.attachmentIcon;
        }
    }
    else
    {
        _title.text = nil;
        _date.text = nil;
        _message.text = @"";
        
        _attachmentImageView.image = nil;
        _iconImage.image = nil;
    }
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 70;
}

@end
