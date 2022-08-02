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

@objcMembers
class AllChatsFilterOptions: NSObject {

    func createFilterListView() -> UIView? {
        guard optionsCount > 0 else {
            return nil
        }
        
        let filterOptionListView = AllChatsFilterOptionListView()
        
        let options = options
        var filterOptions: [AllChatsFilterOptionListView.Option] = [
            AllChatsFilterOptionListView.Option(type: .all, name: VectorL10n.allChatsAllFilter)
        ]
        filterOptions.append(contentsOf: options)
        
        filterOptionListView.options = filterOptions
        filterOptionListView.selectedOptionType = AllChatsLayoutSettingsManager.shared.activeFilters
        filterOptionListView.selectionChanged = { filter in
            guard filter != .all else {
                AllChatsLayoutSettingsManager.shared.activeFilters = []
                return
            }
         
            AllChatsLayoutSettingsManager.shared.activeFilters = filter
        }

        return filterOptionListView
    }
    
    var optionsCount: Int {
        return options.count
    }
    
    private var options: [AllChatsFilterOptionListView.Option] {
        var options: [AllChatsFilterOptionListView.Option] = []
        let filters = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.filters

        if filters.contains(.unreads) {
            options.append(AllChatsFilterOptionListView.Option(type: .unreads, name: VectorL10n.allChatsEditLayoutUnreads))
        }
        if filters.contains(.favourites) {
            options.append(AllChatsFilterOptionListView.Option(type: .favourites, name: VectorL10n.titleFavourites))
        }
        if filters.contains(.people) {
            options.append(AllChatsFilterOptionListView.Option(type: .people, name: VectorL10n.titlePeople))
        }
        if filters.contains(.rooms) {
            options.append(AllChatsFilterOptionListView.Option(type: .rooms, name: VectorL10n.titleRooms))
        }
        
        return options
    }
}
