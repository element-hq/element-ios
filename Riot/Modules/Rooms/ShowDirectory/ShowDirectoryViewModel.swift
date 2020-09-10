// File created from ScreenTemplate
// $ createScreen.sh Rooms/ShowDirectory ShowDirectory
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

final class ShowDirectoryViewModel: NSObject, ShowDirectoryViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let dataSource: PublicRoomsDirectoryDataSource
    
    private var currentOperation: MXHTTPOperation?
    private var userDisplayName: String?
    
    // MARK: Public

    weak var viewDelegate: ShowDirectoryViewModelViewDelegate?
    weak var coordinatorDelegate: ShowDirectoryViewModelCoordinatorDelegate?
    
    var roomsCount: Int {
        return Int(dataSource.roomsCount)
    }
    var directoryServerDisplayname: String? {
        return dataSource.directoryServerDisplayname
    }
    func roomViewModel(at indexPath: IndexPath) -> DirectoryRoomTableViewCellVM? {
        guard let room = dataSource.room(at: indexPath) else { return nil }
        let summary = session.roomSummary(withRoomId: room.roomId)
        
        return DirectoryRoomTableViewCellVM(title: room.displayname(),
                                            numberOfUsers: room.numJoinedMembers,
                                            subtitle: MXTools.stripNewlineCharacters(room.topic),
                                            isJoined: summary?.membership == .join,
                                            roomId: room.roomId,
                                            avatarUrl: room.avatarUrl,
                                            mediaManager: session.mediaManager)
    }
    
    // MARK: - Setup
    
    init(session: MXSession, dataSource: PublicRoomsDirectoryDataSource) {
        self.session = session
        self.dataSource = dataSource
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: ShowDirectoryViewAction) {
        switch viewAction {
        case .loadData(let force):
            self.loadData(force: force)
        case .selectRoom(let indexPath):
            guard let room = dataSource.room(at: indexPath) else { return }
            self.coordinatorDelegate?.showDirectoryViewModelDidSelect(self, room: room)
        case .joinRoom(let indexPath):
            guard let room = dataSource.room(at: indexPath) else { return }
            joinRoom(room)
        case .search(let pattern):
            self.dataSource.searchPattern = pattern
            self.loadData(force: true)
        case .createNewRoom:
            self.coordinatorDelegate?.showDirectoryViewModelDidTapCreateNewRoom(self)
        case .switchServer:
            self.switchServer()
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.showDirectoryViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData(force: Bool) {
        if !force && (dataSource.hasReachedPaginationEnd || currentOperation != nil) {
            // We got all public rooms or we are already paginating
            // Do nothing
            return
        }
        
        self.update(viewState: .loading)
        
        currentOperation = dataSource.paginate({ [weak self] (roomsAdded) in
            guard let self = self else { return }
            if roomsAdded > 0 {
                self.viewDelegate?.showDirectoryViewModelDidUpdateDataSource(self)
            }
            self.update(viewState: .loaded)
            self.currentOperation = nil
        }, failure: { [weak self] (error) in
            guard let self = self else { return }
            guard let error = error else { return }
            self.update(viewState: .error(error))
            self.currentOperation = nil
        })
    }
    
    private func switchServer() {
        let controller = DirectoryServerPickerViewController()
        let source = MXKDirectoryServersDataSource(matrixSession: session)
        source?.finalizeInitialization()
        source?.roomDirectoryServers = BuildSettings.publicRoomsDirectoryServers

        controller.display(with: source) { [weak self] (cellData) in
            guard let self = self else { return }
            guard let cellData = cellData else { return }

            if let thirdpartyProtocolInstance = cellData.thirdPartyProtocolInstance {
                self.dataSource.thirdpartyProtocolInstance = thirdpartyProtocolInstance
            } else if let homeserver = cellData.homeserver {
                self.dataSource.includeAllNetworks = cellData.includeAllNetworks
                self.dataSource.homeserver = homeserver
            }

            self.loadData(force: false)
        }

        self.coordinatorDelegate?.showDirectoryViewModelWantsToShow(self, controller: controller)
    }
    
    private func joinRoom(_ room: MXPublicRoom) {
        session.joinRoom(room.roomId) { [weak self] (response) in
            guard let self = self else { return }
            self.viewDelegate?.showDirectoryViewModelDidUpdateDataSource(self)
        }
    }
    
    private func update(viewState: ShowDirectoryViewState) {
        self.viewDelegate?.showDirectoryViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}

// MARK: - MXKDataSourceDelegate

extension ShowDirectoryViewModel: MXKDataSourceDelegate {
    
    func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        return nil
    }
    
    func cellReuseIdentifier(for cellData: MXKCellData!) -> String! {
        return nil
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didCellChange changes: Any!) {
        
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didStateChange state: MXKDataSourceState) {
        self.viewDelegate?.showDirectoryViewModelDidUpdateDataSource(self)
    }
    
}
