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
public class MockRecentsListService: NSObject, RecentsListServiceProtocol {
    private var rooms: [MockRoomSummary] = []
    
    // swiftlint:disable weak_delegate
    private let multicastDelegate: MXMulticastDelegate<RecentsListServiceDelegate> = MXMulticastDelegate()
    // swiftlint:enable weak_delegate
    
    public init(withRooms rooms: [MockRoomSummary]) {
        self.rooms = rooms
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
            room.displayname = "Room \(i+1)"
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
        return MockRoomListData(withRooms: rooms.filter({ $0.isTyped(.invited) }))
    }
    
    public var favoritedRoomListData: MXRoomListData? {
        guard mode == .home || mode == .favourites else { return nil }
        return MockRoomListData(withRooms: rooms.filter({ $0.isTyped(.favorited) }))
    }
    
    public var peopleRoomListData: MXRoomListData? {
        guard mode == .home || mode == .people else { return nil }
        return MockRoomListData(withRooms: rooms.filter({ $0.isTyped(.direct) }))
    }
    
    public var conversationRoomListData: MXRoomListData? {
        guard mode == .home || mode == .rooms else { return nil }
        let mockRooms = rooms.filter({ !$0.isTyped([.direct,
                                                    .invited,
                                                    .favorited,
                                                    .lowPriority,
                                                    .serverNotice])
        })
        return MockRoomListData(withRooms: mockRooms)
    }
    
    public var lowPriorityRoomListData: MXRoomListData? {
        guard mode == .home else { return nil }
        return MockRoomListData(withRooms: rooms.filter({ $0.isTyped(.lowPriority) }))
    }
    
    public var serverNoticeRoomListData: MXRoomListData? {
        guard mode == .home else { return nil }
        return MockRoomListData(withRooms: rooms.filter({ $0.isTyped(.serverNotice) }))
    }
    
    public var suggestedRoomListData: MXRoomListData?
    
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
        @unknown default:
            return 0
        }
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
        rooms.removeAll()
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
        multicastDelegate.invoke({ $0.serviceDidChangeData(self) })
    }
    
}
