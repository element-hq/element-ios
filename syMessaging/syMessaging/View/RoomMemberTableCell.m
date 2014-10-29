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

#import "RoomMemberTableCell.h"
#import "MatrixHandler.h"

@implementation RoomMemberTableCell

- (void)setRoomMember:(MXRoomMember *)roomMember withRoomData:(MXRoomData *)roomData {
    if (roomData && roomMember) {
        self.userLabel.text = [roomData memberName:roomMember.user_id];
        self.placeholder = @"default-profile";
        self.pictureURL = roomMember.avatar_url;
        
        // Shade invited users
        if ([roomMember.membership isEqualToString:@"invite"]) {
            for (UIView *view in self.subviews) {
                view.alpha = 0.3;
            }
        } else {
            for (UIView *view in self.subviews) {
                view.alpha = 1;
            }
        }
        
        // Handle power level display
        NSDictionary *powerLevels = roomData.powerLevels;
        if (powerLevels) {
            int maxLevel = 0;
            for (NSString *powerLevel in powerLevels.allValues) {
                int level = [powerLevel intValue];
                if (level > maxLevel) {
                    maxLevel = level;
                }
            }
            NSString *userPowerLevel = [powerLevels objectForKey:roomMember.user_id]; // CAUTION: we invoke objectForKey here because user_id starts with an '@' character
            if (userPowerLevel == nil) {
                userPowerLevel = [powerLevels valueForKey:@"default"];
            }
            float userPowerLevelFloat = 0.0;
            if (userPowerLevel) {
                userPowerLevelFloat = [userPowerLevel floatValue];
            }
            self.userPowerLevel.progress = maxLevel ? userPowerLevelFloat / maxLevel : 1;
        } else {
            self.userPowerLevel.progress = 0;
        }
        
        // TODO: handle last_active_ago duration when it will be available from SDK
        self.lastActiveAgoLabel.backgroundColor = [UIColor greenColor];
        self.lastActiveAgoLabel.text = [NSString stringWithFormat:@"%ds ago", roomMember.last_active_ago];
        self.lastActiveAgoLabel.numberOfLines = 0;
    }
}
@end