// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit

/**
 Types of sections as defined in `RecentsDataSource`, albeit represented as an enum for stronger type safety
 */
enum RecentsDataSourceSectionType {
    case crossSigningBanner
    case secureBackupBanner
    case directory
    case invites
    case favorites
    case people
    case conversation
    case lowPriority
    case serverNotice
    case suggestedRooms
}

/**
 A store of content offsets for a special type of table view where each cell contains a collection view,
 and the content offset needs to be preserved across table view reloads.
 
 This type of table view is used on some of the tabs (e.g. home), where vertical rows represent sections
 (favourites, people, rooms ... ) and horizontal represents different rooms (shown in a collection view).
 When such a table view is reloaded, it will dequeue and reuse the previously created collection views
 in random order, meaning that any contentOffset they may have had will now be arbitrarily swapped around.
 The store allows saving the current content offsets per section and restoring them after a reload.
 */
@objc class RecentsContentOffsetStore: NSObject {
    private var contentOffsets = [RecentsDataSourceSectionType: CGPoint]()
    
    @objc func storeContentOffsets(for tableView: UITableView, dataSource: RecentsDataSource) {
        reset()
        let sections = sectionWithTypes(for: tableView, dataSource: dataSource)
        
        for (section, sectionType) in sections {
            
            let indexPath = IndexPath(row: 0, section: section)
            guard let cell = tableView.cellForRow(at: indexPath) as? TableViewCellWithCollectionView else {
                continue
            }
            
            contentOffsets[sectionType] = cell.collectionView.contentOffset
        }
    }
    
    @objc func restoreContentOffsets(for tableView: UITableView, dataSource: RecentsDataSource) {
        let sections = sectionWithTypes(for: tableView, dataSource: dataSource)
        
        for (section, sectionType) in sections {
            
            let indexPath = IndexPath(row: 0, section: section)
            guard
                let offset = contentOffsets[sectionType],
                let cell = tableView.cellForRow(at: indexPath) as? TableViewCellWithCollectionView
            else {
                continue
            }
            
            cell.collectionView.contentOffset = offset
        }
        reset()
    }
    
    private func reset() {
        contentOffsets = [:]
    }
    
    private func sectionWithTypes(for tableView: UITableView, dataSource: RecentsDataSource) -> [(Int, RecentsDataSourceSectionType)] {
        // We associate the arbitrary integer index of a section at any particular time with its semantic value (e.g. 2 = `favorites`).
        // At this point the index could equal -1 because not all indexes in data source ara valid for every screen
        return [
            (dataSource.crossSigningBannerSection, .crossSigningBanner),
            (dataSource.secureBackupBannerSection, .secureBackupBanner),
            (dataSource.directorySection, .directory),
            (dataSource.invitesSection, .invites),
            (dataSource.favoritesSection, .favorites),
            (dataSource.peopleSection, .people),
            (dataSource.conversationSection, .conversation),
            (dataSource.lowPrioritySection, .lowPriority),
            (dataSource.serverNoticeSection, .serverNotice),
            (dataSource.suggestedRoomsSection, .suggestedRooms)
        ].filter { (section, sectionType) in
            
            // We only want indexes that are valid for a given view and actually shown on the table view
            section != DATA_SOURCE_INVALID_SECTION
            && section < tableView.numberOfSections
        }
    }
}
