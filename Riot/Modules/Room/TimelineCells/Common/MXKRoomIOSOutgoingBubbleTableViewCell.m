/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MXKRoomIOSOutgoingBubbleTableViewCell.h"

#import "MXKRoomBubbleCellData.h"

#import "MXEvent+MatrixKit.h"
#import "MXKTools.h"

#import "NSBundle+MatrixKit.h"

#import "MXKImageView.h"

#define OUTGOING_BUBBLE_COLOR 0x00e34d

@implementation MXKRoomIOSOutgoingBubbleTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Create the strechable background bubble
        self.bubbleImageView.image = self.class.bubbleImage;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    // Reset values
    self.bubbleImageView.hidden = NO;
    
    // Customise the data precomputed by the legacy classes
    // Replace black color in texts by the white color expected for outgoing messages.
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.messageTextView.attributedText];
    
    // Change all attributes one by one
    [attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop)
    {
        
        // Replace only black colored texts
        if (attrs[NSForegroundColorAttributeName] == self->bubbleData.eventFormatter.defaultTextColor)
        {
            
            // By white
            NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithDictionary:attrs];
            newAttrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
            
            [attributedString setAttributes:newAttrs range:range];
        }
    }];
    
    self.messageTextView.attributedText = attributedString;
    
    // Update the bubble width to include the text view
    self.bubbleImageViewWidthConstraint.constant = bubbleData.contentSize.width + 17;
    
    // Limit bubble width
    if (self.bubbleImageViewWidthConstraint.constant < 46)
    {
        self.bubbleImageViewWidthConstraint.constant = 46;
    }
    
    // Mask the image with the bubble
    if (bubbleData.attachment && bubbleData.attachment.type != MXKAttachmentTypeFile && bubbleData.attachment.type != MXKAttachmentTypeAudio)
    {
        self.bubbleImageView.hidden = YES;
        
        UIImageView *rightBubbleImageView = [[UIImageView alloc] initWithImage:self.class.bubbleImage];
        rightBubbleImageView.frame = CGRectMake(0, 0, self.bubbleImageViewWidthConstraint.constant, bubbleData.contentSize.height + self.attachViewTopConstraint.constant - 4);
        
        self.attachmentView.layer.mask = rightBubbleImageView.layer;
    }
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    CGFloat rowHeight = [super heightForCellData:cellData withMaximumWidth:maxWidth];
    
    CGFloat height = self.cellWithOriginalXib.frame.size.height;
    
    // Use the xib height as the minimal height
    if (rowHeight < height)
    {
        rowHeight = height;
    }
    
    return rowHeight;
}

/**
 Create the strechable background bubble.
 
 @return the bubble image.
 */
+ (UIImage *)bubbleImage
{
    UIImage *rightBubbleImage = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"bubble_ios_messages_right"];

    rightBubbleImage = [MXKTools paintImage:rightBubbleImage
                                  withColor:[MXKTools colorWithRGBValue:OUTGOING_BUBBLE_COLOR]];
    
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(17, 22, 17, 27);
    return [rightBubbleImage resizableImageWithCapInsets:edgeInsets];
}

@end
