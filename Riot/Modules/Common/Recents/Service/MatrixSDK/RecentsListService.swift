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
import CoreImage

@objcMembers
public class RecentsListService: NSObject, RecentsListServiceProtocol {
    
    private weak var session: MXSession?
    public private(set) var mode: RecentsDataSourceMode {
        didSet {
            refresh()
        }
    }
    
    public private(set) var query: String?
    public private(set) var space: MXSpace?
    private var fetchersCreated: Bool = false
    
    //  MARK: - Fetchers
    
    private var invitedRoomListDataFetcher: MXRoomListDataFetcher? {
        switch mode {
        case .home, .allChats, .roomInvites:
            return invitedRoomListDataFetcherForHome
        case .people:
            return invitedRoomListDataFetcherForPeople
        case .rooms:
            return invitedRoomListDataFetcherForRooms
        default:
            return nil
        }
    }
    private var favoritedRoomListDataFetcher: MXRoomListDataFetcher?
    private var directRoomListDataFetcher: MXRoomListDataFetcher? {
        switch mode {
        case .home, .allChats:
            return directRoomListDataFetcherForHome
        case .people:
            return directRoomListDataFetcherForPeople
        default:
            return nil
        }
    }
    private var conversationRoomListDataFetcher: MXRoomListDataFetcher? {
        switch mode {
        case .home:
            return conversationRoomListDataFetcherForHome
        case .rooms:
            return conversationRoomListDataFetcherForRooms
        default:
            return nil
        }
    }
    private var lowPriorityRoomListDataFetcher: MXRoomListDataFetcher?
    private var serverNoticeRoomListDataFetcher: MXRoomListDataFetcher?
    private var suggestedRoomListDataFetcher: MXRoomListDataFetcher?
    private var breadcrumbsRoomListDataFetcher: MXRoomListDataFetcher?
    private var allChatsRoomListDataFetcher: MXRoomListDataFetcher?

    private var conversationRoomListDataFetcherForHome: MXRoomListDataFetcher?
    private var conversationRoomListDataFetcherForRooms: MXRoomListDataFetcher?
    private var directRoomListDataFetcherForHome: MXRoomListDataFetcher?
    private var directRoomListDataFetcherForPeople: MXRoomListDataFetcher?
    private var invitedRoomListDataFetcherForHome: MXRoomListDataFetcher?
    private var invitedRoomListDataFetcherForPeople: MXRoomListDataFetcher?
    private var invitedRoomListDataFetcherForRooms: MXRoomListDataFetcher?

    //  MARK: - Private
    
    private var fetcherTypesForMode: [RecentsDataSourceMode: FetcherTypes] = [
        .home: [.invited, .favorited, .directHome, .conversationHome, .lowPriority, .serverNotice, .suggested],
        .favourites: [.favorited],
        .people: [.invited, .directPeople],
        .rooms: [.invited, .conversationRooms, .suggested],
        .roomInvites: [.invited],
        .allChats: [.breadcrumbs, .favorited, .directHome, .invited, .allChats, .lowPriority, .serverNotice, .suggested]
    ]
    
    private var allFetchers: [MXRoomListDataFetcher] {
        return [
            invitedRoomListDataFetcherForHome,
            invitedRoomListDataFetcherForPeople,
            invitedRoomListDataFetcherForRooms,
            favoritedRoomListDataFetcher,
            directRoomListDataFetcherForHome,
            directRoomListDataFetcherForPeople,
            conversationRoomListDataFetcherForHome,
            conversationRoomListDataFetcherForRooms,
            lowPriorityRoomListDataFetcher,
            serverNoticeRoomListDataFetcher,
            suggestedRoomListDataFetcher,
            breadcrumbsRoomListDataFetcher,
            allChatsRoomListDataFetcher
        ].compactMap({ $0 })
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
        if let fetcher = lowPriorityRoomListDataFetcher, fetcherTypes.contains(.lowPriority), shouldShowLowPriority {
            result.append(fetcher)
        }
        if let fetcher = serverNoticeRoomListDataFetcher, fetcherTypes.contains(.serverNotice) {
            result.append(fetcher)
        }
        if space != nil, let fetcher = suggestedRoomListDataFetcher, fetcherTypes.contains(.suggested) {
            result.append(fetcher)
        }
        if let fetcher = breadcrumbsRoomListDataFetcher, fetcherTypes.contains(.breadcrumbs), shouldShowBreadcrumbs {
            result.append(fetcher)
        }
        if let fetcher = allChatsRoomListDataFetcher, fetcherTypes.contains(.allChats) {
            result.append(fetcher)
        }
        return result
    }

    private var hideInvitedSection: Bool {
        return MXSDKOptions.sharedInstance().autoAcceptRoomInvites
    }
    
    private var showAllRoomsInHomeSpace: Bool {
        return RiotSettings.shared.showAllRoomsInHomeSpace
    }
    
    // swiftlint:disable weak_delegate
    private let multicastDelegate: MXMulticastDelegate<RecentsListServiceDelegate> = MXMulticastDelegate()
    // swiftlint:enable weak_delegate
    
    private var noSortOptions: MXRoomListDataSortOptions {
        return MXRoomListDataSortOptions(invitesFirst: false, sentStatus: false, lastEventDate: false, favoriteTag: false, suggested: false, alphabetical: false, missedNotificationsFirst: false, unreadMessagesFirst: false)
    }
    
    private var sortOptions: MXRoomListDataSortOptions {
        switch mode {
        case .home:
            let pinMissed = RiotSettings.shared.pinRoomsWithMissedNotificationsOnHome
            let pinUnread = RiotSettings.shared.pinRoomsWithUnreadMessagesOnHome
            return MXRoomListDataSortOptions(missedNotificationsFirst: pinMissed,
                                             unreadMessagesFirst: pinUnread)
        case .allChats:
            let pinMissed = RiotSettings.shared.pinRoomsWithMissedNotificationsOnHome
            let pinUnread = RiotSettings.shared.pinRoomsWithUnreadMessagesOnHome
            switch AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.sorting {
            case .alphabetical:
                return MXRoomListDataSortOptions(invitesFirst: false,
                                                 sentStatus: false,
                                                 lastEventDate: false,
                                                 favoriteTag: false,
                                                 suggested: false,
                                                 alphabetical: true,
                                                 missedNotificationsFirst: false,
                                                 unreadMessagesFirst: false)
            case .activity:
                return MXRoomListDataSortOptions(missedNotificationsFirst: pinMissed,
                                                 unreadMessagesFirst: pinUnread)
            @unknown default:
                return MXRoomListDataSortOptions(missedNotificationsFirst: pinMissed,
                                                 unreadMessagesFirst: pinUnread)
            }
        default:
            return MXRoomListDataSortOptions(missedNotificationsFirst: false,
                                             unreadMessagesFirst: false)
        }
    }
    
    //  MARK: - Public API
    
    public convenience init(withSession session: MXSession) {
        self.init(withSession: session,
                  mode: .home,
                  query: nil,
                  space: nil)
    }
    
    private var allChatLayoutSettingsManagerObserver: Any?
    private var allChatLayoutSettingsObserver: Any?

    private init(withSession session: MXSession,
                mode: RecentsDataSourceMode,
                query: String?,
                space: MXSpace?) {
        self.session = session
        self.mode = mode
        self.query = query
        self.space = space
        super.init()
        createFetchers()
        addRiotSettingsObserver()
        addSessionStateObserver()
        
        allChatLayoutSettingsManagerObserver = NotificationCenter.default.addObserver(forName: AllChatsLayoutSettingsManager.didUpdateSettings, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let self = self else { return }
            self.refresh()
            for fetcher in self.allFetchers {
                fetcher.refresh()
            }
            if let fetcher = self.allChatsRoomListDataFetcher {
                self.updateConversationFetcher(fetcher, for: .allChats)
                fetcher.paginate()
            }
        }
        
        allChatLayoutSettingsObserver = NotificationCenter.default.addObserver(forName: AllChatsLayoutSettingsManager.didUpdateActiveFilters, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let self = self else { return }
            if let fetcher = self.allChatsRoomListDataFetcher {
                self.updateConversationFetcher(fetcher, for: .allChats)
                fetcher.paginate()
            }
        }
    }
    
    //  MARK: - View Data
    
    public var invitedRoomListData: MXRoomListData? {
        guard shouldShowInvited else { return nil }
        return invitedRoomListDataFetcher?.data
    }
    public var favoritedRoomListData: MXRoomListData? {
        guard shouldShowFavorited else { return nil }
        return favoritedRoomListDataFetcher?.data
    }
    public var peopleRoomListData: MXRoomListData? {
        guard shouldShowDirect else { return nil }
        return directRoomListDataFetcher?.data
    }
    public var conversationRoomListData: MXRoomListData? {
        guard shouldShowConversation else { return nil }
        return conversationRoomListDataFetcher?.data
    }
    public var lowPriorityRoomListData: MXRoomListData? {
        guard shouldShowLowPriority else { return nil }
        return lowPriorityRoomListDataFetcher?.data
    }
    public var serverNoticeRoomListData: MXRoomListData? {
        guard shouldShowServerNotice else { return nil }
        return serverNoticeRoomListDataFetcher?.data
    }
    public var suggestedRoomListData: MXRoomListData? {
        guard shouldShowSuggested else { return nil }
        return suggestedRoomListDataFetcher?.data
    }
    public var breadcrumbsRoomListData: MXRoomListData? {
        guard shouldShowBreadcrumbs else { return nil }
        return breadcrumbsRoomListDataFetcher?.data
    }
    public var allChatsRoomListData: MXRoomListData? {
        guard shouldShowAllChats else { return nil }
        return allChatsRoomListDataFetcher?.data
    }
    
    public var favoritedMissedDiscussionsCount: DiscussionsCount {
        guard let totalCounts = favoritedRoomListDataFetcher?.data?.counts.total else {
            return .zero
        }
        return DiscussionsCount(withRoomListDataCounts: [totalCounts])
    }
    
    public var peopleMissedDiscussionsCount: DiscussionsCount {
        let invitesCount = invitedRoomListDataFetcherForPeople?.data?.counts.total
        let directCount = directRoomListDataFetcherForPeople?.data?.counts.total
        let totalCounts = [invitesCount, directCount].compactMap { $0 }
        return DiscussionsCount(withRoomListDataCounts: totalCounts)
    }
    
    public var conversationMissedDiscussionsCount: DiscussionsCount {
        let invitesCount = invitedRoomListDataFetcherForRooms?.data?.counts.total
        let conversationCount = conversationRoomListDataFetcherForRooms?.data?.counts.total
        let totalCounts = [invitesCount, conversationCount].compactMap { $0 }
        return DiscussionsCount(withRoomListDataCounts: totalCounts)
    }
    
    public var totalVisibleItemCount: Int {
        return visibleFetchers.reduce(0, { $0 + ($1.data?.counts.numberOfRooms ?? 0) })
    }
    
    public func paginate(inSection section: RecentsListServiceSection) {
        guard let fetcher = fetcher(forSection: section) else {
            return
        }
        guard let data = fetcher.data else {
            //  first page is not fetched yet
            return
        }
        guard data.paginationOptions != .none else {
            //  pagination is not enabled
            return
        }
        fetcher.paginate()
    }
    
    public func updateMode(_ mode: RecentsDataSourceMode) {
        self.mode = mode
        if let fetcher = favoritedRoomListDataFetcher {
            updateFavoritedFetcher(fetcher, for: mode)
        }
        allFetchers.forEach({ notifyDataChange(on: $0, totalCountsChanged: true) })
    }
    
    public func updateQuery(_ query: String?) {
        self.query = query
        visibleFetchers.forEach({ $0.fetchOptions.filterOptions.query = query })
    }
    
    public func updateSpace(_ space: MXSpace?) {
        self.space = space
        allFetchers.forEach({ $0.fetchOptions.filterOptions.space = space })

        if let fetcher = conversationRoomListDataFetcherForHome {
            self.updateConversationFetcher(fetcher, for: .home)
            fetcher.paginate()
        }
        
        if let fetcher = allChatsRoomListDataFetcher {
            self.updateConversationFetcher(fetcher, for: .allChats)
            fetcher.paginate()
        }
    }
    
    public func refresh() {
        allFetchers.forEach({ $0.fetchOptions.sortOptions = $0.fetchOptions.filterOptions.onlyBreadcrumbs ? noSortOptions : sortOptions })
        allFetchers.forEach({ $0.fetchOptions.filterOptions.showAllRoomsInHomeSpace = showAllRoomsInHomeSpace })
    }
    
    public func stop() {
        removeSessionStateObserver()
        removeRiotSettingsObserver()
        removeAllDelegates()
        allFetchers.forEach({ $0.stop() })
        
        invitedRoomListDataFetcherForHome = nil
        invitedRoomListDataFetcherForPeople = nil
        invitedRoomListDataFetcherForRooms = nil
        favoritedRoomListDataFetcher = nil
        directRoomListDataFetcherForHome = nil
        directRoomListDataFetcherForPeople = nil
        conversationRoomListDataFetcherForHome = nil
        conversationRoomListDataFetcherForRooms = nil
        lowPriorityRoomListDataFetcher = nil
        serverNoticeRoomListDataFetcher = nil
        suggestedRoomListDataFetcher = nil
        breadcrumbsRoomListDataFetcher = nil
        allChatsRoomListDataFetcher = nil
    }
    
    //  MARK: - Delegate
    
    public func addDelegate(_ delegate: RecentsListServiceDelegate) {
        multicastDelegate.addDelegate(delegate)
    }
    
    public func removeDelegate(_ delegate: RecentsListServiceDelegate) {
        multicastDelegate.removeDelegate(delegate)
    }
    
    public func removeAllDelegates() {
        multicastDelegate.removeAllDelegates()
    }
    
    //  MARK: - Riot Settings Observer
    
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
        case RiotSettings.UserDefaultsKeys.showAllRoomsInHomeSpace:
            refresh()
        default:
            break
        }
    }
    
    //  MARK: - Session State Observers
    
    private func addSessionStateObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionStateUpdated(_:)),
                                               name: .mxSessionStateDidChange,
                                               object: nil)
    }
    
    private func removeSessionStateObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .mxSessionStateDidChange,
                                                  object: nil)
    }
    
    @objc
    private func sessionStateUpdated(_ notification: Notification) {
        guard let session = notification.object as? MXSession else {
            return
        }
        guard session == self.session else {
            return
        }
        createFetchers()
    }
    
    //  MARK: - Private
    
    private var shouldShowInvited: Bool {
        return fetcherTypesForMode[mode]?.contains(.invited) ?? false
    }
    
    private var shouldShowFavorited: Bool {
        return fetcherTypesForMode[mode]?.contains(.favorited) ?? false
    }
    
    private var shouldShowDirect: Bool {
        switch mode {
        case .home, .allChats:
            return fetcherTypesForMode[mode]?.contains(.directHome) ?? false
        case .people:
            return fetcherTypesForMode[mode]?.contains(.directPeople) ?? false
        default:
            return false
        }
    }
    
    private var shouldShowConversation: Bool {
        switch mode {
        case .home:
            return fetcherTypesForMode[mode]?.contains(.conversationHome) ?? false
        case .rooms:
            return fetcherTypesForMode[mode]?.contains(.conversationRooms) ?? false
        default:
            return false
        }
    }
    
    private var shouldShowLowPriority: Bool {
        return ((mode != .allChats) || !AllChatsLayoutSettingsManager.shared.hasAnActiveFilter) && fetcherTypesForMode[mode]?.contains(.lowPriority) ?? false
    }
    
    private var shouldShowServerNotice: Bool {
        return fetcherTypesForMode[mode]?.contains(.serverNotice) ?? false
    }
    
    private var shouldShowSuggested: Bool {
        return fetcherTypesForMode[mode]?.contains(.suggested) ?? false
    }
    
    private var shouldShowBreadcrumbs: Bool {
        return AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.sections.contains(.recents) && (fetcherTypesForMode[mode]?.contains(.breadcrumbs) ?? false)
    }
    
    private var shouldShowAllChats: Bool {
        return fetcherTypesForMode[mode]?.contains(.allChats) ?? false
    }

    private func fetcher(forSection section: RecentsListServiceSection) -> MXRoomListDataFetcher? {
        switch section {
        case .invited:
            return invitedRoomListDataFetcher
        case .favorited:
            return favoritedRoomListDataFetcher
        case .people:
            return directRoomListDataFetcher
        case .conversation:
            return conversationRoomListDataFetcher
        case .lowPriority:
            return lowPriorityRoomListDataFetcher
        case .serverNotice:
            return serverNoticeRoomListDataFetcher
        case .suggested:
            return suggestedRoomListDataFetcher
        case .breadcrumbs:
            return breadcrumbsRoomListDataFetcher
        case .allChats:
            return allChatsRoomListDataFetcher
        }
    }
    
    private func section(forFetcher fetcher: MXRoomListDataFetcher) -> RecentsListServiceSection? {
        if fetcher === invitedRoomListDataFetcher {
            return .invited
        } else if fetcher === favoritedRoomListDataFetcher {
            return .favorited
        } else if fetcher === directRoomListDataFetcher {
            return .people
        } else if fetcher === conversationRoomListDataFetcher {
            return .conversation
        } else if fetcher === lowPriorityRoomListDataFetcher {
            return .lowPriority
        } else if fetcher === serverNoticeRoomListDataFetcher {
            return .serverNotice
        } else if fetcher === suggestedRoomListDataFetcher {
            return .suggested
        } else if fetcher === breadcrumbsRoomListDataFetcher {
            return .breadcrumbs
        } else if fetcher === allChatsRoomListDataFetcher {
            return .allChats
        }
        return nil
    }
    
    private func createCommonRoomListDataFetcher(withDataTypes dataTypes: MXRoomSummaryDataTypes = [],
                                                 onlySuggested: Bool = false,
                                                 onlyBreadcrumbs: Bool = false,
                                                 paginate: Bool = true,
                                                 strictMatches: Bool = false) -> MXRoomListDataFetcher {
        guard let session = session else {
            fatalError("Session deallocated")
        }
        let filterOptions = MXRoomListDataFilterOptions(dataTypes: dataTypes,
                                                        onlySuggested: onlySuggested,
                                                        onlyBreadcrumbs: onlyBreadcrumbs,
                                                        query: query,
                                                        space: space,
                                                        showAllRoomsInHomeSpace: showAllRoomsInHomeSpace,
                                                        strictMatches: strictMatches)
        
        let fetchOptions = MXRoomListDataFetchOptions(filterOptions: filterOptions,
                                                      sortOptions: onlyBreadcrumbs ? noSortOptions : sortOptions,
                                                      async: true)
        let fetcher = session.roomListDataManager.fetcher(withOptions: fetchOptions)
        if paginate {
            fetcher.addDelegate(self)
            fetcher.paginate()
        }
        return fetcher
    }

    private func createInvitedRoomListDataFetcherForPeople() -> MXRoomListDataFetcher {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [.invited, .direct], paginate: false, strictMatches: true)
        updateInvitedFetcher(fetcher, for: .people)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }

    private func createInvitedRoomListDataFetcherForRooms() -> MXRoomListDataFetcher {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [.invited], paginate: false)
        updateInvitedFetcher(fetcher, for: .rooms)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }
    
    private func createDirectRoomListDataFetcherForHome() -> MXRoomListDataFetcher {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [.direct], paginate: false)
        updateDirectFetcher(fetcher, for: .home)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }
    
    private func createDirectRoomListDataFetcherForPeople() -> MXRoomListDataFetcher {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [.direct], paginate: false)
        updateDirectFetcher(fetcher, for: .people)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }
    
    private func createConversationRoomListDataFetcherForHome() -> MXRoomListDataFetcher {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [], paginate: false)
        updateConversationFetcher(fetcher, for: .home)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }
    
    private func createConversationRoomListDataFetcherForAllChats() -> MXRoomListDataFetcher {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [], paginate: false)
        updateConversationFetcher(fetcher, for: .allChats)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }
    
    private func createConversationRoomListDataFetcherForRooms() -> MXRoomListDataFetcher {
        let fetcher = createCommonRoomListDataFetcher(withDataTypes: [], paginate: false)
        updateConversationFetcher(fetcher, for: .rooms)
        fetcher.addDelegate(self)
        fetcher.paginate()
        return fetcher
    }
    
    private func createFetchers() {
        guard fetchersCreated == false else {
            removeSessionStateObserver()
            return
        }
        guard let session = session else {
            return
        }
        guard session.state != .closed else {
            MXLog.debug("[RecentsListService] createFetchers cancelled on closed session")
            return
        }
        guard session.roomListDataManager != nil else {
            MXLog.debug("[RecentsListService] createFetchers cancelled on race condition (session closing in progress)")
            return
        }
        guard session.isEventStreamInitialised else {
            return
        }
        if !hideInvitedSection {
            invitedRoomListDataFetcherForHome = createCommonRoomListDataFetcher(withDataTypes: [.invited])
            invitedRoomListDataFetcherForPeople = createInvitedRoomListDataFetcherForPeople()
            invitedRoomListDataFetcherForRooms = createInvitedRoomListDataFetcherForRooms()
        }
        favoritedRoomListDataFetcher = createCommonRoomListDataFetcher(withDataTypes: [.favorited])
        directRoomListDataFetcherForHome = createDirectRoomListDataFetcherForHome()
        directRoomListDataFetcherForPeople = createDirectRoomListDataFetcherForPeople()
        conversationRoomListDataFetcherForHome = createConversationRoomListDataFetcherForHome()
        conversationRoomListDataFetcherForRooms = createConversationRoomListDataFetcherForRooms()
        lowPriorityRoomListDataFetcher = createCommonRoomListDataFetcher(withDataTypes: [.lowPriority])
        serverNoticeRoomListDataFetcher = createCommonRoomListDataFetcher(withDataTypes: [.serverNotice])
        suggestedRoomListDataFetcher = createCommonRoomListDataFetcher(onlySuggested: true)
        breadcrumbsRoomListDataFetcher = createCommonRoomListDataFetcher(onlyBreadcrumbs: true)
        allChatsRoomListDataFetcher = createConversationRoomListDataFetcherForAllChats()
        
        fetchersCreated = true
        removeSessionStateObserver()
    }
    
    private func updateDirectFetcher(_ fetcher: MXRoomListDataFetcher, for mode: RecentsDataSourceMode) {
        var notDataTypes: MXRoomSummaryDataTypes = [.hidden, .conferenceUser, .space, .invited, .lowPriority]
            switch mode {
            case .home:
                notDataTypes.insert(.favorited)
                fetcher.fetchOptions.filterOptions.notDataTypes = notDataTypes
            case .people:
                fetcher.fetchOptions.filterOptions.notDataTypes = notDataTypes
            default:
                break
            }
        }

    private func updateInvitedFetcher(_ fetcher: MXRoomListDataFetcher, for mode: RecentsDataSourceMode) {
        var notDataTypes: MXRoomSummaryDataTypes = [.hidden, .conferenceUser, .lowPriority, .serverNotice, .space]
        switch mode {
        case .people:
            fetcher.fetchOptions.filterOptions.notDataTypes = notDataTypes
        case .rooms:
            notDataTypes.insert([.direct])
            fetcher.fetchOptions.filterOptions.notDataTypes = notDataTypes
        default:
            break
        }
    }
    
    private func updateFavoritedFetcher(_ fetcher: MXRoomListDataFetcher, for mode: RecentsDataSourceMode) {
        switch mode {
        case .home:
            if fetcher.fetchOptions.filterOptions.onlyBreadcrumbs {
                fetcher.fetchOptions.sortOptions = noSortOptions
            } else {
                fetcher.fetchOptions.sortOptions = sortOptions
            }
        case .favourites:
            var newSortOptions = sortOptions
            newSortOptions.favoriteTag = true
            fetcher.fetchOptions.sortOptions = newSortOptions
        default:
            break
        }
    }
    
    private func updateConversationFetcher(_ fetcher: MXRoomListDataFetcher, for mode: RecentsDataSourceMode) {
        var notDataTypes: MXRoomSummaryDataTypes = mode == .allChats ? [.hidden, .conferenceUser, .invited, .lowPriority, .serverNotice, .space] : [.hidden, .conferenceUser, .direct, .invited, .lowPriority, .serverNotice, .space]

        switch mode {
        case .home:
            notDataTypes.insert(.favorited)
            
            fetcher.fetchOptions.filterOptions.notDataTypes = notDataTypes
        case .rooms:
            fetcher.fetchOptions.filterOptions.notDataTypes = notDataTypes
        case .allChats:
            let settingsManager = AllChatsLayoutSettingsManager.shared
            let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
            if settings.sections.contains(.favourites) && !settings.filters.contains(.favourites) {
                notDataTypes.insert(.favorited)
            }
            if settings.filters.contains(.rooms) && settingsManager.activeFilters.contains(.rooms) {
                notDataTypes.insert(.direct)
            }
            fetcher.fetchOptions.filterOptions.notDataTypes = notDataTypes
            
            if settings.filters.contains(.unreads) && settingsManager.activeFilters.contains(.unreads) {
                fetcher.fetchOptions.filterOptions.dataTypes = [.unread]
                return
            }
            if settings.filters.contains(.people) && settingsManager.activeFilters.contains(.people) {
                fetcher.fetchOptions.filterOptions.dataTypes = [.direct]
                return
            }
            if settings.filters.contains(.favourites) && settingsManager.activeFilters.contains(.favourites) {
                fetcher.fetchOptions.filterOptions.dataTypes = [.favorited]
                return
            }
            fetcher.fetchOptions.filterOptions.dataTypes = []
        default:
            break
        }
    }
    
    private func notifyDataChange(on fetcher: MXRoomListDataFetcher, totalCountsChanged: Bool) {
        if let section = section(forFetcher: fetcher) {
            multicastDelegate.invoke { $0.recentsListServiceDidChangeData?(self,
                                                                           forSection: section,
                                                                           totalCountsChanged: totalCountsChanged) }
        } else {
            multicastDelegate.invoke { $0.recentsListServiceDidChangeData?(self,
                                                                           totalCountsChanged: totalCountsChanged) }
        }
    }
    
    deinit {
        if let observer = allChatLayoutSettingsManagerObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = allChatLayoutSettingsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        stop()
    }
    
}

//  MARK: - MXRoomListDataFetcherDelegate

extension RecentsListService: MXRoomListDataFetcherDelegate {
    
    public func fetcherDidChangeData(_ fetcher: MXRoomListDataFetcher, totalCountsChanged: Bool) {
        notifyDataChange(on: fetcher, totalCountsChanged: totalCountsChanged)
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
    static let breadcrumbs = FetcherTypes(rawValue: 1 << 9)
    static let allChats = FetcherTypes(rawValue: 1 << 10)

    static let none: FetcherTypes = []
    static let all: FetcherTypes = [
        .invited, .favorited, .directHome, .directPeople, .conversationHome, .conversationRooms, .lowPriority, .serverNotice, .suggested, .breadcrumbs, .allChats]
}
