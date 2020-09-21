// File created from ScreenTemplate
// $ createScreen.sh Room2/RoomInfo RoomInfoList
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

final class RoomInfoListViewModel: NSObject, RoomInfoListViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let room: MXRoom
    
    private var currentOperation: MXHTTPOperation?
    private var userDisplayName: String?
    
    private lazy var segmentedViewController: SegmentedViewController = {
        let controller = SegmentedViewController()
        
        let participants = RoomParticipantsViewController()
        participants.finalizeInit()
        participants.enableMention = true
        participants.mxRoom = self.room
        participants.delegate = self
        
        let files = RoomFilesViewController()
        files.finalizeInit()
        MXKRoomDataSource.load(withRoomId: self.room.roomId, andMatrixSession: self.session) { (dataSource) in
            guard let dataSource = dataSource as? MXKRoomDataSource else { return }
            dataSource.filterMessagesWithURL = true
            dataSource.finalizeInitialization()
            files.hasRoomDataSourceOwnership = true
            files.displayRoom(dataSource)
        }
        
        let settings = RoomSettingsViewController()
        settings.finalizeInit()
        settings.initWith(self.session, andRoomId: self.room.roomId)
        
        controller.title = VectorL10n.roomDetailsTitle
        controller.initWithTitles([
            VectorL10n.roomDetailsPeople,
            VectorL10n.roomDetailsFiles,
            VectorL10n.roomDetailsSettings
        ], viewControllers: [
            participants,
            files,
            settings
        ], defaultSelected: 0)
        controller.addMatrixSession(self.session)
        
        _ = controller.view
        
        return controller
    }()
    
    // MARK: Public

    weak var viewDelegate: RoomInfoListViewModelViewDelegate?
    weak var coordinatorDelegate: RoomInfoListViewModelCoordinatorDelegate?
    
    var numberOfMembers: Int {
        return Int(room.summary.membersCount.joined)
    }
    var isEncrypted: Bool {
        return room.summary.isEncrypted
    }
    var basicInfoViewModel: RoomInfoBasicTableViewCellVM {
        return self
    }
    var roomTopic: String? {
        return room.summary.topic
    }
    
    // MARK: - Setup
    
    init(session: MXSession, room: MXRoom) {
        self.session = session
        self.room = room
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: RoomInfoListViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .navigate(let target):
            self.navigate(to: target)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.roomInfoListViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        self.update(viewState: .loaded)
    }
    
    private func navigate(to target: RoomInfoListTarget) {
        switch target {
        case .settings:
            let controller = segmentedViewController
            controller.selectedIndex = 2
            self.coordinatorDelegate?.roomInfoListViewModel(self, wantsToNavigate: controller)
        case .members:
            let controller = segmentedViewController
            controller.selectedIndex = 0
            self.coordinatorDelegate?.roomInfoListViewModel(self, wantsToNavigate: controller)
        case .uploads:
            let controller = segmentedViewController
            controller.selectedIndex = 1
            self.coordinatorDelegate?.roomInfoListViewModel(self, wantsToNavigate: controller)
        }
    }
    
    private func update(viewState: RoomInfoListViewState) {
        self.viewDelegate?.roomInfoListViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}

extension RoomInfoListViewModel: RoomInfoBasicTableViewCellVM {
    
    func setAvatar(in avatarImageView: MXKImageView) {
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: room.roomId, withDisplayName: room.summary.displayname)
        
        if let avatarUrl = room.summary.avatar ?? session.roomSummary(withRoomId: room.roomId)?.avatar {
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
        guard let summary = room.summary else {
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
    
    var roomName: String? {
        return room.summary.displayname
    }
    
    var roomAddress: String? {
        return room.summary.aliases?.first
    }
    
}

extension RoomInfoListViewModel: RoomParticipantsViewControllerDelegate {
    
    func roomParticipantsViewController(_ roomParticipantsViewController: RoomParticipantsViewController!, mention member: MXRoomMember!) {
        
    }
    
}
