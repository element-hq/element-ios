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

#import "RoomTitleView.h"

#import "RoomPreviewData.h"

@interface PreviewRoomTitleView : RoomTitleView

@property (weak, nonatomic) IBOutlet UIView *mainHeaderContainer;

@property (weak, nonatomic) IBOutlet UILabel *roomTopic;

@property (weak, nonatomic) IBOutlet UILabel *roomMembers;
@property (weak, nonatomic) IBOutlet UIView *roomMembersDetailsIcon;

@property (weak, nonatomic) IBOutlet UILabel *invitationLabel;
@property (weak, nonatomic) IBOutlet UIView *buttonsContainer;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UILabel *subInvitationLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomBorderView;

@property (strong, nonatomic) RoomPreviewData *roomPreviewData;

@end