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
