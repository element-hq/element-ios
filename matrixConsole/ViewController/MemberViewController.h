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

#import <UIKit/UIKit.h>

#import "MatrixHandler.h"

@interface MemberViewController : UITableViewController {
    NSMutableArray* buttonsTitles;
    
    UIView* pendingRequestMask;
}


@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *memberThumbnailButton;
@property (weak, nonatomic) IBOutlet UITextView *roomMemberMID;

- (IBAction)onButtonToggle:(id)sender;


@property (strong, nonatomic) MXRoomMember *roomMember;
@property (strong, nonatomic) MXRoom *mxRoom;



@end

