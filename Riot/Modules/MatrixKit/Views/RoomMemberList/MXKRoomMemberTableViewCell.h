/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCell.h"
#import "MXKCellRendering.h"

@class MXKImageView;
@class MXKPieChartView;
@class MXSession;

/**
 `MXKRoomMemberTableViewCell` instances display a user in the context of the room member list.
 */
@interface MXKRoomMemberTableViewCell : MXKTableViewCell <MXKCellRendering> {

@protected
    /**
     */
    MXSession *mxSession;
    
    /**
     */
    NSString *memberId;
    
    /**
     YES when last activity time is displayed and must be refreshed regularly.
     */
    BOOL shouldUpdateActivityInfo;
}

@property (strong, nonatomic) IBOutlet MXKImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UIView *powerContainer;
@property (weak, nonatomic) IBOutlet UIImageView *typingBadge;

/**
 The default picture displayed when no picture is available.
 */
@property (nonatomic) UIImage *picturePlaceholder;

/**
 Update last activity information if any.
 */
- (void)updateActivityInfo;

/**
 Stringify the last activity date/time of the member.
 
 @return a string which described the last activity time of the member.
 */
- (NSString*)lastActiveTime;

@end
