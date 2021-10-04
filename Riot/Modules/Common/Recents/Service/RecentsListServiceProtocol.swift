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
    var session: MXSession? { get }
    var mode: RecentsDataSourceMode { get }
    var query: String? { get }
    var space: MXSpace? { get }
    
    // MARK: Cells
    var invitedRoomListData: MXRoomListData? { get }
    var favoritedRoomListData: MXRoomListData? { get }
    var peopleRoomListData: MXRoomListData? { get }
    var conversationRoomListData: MXRoomListData? { get }
    var lowPriorityRoomListData: MXRoomListData? { get }
    var serverNoticeRoomListData: MXRoomListData? { get }
    var suggestedRoomListData: MXRoomListData? { get }
    
    // MARK: Discussion counts
    var favoritedMissedDiscussionsCount: DiscussionsCount { get }
    var peopleMissedDiscussionsCount: DiscussionsCount { get }
    var conversationMissedDiscussionsCount: DiscussionsCount { get }
    var totalVisibleItemCount: Int { get }
    
    //  MARK: - Methods
    func updateMode(_ mode: RecentsDataSourceMode)
    func updateQuery(_ query: String?)
    func updateSpace(_ space: MXSpace?)
    func refresh()
    func stop()
    
    //  MARK: - Delegate
    
    func addDelegate(_ delegate: RecentsListServiceDelegate)
    func removeDelegate(_ delegate: RecentsListServiceDelegate)
    func removeAllDelegates()
}
