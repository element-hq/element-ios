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

#import <MatrixSDK/MatrixSDK.h>

#import "MXKView.h"

typedef NS_ENUM(NSInteger, ReadReceiptsAlignment)
{
    /**
     The latest receipt is displayed on left
     */
    ReadReceiptAlignmentLeft = 0,
    
    /**
     The latest receipt is displayed on right
     */
    ReadReceiptAlignmentRight = 1,
};

/**
 `MXKReceiptSendersContainer` is a view dedicated to display receipt senders by using their avatars.
 
 This container handles automatically the number of visible avatars. A label is added when avatars are not all visible (see 'moreLabel' property).
 */
@interface MXKReceiptSendersContainer : MXKView

/**
 The maximum number of avatars displayed in the container. 3 by default.
 */
@property (nonatomic) NSInteger maxDisplayedAvatars;

/**
 The space between avatars. 2.0 points by default.
 */
@property (nonatomic) CGFloat avatarMargin;

/**
 The label added beside avatars when avatars are not all visible.
 */
@property (nonatomic) UILabel* moreLabel;

/**
 The more label text color (If set to nil `moreLabel.textColor` use `UIColor.blackColor` as default color).
 */
@property (nonatomic) UIColor* moreLabelTextColor;

/*
 The read receipt objects for details required in the details view
 */
@property (nonatomic) NSArray <MXReceiptData *> *readReceipts;

/*
 The array of the room members that will be displayed in the container
 */
@property (nonatomic, readonly) NSArray <MXRoomMember *> *roomMembers;

/*
 The placeholders of the room members that will be shown if the users don't have avatars
 */
@property (nonatomic, readonly) NSArray <UIImage *> *placeholders;

/**
 Initializes an `MXKReceiptSendersContainer` object with a frame and a media manager.
 
 This is the designated initializer.
 
 @param frame the container frame. Note that avatar will be displayed in full height in this container.
 @param mediaManager the media manager used to download the matrix user's avatar.
 @return The newly-initialized MXKReceiptSendersContainer instance
 */
- (instancetype)initWithFrame:(CGRect)frame andMediaManager:(MXMediaManager*)mediaManager;

/**
 Refresh the container content by using the provided room members.
 
 @param roomMembers list of room members sorted from the latest receipt to the oldest receipt.
 @param placeHolders list of placeholders, one by room member. Used when url is nil, or during avatar download.
 @param alignment (see ReadReceiptsAlignment).
 */
- (void)refreshReceiptSenders:(NSArray<MXRoomMember*>*)roomMembers withPlaceHolders:(NSArray<UIImage*>*)placeHolders andAlignment:(ReadReceiptsAlignment)alignment;

@end

