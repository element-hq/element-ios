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

#import <UIKit/UIKit.h>

#import "MatrixKit.h"

@interface DirectoryServerPickerViewController : MXKTableViewController <MXKDataSourceDelegate, UITableViewDelegate>

/**
 Display data managed by the passed `MXKDirectoryServersDataSource`.

 @param dataSource the data source serving the data.
 @param onComplete a block called when the picker disappears. It provides data about
                   the selected protocol instance or homeserver.
                   Both nil means the user cancelled the picker.
 */
- (void)displayWithDataSource:(MXKDirectoryServersDataSource*)dataSource
                   onComplete:(void (^)(id<MXKDirectoryServerCellDataStoring> cellData))onComplete;

@end

