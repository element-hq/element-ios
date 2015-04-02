/*
 Copyright 2014 OpenMarket Ltd
 
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
#import <MatrixKit/MXKImageView.h>
#import <MatrixKit/MXKPieChartView.h>

#import <UIKit/UIKit.h>

@class MXRoomMember;
@class MXRoom;

// Room Member Table View Cell
@interface RoomMemberTableCell : UITableViewCell {
    MXKPieChartView* pieChartView;
}
@property (strong, nonatomic) IBOutlet MXKImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UIView *powerContainer;
@property (weak, nonatomic) IBOutlet UIImageView *typingBadge;

- (void)setRoomMember:(MXRoomMember *)roomMember withRoom:(MXRoom *)room;
@end

