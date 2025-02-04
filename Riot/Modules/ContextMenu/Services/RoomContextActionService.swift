// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `RoomContextActionService` implements all the possible actions for an instance of `MXRoom`
class RoomContextActionService: NSObject, RoomContextActionServiceProtocol {
    
    // MARK: - RoomContextActionServiceProtocol

    private(set) var session: MXSession
    var roomId: String {
        return room.roomId
    }
    internal weak var delegate: RoomContextActionServiceDelegate?

    // MARK: - Properties
    
    private let room: MXRoom
    private let unownedRoomService: UnownedRoomContextActionService
    
    // MARK: - Setup
    
    init(room: MXRoom, delegate: RoomContextActionServiceDelegate?) {
        self.room = room
        self.delegate = delegate
        self.isRoomJoined = room.summary?.isJoined ?? false
        self.hasUnread = room.summary?.hasAnyUnread ?? false
        self.roomMembership = room.summary?.membership ?? .unknown
        self.session = room.mxSession
        self.unownedRoomService = UnownedRoomContextActionService(roomId: room.roomId, canonicalAlias: room.summary?.aliases?.first, session: self.session, delegate: delegate)
    }
    
    // MARK: - Public
    
    let isRoomJoined: Bool
    let hasUnread: Bool
    let roomMembership: MXMembership
    
    var isRoomDirect: Bool {
        get {
            return room.isDirect
        }
        set {
            delegate?.roomContextActionService(self, updateActivityIndicator: true)
            room.setIsDirect(newValue, withUserId: nil) { [weak self] in
                guard let self = self else { return }
                self.delegate?.roomContextActionService(self, updateActivityIndicator: false)
            } failure: { [weak self] error in
                guard let self = self else { return }
                self.delegate?.roomContextActionService(self, updateActivityIndicator: false)
                
                // Notify the end user
                if let userId = self.session.myUserId {
                    NotificationCenter.default.post(name: NSNotification.Name.mxkError, object: error, userInfo: [kMXKErrorUserIdKey: userId])
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name.mxkError, object: error)
                }
            }
        }
    }

    var isRoomMuted: Bool {
        get {
            return room.isMuted || room.isMentionsOnly
        }
        set {
            if BuildSettings.showNotificationsV2 {
                self.delegate?.roomContextActionService(self, showRoomNotificationSettingsForRoomWithId: room.roomId)
            } else {
                self.muteRoomNotifications(newValue)
            }
        }
    }
    
    var isRoomFavourite: Bool {
        get {
            let currentTag = room.accountData.tags?.values.first
            return currentTag?.name == kMXRoomTagFavourite
        }
        set {
            self.updateRoom(tag: newValue ? kMXRoomTagFavourite : nil)
        }
    }
    
    var isRoomLowPriority: Bool {
        get {
            let currentTag = room.accountData.tags?.values.first
            return currentTag?.name == kMXRoomTagLowPriority
        }
        set {
            self.updateRoom(tag: newValue ? kMXRoomTagLowPriority : nil)
        }
    }
    
    func markAsRead() {
        room.markAllAsRead()
        self.delegate?.roomContextActionServiceDidMarkRoom(self)
    }
    func markAsUnread() {
        room.setUnread()
        self.delegate?.roomContextActionServiceDidMarkRoom(self)
    }
    
    // MARK: - Private
    
    private func muteRoomNotifications(_ isMuted: Bool) {
        self.delegate?.roomContextActionService(self, updateActivityIndicator: true)
        if isMuted {
            room.mentionsOnly { [weak self] in
                guard let self = self else { return }
                self.delegate?.roomContextActionService(self, updateActivityIndicator: false)
            }
        } else {
            room.allMessages { [weak self] in
                guard let self = self else { return }
                self.delegate?.roomContextActionService(self, updateActivityIndicator: false)
            }
        }
    }
    
    private func updateRoom(tag: String?) {
        self.delegate?.roomContextActionService(self, updateActivityIndicator: true)
        room.setRoomTag(tag) {
            self.delegate?.roomContextActionService(self, updateActivityIndicator: false)
        }
    }
    
    func leaveRoom(promptUser: Bool) {
        guard promptUser else {
            self.leaveRoom()
            return
        }
        
        let title = room.isDirect ? VectorL10n.roomParticipantsLeavePromptTitleForDm : VectorL10n.roomParticipantsLeavePromptTitle
        let message = room.isDirect ? VectorL10n.roomParticipantsLeavePromptMsgForDm : VectorL10n.roomParticipantsLeavePromptMsg
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: VectorL10n.leave, style: .default, handler: { action in
            self.leaveRoom()
        }))
        self.delegate?.roomContextActionService(self, presentAlert: alertController)
    }

    func joinRoom() {
        unownedRoomService.joinRoom()
    }
    
    private func leaveRoom() {
        self.delegate?.roomContextActionService(self, updateActivityIndicator: true)
        // cancel pending uploads/downloads
        // they are useless by now
        MXMediaManager.cancelDownloads(inCacheFolder: self.room.roomId)
        
        // TODO: GFO cancel pending uploads related to this room
        
        MXLog.debug("[RoomContextActionService] leaving room \(self.room.roomId ?? "nil")")
        
        self.room.leave { [weak self] response in
            guard let self = self else { return }

            switch response {
            case .success:
                self.delegate?.roomContextActionService(self, updateActivityIndicator: false)
                self.delegate?.roomContextActionServiceDidLeaveRoom(self)
            case .failure(let error):
                self.delegate?.roomContextActionService(self, updateActivityIndicator: false)
                // Notify the end user
                if let userId = self.session.myUserId {
                    NotificationCenter.default.post(name: NSNotification.Name.mxkError, object: error, userInfo: [kMXKErrorUserIdKey: userId])
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name.mxkError, object: error)
                }
            }
        }
    }
}
