/*
 Copyright 2017 Vector Creations Ltd

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

#import "MatrixKit.h"

#import "DeviceTableViewCell.h"

@interface UsersDevicesViewController : MXKViewController <UITableViewDelegate, UITableViewDataSource, DeviceTableViewCellDelegate>

/**
 Display a map of users/devices.

 @param usersDevices the map to display.
 @param mxSession the Matrix session.
 @param onComplete a block called when the user quits the screen
                   doneButtonPressed is:
                       - YES if the user clicked the Done button, meaning he acknowledges all unknown devices.
                       - NO if the user clicked the Cancel button, meaning he prefers to cancel the current request.
 */
- (void)displayUsersDevices:(MXUsersDevicesMap<MXDeviceInfo*>*)usersDevices andMatrixSession:(MXSession*)mxSession onComplete:(void (^)(BOOL doneButtonPressed))onComplete;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
