/*
 Copyright 2015 OpenMarket Ltd
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

#import "MXKReceiptSendersContainer.h"

#import "MXKImageView.h"

static UIColor* kMoreLabelDefaultcolor;

@interface MXKReceiptSendersContainer ()

@property (nonatomic, readwrite) NSArray <MXRoomMember *> *roomMembers;
@property (nonatomic, readwrite) NSArray <UIImage *> *placeholders;
@property (nonatomic) MXMediaManager *mediaManager;

@end


@implementation MXKReceiptSendersContainer

+ (void)initialize
{
    if (self == [MXKReceiptSendersContainer class])
    {
        kMoreLabelDefaultcolor = [UIColor blackColor];
    }
}

- (instancetype)initWithFrame:(CGRect)frame andMediaManager:(MXMediaManager*)mediaManager
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _mediaManager = mediaManager;
        _maxDisplayedAvatars = 3;
        _avatarMargin = 2.0;
        _moreLabel = nil;
        _moreLabelTextColor = kMoreLabelDefaultcolor;
    }
    return self;
}

- (void)refreshReceiptSenders:(NSArray<MXRoomMember*>*)roomMembers withPlaceHolders:(NSArray<UIImage*>*)placeHolders andAlignment:(ReadReceiptsAlignment)alignment
{
    // Store the room members and placeholders for showing in the details view controller
    self.roomMembers = roomMembers;
    self.placeholders = placeHolders;
    
    // Remove all previous content
    for (UIView* view in self.subviews)
    {
        [view removeFromSuperview];
    }
    if (_moreLabel)
    {
        [_moreLabel removeFromSuperview];
        _moreLabel = nil;
    }
    
    CGRect globalFrame = self.frame;
    CGFloat side = globalFrame.size.height;
    CGFloat defaultMoreLabelWidth = side < 20 ? 20 : side;
    unsigned long count;
    unsigned long maxDisplayableItems = (int)((globalFrame.size.width - defaultMoreLabelWidth - _avatarMargin) / (side + _avatarMargin));
    
    maxDisplayableItems = MIN(maxDisplayableItems, _maxDisplayedAvatars);
    count = MIN(roomMembers.count, maxDisplayableItems);
    
    int index;
    
    CGFloat xOff = 0;
    
    if (alignment == ReadReceiptAlignmentRight)
    {
        xOff = globalFrame.size.width - (side + _avatarMargin);
    }
    
    for (index = 0; index < count; index++)
    {
        MXRoomMember *roomMember = [roomMembers objectAtIndex:index];
        UIImage *preview = index < placeHolders.count ? placeHolders[index] : nil;
        
        MXKImageView *imageView = [[MXKImageView alloc] initWithFrame:CGRectMake(xOff, 0, side, side)];
        imageView.defaultBackgroundColor = [UIColor clearColor];
        imageView.autoresizingMask = UIViewAutoresizingNone;
        
        if (alignment == ReadReceiptAlignmentRight)
        {
            xOff -= side + _avatarMargin;
        }
        else
        {
            xOff += side + _avatarMargin;
        }
        
        [self addSubview:imageView];
        imageView.enableInMemoryCache = YES;
        
        [imageView setImageURI:roomMember.avatarUrl
                      withType:nil
           andImageOrientation:UIImageOrientationUp
                 toFitViewSize:CGSizeMake(side, side)
                    withMethod:MXThumbnailingMethodCrop
                  previewImage:preview
                  mediaManager:_mediaManager];
        
        [imageView.layer setCornerRadius:imageView.frame.size.width / 2];
        imageView.clipsToBounds = YES;
    }
    
    // Check whether there are more than expected read receipts
    if (roomMembers.count > maxDisplayableItems)
    {
        // Add a more indicator
        
        // In case of right alignment, adjust the current position by considering the default label width
        if (alignment == ReadReceiptAlignmentRight && side < defaultMoreLabelWidth)
        {
            xOff -= (defaultMoreLabelWidth - side);
        }
        
        _moreLabel = [[UILabel alloc] initWithFrame:CGRectMake(xOff, 0, defaultMoreLabelWidth, side)];
        _moreLabel.text = [NSString stringWithFormat:(alignment == ReadReceiptAlignmentRight) ? @"%tu+" : @"+%tu", roomMembers.count - maxDisplayableItems];
        _moreLabel.font = [UIFont systemFontOfSize:11];
        _moreLabel.adjustsFontSizeToFitWidth = YES;
        _moreLabel.minimumScaleFactor = 0.6;
        
        // In case of right alignment, adjust the horizontal position according to the actual label width
        if (alignment == ReadReceiptAlignmentRight)
        {
            [_moreLabel sizeToFit];
            CGRect frame = _moreLabel.frame;
            if (frame.size.width < defaultMoreLabelWidth)
            {
                frame.origin.x += (defaultMoreLabelWidth - frame.size.width);
                _moreLabel.frame = frame;
            }
        }
        
        _moreLabel.textColor = self.moreLabelTextColor ?: kMoreLabelDefaultcolor;
        [self addSubview:_moreLabel];
    }
}

- (void)dealloc
{
    NSArray* subviews = self.subviews;
    for (UIView* view in subviews)
    {
        [view removeFromSuperview];
    }
    
    if (_moreLabel)
    {
        [_moreLabel removeFromSuperview];
        _moreLabel = nil;
    }
}

@end
