// File created from ScreenTemplate
// $ createScreen.sh Modal2/RoomCreation RoomCreationEventsModal
/*
 Copyright 2020 New Vector Ltd
 
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

import Foundation

final class RoomCreationEventsModalViewModel: RoomCreationEventsModalViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let roomState: MXRoomState
    private lazy var eventFormatter: EventFormatter = {
        return EventFormatter(matrixSession: self.session)
    }()
    private var events: [MXEvent] = []
    private var roomCreateEvent: MXEvent?
    
    // MARK: Public

    weak var viewDelegate: RoomCreationEventsModalViewModelViewDelegate?
    weak var coordinatorDelegate: RoomCreationEventsModalViewModelCoordinatorDelegate?
    
    var numberOfRows: Int {
        return events.count
    }
    
    func rowViewModel(at indexPath: IndexPath) -> RoomCreationEventRowViewModel? {
        let event = events[indexPath.row]
        let formatterError = UnsafeMutablePointer<MXKEventFormatterError>.allocate(capacity: 1)
        if let string = eventFormatter.attributedString(from: event,
                                                        with: roomState,
                                                        andLatestRoomState: nil,
                                                        error: formatterError) {
            if string.string.hasPrefix("·") {
                return RoomCreationEventRowViewModel(title: string)
            }
            let mutableString = NSMutableAttributedString(attributedString: string)
            mutableString.insert(NSAttributedString(string: "· "), at: 0)
            return RoomCreationEventRowViewModel(title: mutableString)
        }
        return RoomCreationEventRowViewModel(title: nil)
    }
    
    var roomName: String? {
        guard let summary = session.roomSummary(withRoomId: roomState.roomId) else {
            return nil
        }
        return summary.displayname
    }
    
    var roomInfo: String? {
        guard let creationEvent = roomCreateEvent else {
            return nil
        }
        let timestamp = creationEvent.originServerTs
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp/1000))
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    func setAvatar(in avatarImageView: MXKImageView) {
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: roomState.roomId, withDisplayName: roomName)
        
        if let avatarUrl = roomState.avatar ?? session.roomSummary(withRoomId: roomState.roomId)?.avatar {
            avatarImageView.enableInMemoryCache = true

            avatarImageView.setImageURI(avatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: avatarImageView.frame.size,
                                        with: MXThumbnailingMethodCrop,
                                        previewImage: avatarImage,
                                        mediaManager: session.mediaManager)
        } else {
            avatarImageView.image = avatarImage
        }
    }
    
    func setEncryptionIcon(in imageView: UIImageView) {
        guard let summary = session.roomSummary(withRoomId: roomState.roomId) else {
            imageView.image = nil
            imageView.isHidden = true
            return
        }
        
        if summary.isEncrypted {
            imageView.isHidden = false
            imageView.image = EncryptionTrustLevelBadgeImageHelper.roomBadgeImage(for: summary.roomEncryptionTrustLevel())
        } else {
            imageView.isHidden = true
        }
    }
    
    // MARK: - Setup
    
    init(session: MXSession, roomState: MXRoomState) {
        self.session = session
        self.roomState = roomState
    }
    
    // MARK: - Public
    
    func process(viewAction: RoomCreationEventsModalViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .close:
            self.coordinatorDelegate?.roomCreationEventsModalViewModelDidTapClose(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        events.removeAll()
        
        //  shape-up events
        for event in roomState.stateEvents {
            let formatterError = UnsafeMutablePointer<MXKEventFormatterError>.allocate(capacity: 1)
            let eventString = eventFormatter.attributedString(from: event,
                                                              with: roomState,
                                                              andLatestRoomState: nil,
                                                              error: formatterError)
            guard shouldDisplay(event), eventString != nil, formatterError.pointee == MXKEventFormatterErrorNone else {
                continue
            }
            
            // we replace previous event of the same type to keep the latest one.
            if events.last?.eventType == event.eventType {
                events.removeLast()
            }
            events.append(event)
        }
        
        roomCreateEvent = events.first(where: { $0.eventType == .roomCreate })

        //  remove room create event from the list, as EW and ElA do. This will also avoid duplication of "%@ joined" messages for direct rooms.
        events.removeAll(where: { $0.eventType == .roomCreate })

        self.update(viewState: .loaded)
    }
    
    private func shouldDisplay(_ event: MXEvent) -> Bool {
        return event.eventType != .roomPowerLevels
    }
    
    private func update(viewState: RoomCreationEventsModalViewState) {
        self.viewDelegate?.roomCreationEventsModalViewModel(self, didUpdateViewState: viewState)
    }
    
}
