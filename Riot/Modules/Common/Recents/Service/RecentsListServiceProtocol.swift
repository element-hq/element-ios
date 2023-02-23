// 
// Copyright 2021 New Vector Ltd
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

@objc
public protocol RecentsListServiceProtocol {
    
    //  MARK: - Properties
    
    /// Current mode
    var mode: RecentsDataSourceMode { get }
    
    /// Query to filter rooms
    var query: String? { get }
    
    /// Current space
    var space: MXSpace? { get }
    
    // MARK: - Data
    
    /// Invited rooms for current mode
    var invitedRoomListData: MXRoomListData? { get }
    
    /// Favorited rooms for current mode
    var favoritedRoomListData: MXRoomListData? { get }
    
    /// Direct rooms for current mode
    var peopleRoomListData: MXRoomListData? { get }
    
    /// Rooms for current mode
    var conversationRoomListData: MXRoomListData? { get }
    
    /// Low priority rooms for current mode
    var lowPriorityRoomListData: MXRoomListData? { get }
    
    /// Server notice rooms for current mode
    var serverNoticeRoomListData: MXRoomListData? { get }
    
    /// Suggested rooms for current mode
    var suggestedRoomListData: MXRoomListData? { get }
    
    /// Breadcrumbs
    var breadcrumbsRoomListData: MXRoomListData? { get }
    
    /// All Chats room for current mode
    var allChatsRoomListData: MXRoomListData? { get }

    // MARK: Discussion counts
    
    /// Counts for favorite screen
    var favoritedMissedDiscussionsCount: DiscussionsCount { get }
    
    /// Counts for people screen
    var peopleMissedDiscussionsCount: DiscussionsCount { get }
    
    /// Counts for rooms screen
    var conversationMissedDiscussionsCount: DiscussionsCount { get }
    
    /// Total number of rooms visible in one screen. Can be used to display an empty view
    var totalVisibleItemCount: Int { get }
    
    //  MARK: - Methods
    
    /// Upte mode function
    /// - Parameter mode: new mode
    func updateMode(_ mode: RecentsDataSourceMode)
    
    /// Update query to filter rooms
    /// - Parameter query: new query
    func updateQuery(_ query: String?)
    
    /// Update current space
    /// - Parameter space: new space
    func updateSpace(_ space: MXSpace?)
    
    /// Refresh recents
    func refresh()
    
    /// Stop service. Do not use after stopping.
    func stop()
    
    //  MARK: Pagination
    
    /// Paginate in the given section.
    func paginate(inSection section: RecentsListServiceSection)
    
    //  MARK: - Delegate
    
    /// Add delegate instance for the service
    /// - Parameter delegate: new delegate
    func addDelegate(_ delegate: RecentsListServiceDelegate)
    
    /// Remove given delegate instance
    /// - Parameter delegate: delegate to be removed
    func removeDelegate(_ delegate: RecentsListServiceDelegate)
    
    /// Remove all delegates
    func removeAllDelegates()
}
