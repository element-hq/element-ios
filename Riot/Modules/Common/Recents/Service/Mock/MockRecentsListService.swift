// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
public class MockRecentsListService: NSObject, RecentsListServiceProtocol {
    
    private var rooms: [MockRoomSummary]
    
    private var _invitedRoomListData: MXRoomListData?
    private var _favoritedRoomListData: MXRoomListData?
    private var _peopleRoomListData: MXRoomListData?
    private var _conversationRoomListData: MXRoomListData?
    private var _lowPriorityRoomListData: MXRoomListData?
    private var _serverNoticeRoomListData: MXRoomListData?
    private var _recentsRoomListData: MXRoomListData?
    private var _allChatsRoomListData: MXRoomListData?
    
    // swiftlint:disable weak_delegate
    private let multicastDelegate: MXMulticastDelegate<RecentsListServiceDelegate> = MXMulticastDelegate()
    // swiftlint:enable weak_delegate
    
    public init(withRooms rooms: [MockRoomSummary]) {
        self.rooms = rooms
        
        var invited: [MockRoomSummary] = []
        var favorited: [MockRoomSummary] = []
        var people: [MockRoomSummary] = []
        var conversation: [MockRoomSummary] = []
        var lowPriority: [MockRoomSummary] = []
        var serverNotice: [MockRoomSummary] = []
        
        rooms.forEach { summary in
            if summary.isTyped(.invited) {
                invited.append(summary)
            }
            if summary.isTyped(.favorited) {
                favorited.append(summary)
            }
            if summary.isTyped(.direct) {
                people.append( summary)
            }
            if !summary.isTyped([.direct,
                                .invited,
                                .favorited,
                                .lowPriority,
                                .serverNotice]) {
                conversation.append(summary)
            }
            if summary.isTyped(.lowPriority) {
                lowPriority.append(summary)
            }
            if summary.isTyped(.serverNotice) {
                serverNotice.append(summary)
            }
        }
        _invitedRoomListData = MockRoomListData(withRooms: invited)
        _favoritedRoomListData = MockRoomListData(withRooms: favorited)
        _peopleRoomListData = MockRoomListData(withRooms: people)
        _conversationRoomListData = MockRoomListData(withRooms: conversation)
        _lowPriorityRoomListData = MockRoomListData(withRooms: lowPriority)
        _serverNoticeRoomListData = MockRoomListData(withRooms: serverNotice)
        _recentsRoomListData = MockRoomListData(withRooms: conversation)
        _allChatsRoomListData = MockRoomListData(withRooms: conversation)
        
        super.init()
    }
    
    public static func generate(withNumberOfRooms numberOfRooms: Int) -> MockRecentsListService {
        var rooms: [MockRoomSummary] = []
        for i in 0..<numberOfRooms {
            let room = MockRoomSummary(withRoomId: "!room_\(i+1):matrix.org")
            if i % 2 == 0 {
                room.dataTypes = .direct
            } else if i % 3 == 0 {
                room.dataTypes = .favorited
            } else if i % 5 == 0 {
                room.dataTypes = .lowPriority
            } else if i % 7 == 0 {
                room.dataTypes = .invited
            } else if i % 11 == 0 {
                room.dataTypes = .serverNotice
            }
            room.displayName = "Room \(i+1)"
            if let event = MXEvent(fromJSON: [
                "event_id": MXTools.generateTransactionId() as Any,
                "room_id": room.roomId,
                "type": kMXEventTypeStringRoomMessage,
                "origin_server_ts": Date().timeIntervalSince1970,
                "content": [
                    "type": kMXMessageTypeText,
                    "content": "Message \(i+1)"
                ]
            ]) {
                room.lastMessage = MXRoomLastMessage(event: event)
            }
            rooms.append(room)
        }
        return MockRecentsListService(withRooms: rooms)
    }
    
    public weak var session: MXSession?
    
    public var mode: RecentsDataSourceMode = .home
    
    public var query: String?
    
    public var space: MXSpace?
    
    public var invitedRoomListData: MXRoomListData? {
        guard mode == .home else { return nil }
        return _invitedRoomListData
    }
    
    public var favoritedRoomListData: MXRoomListData? {
        guard mode == .home || mode == .favourites else { return nil }
        return _favoritedRoomListData
    }
    
    public var peopleRoomListData: MXRoomListData? {
        guard mode == .home || mode == .people else { return nil }
        return _peopleRoomListData
    }
    
    public var conversationRoomListData: MXRoomListData? {
        guard mode == .home || mode == .rooms else { return nil }
        return _conversationRoomListData
    }
    
    public var lowPriorityRoomListData: MXRoomListData? {
        guard mode == .home else { return nil }
        return _lowPriorityRoomListData
    }
    
    public var serverNoticeRoomListData: MXRoomListData? {
        guard mode == .home else { return nil }
        return _serverNoticeRoomListData
    }
    
    public var suggestedRoomListData: MXRoomListData?
    
    public var breadcrumbsRoomListData: MXRoomListData?
    
    public var allChatsRoomListData: MXRoomListData?

    public var favoritedMissedDiscussionsCount: DiscussionsCount = .zero
    
    public var peopleMissedDiscussionsCount: DiscussionsCount = .zero
    
    public var conversationMissedDiscussionsCount: DiscussionsCount = .zero
    
    public var totalVisibleItemCount: Int {
        switch mode {
        case .home:
            return rooms.count
        case .favourites:
            return favoritedRoomListData?.counts.numberOfRooms ?? 0
        case .people:
            return peopleRoomListData?.counts.numberOfRooms ?? 0
        case .rooms:
            return conversationRoomListData?.counts.numberOfRooms ?? 0
        case .allChats:
            return allChatsRoomListData?.counts.numberOfRooms ?? 0
        @unknown default:
            return 0
        }
    }
    
    public func paginate(inSection section: RecentsListServiceSection) {
        //  no-op
    }
    
    public func updateMode(_ mode: RecentsDataSourceMode) {
        self.mode = mode
        notifyDataChange()
    }
    
    public func updateQuery(_ query: String?) {
        notifyDataChange()
    }
    
    public func updateSpace(_ space: MXSpace?) {
        notifyDataChange()
    }
    
    public func refresh() {
        notifyDataChange()
    }
    
    public func stop() {
        _invitedRoomListData = nil
        _favoritedRoomListData = nil
        _peopleRoomListData = nil
        _conversationRoomListData = nil
        _lowPriorityRoomListData = nil
        _serverNoticeRoomListData = nil
        _recentsRoomListData = nil
        _allChatsRoomListData = nil
        removeAllDelegates()
    }
    
    public func addDelegate(_ delegate: RecentsListServiceDelegate) {
        multicastDelegate.addDelegate(delegate)
    }
    
    public func removeDelegate(_ delegate: RecentsListServiceDelegate) {
        multicastDelegate.removeDelegate(delegate)
    }
    
    public func removeAllDelegates() {
        multicastDelegate.removeAllDelegates()
    }
    
    private func notifyDataChange() {
        multicastDelegate.invoke({ $0.recentsListServiceDidChangeData?(self, totalCountsChanged: true) })
    }
    
    public func stopUncompletedVoiceBroadcastIfNeeded(for listData: MatrixSDK.MXRoomListData?) {
        // nothing here
    }
}
