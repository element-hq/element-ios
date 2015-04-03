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

#import "RecentListDataSource.h"

#import "AppDelegate.h"

@implementation RecentListDataSource

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Leave the selected room
        id<MXKRecentCellDataStoring> recentCellData = [self cellDataAtIndex:indexPath.row];
        
        // cancel pending uploads/downloads
        // they are useless by now
        [MXKMediaManager cancelDownloadsInCacheFolder:recentCellData.room.state.roomId];
        // TODO GFO cancel pending uploads related to this room
        
        [recentCellData.room leave:^{
            // Refresh table display
            [self didCellDataChange:recentCellData];
        } failure:^(NSError *error) {
            NSLog(@"[Console RecentListDataSource] Failed to leave room (%@) failed: %@", recentCellData.room.state.roomId, error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
}

@end
