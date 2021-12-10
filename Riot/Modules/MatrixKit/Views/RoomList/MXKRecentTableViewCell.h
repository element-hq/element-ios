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

#import "MXKRecentCellDataStoring.h"

/**
 `MXKRecentTableViewCell` instances display a room in the context of the recents list.
 */
@interface MXKRecentTableViewCell : MXKTableViewCell <MXKCellRendering>
{
@protected
    /**
     The current cell data displayed by the table view cell
     */
    id<MXKRecentCellDataStoring> roomCellData;
}

@property (weak, nonatomic) IBOutlet UILabel *roomTitle;
@property (weak, nonatomic) IBOutlet UILabel *lastEventDescription;
@property (weak, nonatomic) IBOutlet UILabel *lastEventDate;

@end
