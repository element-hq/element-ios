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

@objcMembers
public class RecentsRoomListFetchersContainer: NSObject {
    
    public let session: MXSession
    public private(set) var mode: RecentsDataSourceMode
    public private(set) var query: String?
    public private(set) var space: MXSpace?
    
    //  MARK: - Fetchers
    
    public private(set) var invitedRoomListDataFetcher: MXRoomListDataFetcher?
    public private(set) var favoritedRoomListDataFetcher: MXRoomListDataFetcher?
    public var directRoomListDataFetcher: MXRoomListDataFetcher? {
        switch mode {
        case .home:
            return directRoomListDataFetcherForHome
        case .people:
            return directRoomListDataFetcherForPeople
        default:
            return nil
        }
    }
    public var conversationRoomListDataFetcher: MXRoomListDataFetcher? {
        switch mode {
        case .home:
            return conversationRoomListDataFetcherForHome
        case .rooms:
            return conversationRoomListDataFetcherForRooms
        default:
            return nil
        }
    }
    public private(set) var lowPriorityRoomListDataFetcher: MXRoomListDataFetcher?
    public private(set) var serverNoticeRoomListDataFetcher: MXRoomListDataFetcher?
    public private(set) var suggestedRoomListDataFetcher: MXRoomListDataFetcher?
    
    private var conversationRoomListDataFetcherForHome: MXRoomListDataFetcher?
    private var conversationRoomListDataFetcherForRooms: MXRoomListDataFetcher?
    private var directRoomListDataFetcherForHome: MXRoomListDataFetcher?
    private var directRoomListDataFetcherForPeople: MXRoomListDataFetcher?
    
    //  MARK: - Private
    
    private var fetcherTypesForMode: [RecentsDataSourceMode: FetcherTypes] = [
        .home: [.invited, .favorited, .directHome, .conversationHome, .lowPriority, .serverNotice],
        .favourites: [.favorited],
        .people: [.directPeople],
        .rooms: [.conversationRooms]
    ]
    
    private var allFetchers: [MXRoomListDataFetcher] {
        var result: [MXRoomListDataFetcher] = []
        if let fetcher = invitedRoomListDataFetcher {
            result.append(fetcher)
        }
        if let fetcher = favoritedRoomListDataFetcher {
            result.append(fetcher)
        }
        if let fetcher = directRoomListDataFetcherForHome {
            result.append(fetcher)
        }
        if let fetcher = directRoomListDataFetcherForPeople {
            result.append(fetcher)
        }
        if let fetcher = conversationRoomListDataFetcherForHome {
            result.append(fetcher)
        }
        if let fetcher = conversationRoomListDataFetcherForRooms {
            result.append(fetcher)
        }
        if let fetcher = lowPriorityRoomListDataFetcher {
            result.append(fetcher)
        }
        if let fetcher = serverNoticeRoomListDataFetcher {
            result.append(fetcher)
        }
        if let fetcher = suggestedRoomListDataFetcher {
            result.append(fetcher)
        }
        return result
    }
    
    private var hideInvitedSection: Bool {
        return MXSDKOptions.sharedInstance().autoAcceptRoomInvites
    }
    
    private var visibleFetchers: [MXRoomListDataFetcher] {
        guard let fetcherTypes = fetcherTypesForMode[mode] else {
            return []
        }
        var result: [MXRoomListDataFetcher] = []
        if let fetcher = invitedRoomListDataFetcher, fetcherTypes.contains(.invited) {
            result.append(fetcher)
        }
        if let fetcher = favoritedRoomListDataFetcher, fetcherTypes.contains(.favorited) {
            result.append(fetcher)
        }
        if let fetcher = directRoomListDataFetcherForHome, fetcherTypes.contains(.directHome) {
            result.append(fetcher)
        }
        if let fetcher = directRoomListDataFetcherForPeople, fetcherTypes.contains(.directPeople) {
            result.append(fetcher)
        }
        if let fetcher = conversationRoomListDataFetcherForHome, fetcherTypes.contains(.conversationHome) {
            result.append(fetcher)
        }
        if let fetcher = conversationRoomListDataFetcherForRooms, fetcherTypes.contains(.conversationRooms) {
            result.append(fetcher)
        }
        if let fetcher = lowPriorityRoomListDataFetcher, fetcherTypes.contains(.lowPriority) {
            result.append(fetcher)
        }
        if let fetcher = serverNoticeRoomListDataFetcher, fetcherTypes.contains(.serverNotice) {
            result.append(fetcher)
        }
        if let fetcher = suggestedRoomListDataFetcher,
           fetcherTypes.contains(.suggested) {
            result.append(fetcher)
        }
        return result
    }
    
    // swiftlint:disable weak_delegate
    private let multicastDelegate: MXMulticastDelegate<MXRoomListDataFetcherDelegate> = MXMulticastDelegate()
    // swiftlint:enable weak_delegate
    
    private var sortOptions: MXRoomListDataSortOptions {
        switch mode {
        case .home:
            let pinMissed = RiotSettings.shared.pinRoomsWithMissedNotificationsOnHome
            let pinUnread = RiotSettings.shared.pinRoomsWithUnreadMessagesOnHome
            return MXRoomListDataSortOptions(missedNotificationsFirst: pinMissed,
                                             unreadMessagesFirst: pinUnread)
        default:
            return MXRoomListDataSortOptions(missedNotificationsFirst: false,
                                             unreadMessagesFirst: false)
        }
    }
    
    //  MARK: - Public API
    
    public init(withSession session: MXSession,
                mode: RecentsDataSourceMode = .home,
                query: String? = nil,
                space: MXSpace? = nil) {
        self.session = session
        self.mode = mode
        self.query = query
        self.space = space
        super.init()
        createFetchers()
        addRiotSettingsObserver()
    }
    
    public var favoritedMissedDiscussionsCount: DiscussionsCount {
        guard let data = favoritedRoomListDataFetcher?.data else {
            return .zero
        }
        return DiscussionsCount(withRoomListDataCounts: data.counts)
    }
    
    public var directMissedDiscussionsCount: DiscussionsCount {
        guard let data = directRoomListDataFetcherForPeople?.data else {
            return .zero
        }
        return DiscussionsCount(withRoomListDataCounts: data.counts)
    }
    
    public var conversationMissedDiscussionsCount: DiscussionsCount {
        guard let data = conversationRoomListDataFetcherForRooms?.data else {
            return .zero
        }
        return DiscussionsCount(withRoomListDataCounts: data.counts)
    }
    
    public var shouldShowInvited: Bool {
        return fetcherTypesForMode[mode]?.contains(.invited) ?? false
    }
    
    public var shouldShowFavorited: Bool {
        return fetcherTypesForMode[mode]?.contains(.favorited) ?? false
    }
    
    public var shouldShowDirect: Bool {
        switch mode {
        case .home:
            return fetcherTypesForMode[mode]?.contains(.directHome) ?? false
        case .people:
            return fetcherTypesForMode[mode]?.contains(.directPeople) ?? false
        default:
            return false
        }
    }
    
    public var shouldShowConversation: Bool {
        switch mode {
        case .home:
            return fetcherTypesForMode[mode]?.contains(.conversationHome) ?? false
        case .rooms:
            return fetcherTypesForMode[mode]?.contains(.conversationRooms) ?? false
        default:
            return false
        }
    }
    
    public var shouldShowLowPriority: Bool {
        return fetcherTypesForMode[mode]?.contains(.lowPriority) ?? false
    }
    
    public var shouldShowServerNotice: Bool {
        return fetcherTypesForMode[mode]?.contains(.serverNotice) ?? false
    }
    
    public func updateMode(_ mode: RecentsDataSourceMode) {
        self.mode = mode
        if let fetcher = favoritedRoomListDataFetcher {
            updateFavoritedFetcher(fetcher, for: mode)
        }
        allFetchers.forEach({ notifyDataChange(on: $0) })
    }
    
    public func updateQuery(_ query: String?) {
        self.query = query
        visibleFetchers.forEach({ $0.fetchOptions.filterOptions.query = query })
    }
    
    public func updateSpace(_ space: MXSpace?) {
        self.space = space
        allFetchers.forEach({ $0.fetchOptions.filterOptions.space = space })
    }
    
    public func refresh() {
        allFetchers.forEach({ $0.fetchOptions.sortOptions = sortOptions })
    }
    
    public func stop() {
        removeRiotSettingsObserver()
        removeAllDelegates()
        allFetchers.forEach({ $0.stop() })
    }
    
    //  MARK: - Delegate
    
    public func addDelegate(_ delegate: MXRoomListDataFetcherDelegate) {
        multicastDelegate.addDelegate(delegate)
    }
    
    public func removeDelegate(_ delegate: MXRoomListDataFetcherDelegate) {
        multicastDelegate.removeDelegate(delegate)
    }
    
    public func removeAllDelegates() {
        multicastDelegate.removeAllDelegates()
    }
    
    //  MARK: - Private
    
    private func addRiotSettingsObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDefaultsUpdated(_:)),
                                               name: .userDefaultValueUpdated,
                                               object: nil)
    }
    
    private func removeRiotSettingsObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .userDefaultValueUpdated,
                                                  object: nil)
    }
    
    @objc
    private func userDefaultsUpdated(_ notification: Notification) {
        guard let key = notification.object as? String else {
            return
        }
        switch key {
        case RiotSettings.UserDefaultsKeys.pinRoomsWithMissedNotificationsOnHome,
             RiotSettings.UserDefaultsKeys.pinRoomsWithUnreadMessagesOnHome:
            refresh()
        default:
            break
        }
    }
    
    private func createCommonRoomListDataFetcher(withDataTypes dataTypes: MXRoomSummaryDataTypes,
                                                 paginate: Bool = true) -> MXRoomListDataFetcher {
        let filterOptions = MXRoomListDataFilterOptions(dataTypes: dataTypes,
                                                        query: query)
        
        let fetchOptions = MXRoomListDataFetchOptions(filterOptions: filterOptions,
                                                      sortOptions: sortOptions,
                                                      async: false)
        let fetcher = session.roomListDataManager.fetcher(withOptions: fetchOptions)
        if paginate {
            fetcher.addDelegate(self)
            fetcher.paginate()
        }
        return fetcher
    }
    
    private func createDirectRoomListDataFetcherForHome() -> MXRoomListDataFetcher? {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [.direct], paginate: false)
        updateDirectFetcher(fetcher, for: .home)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }
    
    private func createDirectRoomListDataFetcherForPeople() -> MXRoomListDataFetcher? {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [.direct], paginate: false)
        updateDirectFetcher(fetcher, for: .people)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }
    
    private func createConversationRoomListDataFetcherForHome() -> MXRoomListDataFetcher? {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [], paginate: false)
        updateConversationFetcher(fetcher, for: .home)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }
    
    private func createConversationRoomListDataFetcherForRooms() -> MXRoomListDataFetcher? {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [], paginate: false)
        updateConversationFetcher(fetcher, for: .rooms)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }
    
    private func createFetchers() {
        if !hideInvitedSection {
            invitedRoomListDataFetcher = createCommonRoomListDataFetcher(withDataTypes: [.invited])
        }
        favoritedRoomListDataFetcher = createCommonRoomListDataFetcher(withDataTypes: [.favorited])
        directRoomListDataFetcherForHome = createDirectRoomListDataFetcherForHome()
        directRoomListDataFetcherForPeople = createDirectRoomListDataFetcherForPeople()
        conversationRoomListDataFetcherForHome = createConversationRoomListDataFetcherForHome()
        conversationRoomListDataFetcherForRooms = createConversationRoomListDataFetcherForRooms()
        lowPriorityRoomListDataFetcher = createCommonRoomListDataFetcher(withDataTypes: [.lowPriority])
        serverNoticeRoomListDataFetcher = createCommonRoomListDataFetcher(withDataTypes: [.serverNotice])
    }
    
    private func updateDirectFetcher(_ fetcher: MXRoomListDataFetcher, for mode: RecentsDataSourceMode) {
        switch mode {
        case .home:
            fetcher.fetchOptions.filterOptions.notDataTypes = [.invited, .lowPriority]
        case .people:
            fetcher.fetchOptions.filterOptions.notDataTypes = [.lowPriority]
        default:
            break
        }
    }
    
    private func updateFavoritedFetcher(_ fetcher: MXRoomListDataFetcher, for mode: RecentsDataSourceMode) {
        switch mode {
        case .home:
            fetcher.fetchOptions.sortOptions = sortOptions
        case .favourites:
            let newSortOptions = sortOptions
            newSortOptions.favoriteTag = true
            fetcher.fetchOptions.sortOptions = newSortOptions
        default:
            break
        }
    }
    
    private func updateConversationFetcher(_ fetcher: MXRoomListDataFetcher, for mode: RecentsDataSourceMode) {
        var notDataTypes: MXRoomSummaryDataTypes = [.hidden, .conferenceUser, .direct, .lowPriority, .serverNotice, .space]
        switch mode {
        case .home:
            notDataTypes.insert([.invited, .favorited])
            fetcher.fetchOptions.filterOptions.notDataTypes = notDataTypes
        case .rooms:
            if hideInvitedSection {
                notDataTypes.insert(.invited)
            }
            fetcher.fetchOptions.filterOptions.notDataTypes = notDataTypes
        default:
            break
        }
    }
    
    private func notifyDataChange(on fetcher: MXRoomListDataFetcher) {
        multicastDelegate.invoke(invocation: { $0.fetcherDidChangeData(fetcher) })
    }
    
    deinit {
        stop()
    }
    
}

//  MARK: - MXRoomListDataFetcherDelegate

extension RecentsRoomListFetchersContainer: MXRoomListDataFetcherDelegate {
    
    public func fetcherDidChangeData(_ fetcher: MXRoomListDataFetcher) {
        notifyDataChange(on: fetcher)
    }
    
}

//  MARK: - FetcherTypes

private struct FetcherTypes: OptionSet {
    typealias RawValue = Int
    let rawValue: RawValue
    
    init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    static let invited = FetcherTypes(rawValue: 1 << 0)
    static let favorited = FetcherTypes(rawValue: 1 << 1)
    static let directHome = FetcherTypes(rawValue: 1 << 2)
    static let directPeople = FetcherTypes(rawValue: 1 << 3)
    static let conversationHome = FetcherTypes(rawValue: 1 << 4)
    static let conversationRooms = FetcherTypes(rawValue: 1 << 5)
    static let lowPriority = FetcherTypes(rawValue: 1 << 6)
    static let serverNotice = FetcherTypes(rawValue: 1 << 7)
    static let suggested = FetcherTypes(rawValue: 1 << 8)
    
    static let none: FetcherTypes = []
    static let all: FetcherTypes = [
        .invited, .favorited, .directHome, .directPeople, .conversationHome, .conversationRooms, .lowPriority, .serverNotice, .suggested]
}
