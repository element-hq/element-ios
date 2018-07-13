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

#import "DirectoryServerDetailTableViewCell.h"

#import "RiotDesignValues.h"

@implementation DirectoryServerDetailTableViewCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];

    self.detailDescLabel.textColor = kRiotSecondaryTextColor;
}

- (void)render:(id<MXKDirectoryServerCellDataStoring>)cellData
{
    [super render:cellData];

    if (cellData.includeAllNetworks)
    {

        self.detailDescLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"directory_server_all_rooms", @"Vector", nil), cellData.homeserver];
    }
    else
    {
        self.detailDescLabel.text = NSLocalizedStringFromTable(@"directory_server_all_native_rooms", @"Vector", nil);
    }
}

@end
