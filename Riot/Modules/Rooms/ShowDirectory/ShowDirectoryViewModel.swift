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

enum ShowDirectorySection {
    case searchInput(_ searchInputViewData: DirectoryRoomTableViewCellVM)
    case publicRoomsDirectory(_ viewModel: PublicRoomsDirectoryViewModel)
}

final class ShowDirectoryViewModel: NSObject, ShowDirectoryViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let dataSource: PublicRoomsDirectoryDataSource
    
    private let publicRoomsDirectoryViewModel: PublicRoomsDirectoryViewModel
    
    private var currentOperation: MXHTTPOperation?
    private var sections: [ShowDirectorySection] = []
    
    private var canPaginatePublicRoomsDirectory: Bool {
        return !dataSource.hasReachedPaginationEnd && currentOperation == nil
    }
    
    private var publicRoomsDirectorySection: ShowDirectorySection {
        return .publicRoomsDirectory(self.publicRoomsDirectoryViewModel)
    }
    
    // Last room id or room alias search
    private var lastSearchInputViewData: DirectoryRoomTableViewCellVM?
    
    // MARK: Public

    weak var viewDelegate: ShowDirectoryViewModelViewDelegate?
    weak var coordinatorDelegate: ShowDirectoryViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, dataSource: PublicRoomsDirectoryDataSource) {
        self.session = session
        self.dataSource = dataSource
        self.publicRoomsDirectoryViewModel = PublicRoomsDirectoryViewModel(dataSource: dataSource, session: session)
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: ShowDirectoryViewAction) {
        switch viewAction {
        case .loadData:
            self.resetSections()
            self.paginatePublicRoomsDirectory(force: false)
        case .selectRoom(let indexPath):
            
            let directorySection = self.sections[indexPath.section]
            
            switch directorySection {
            case .searchInput(let viewData):
                self.coordinatorDelegate?.showDirectoryViewModel(self, didSelectRoomWithIdOrAlias: viewData.roomId)
            case .publicRoomsDirectory:
                guard let publicRoom = self.publicRoom(at: indexPath.row) else { return }
                self.coordinatorDelegate?.showDirectoryViewModelDidSelect(self, room: publicRoom)
            }
        case .joinRoom(let indexPath):
            
            let directorySection = self.sections[indexPath.section]
            let roomIdOrAlias: String?
            
            switch directorySection {
            case .searchInput(let searchInputViewData):
                roomIdOrAlias = searchInputViewData.roomId
            case .publicRoomsDirectory:
                let publicRoom = self.publicRoom(at: indexPath.row)
                roomIdOrAlias = publicRoom?.roomId
            }
            
            if let roomIdOrAlias = roomIdOrAlias {
                joinRoom(withRoomIdOrAlias: roomIdOrAlias)
            }
        case .search(let pattern):
            self.search(with: pattern)
        case .createNewRoom:
            self.coordinatorDelegate?.showDirectoryViewModelDidTapCreateNewRoom(self)
        case .switchServer:
            self.switchServer()
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.showDirectoryViewModelDidCancel(self)
        }
    }
    
    func updatePublicRoomsDataSource(with cellData: MXKDirectoryServerCellDataStoring) {
        if let thirdpartyProtocolInstance = cellData.thirdPartyProtocolInstance {
            self.dataSource.thirdpartyProtocolInstance = thirdpartyProtocolInstance
        } else if let homeserver = cellData.homeserver {
            self.dataSource.includeAllNetworks = cellData.includeAllNetworks
            self.dataSource.homeserver = homeserver
        }
        
        self.resetSections()
        self.paginatePublicRoomsDirectory(force: false)
    }
    
    // MARK: - Private
    
    private func paginatePublicRoomsDirectory(force: Bool) {
        if !force && !self.canPaginatePublicRoomsDirectory {
            // We got all public rooms or we are already paginating
            // Do nothing
            return
        }
        
        self.update(viewState: .loading)
        
        // Useful only when force is true
        self.cancelOperations()
        
        currentOperation = dataSource.paginate({ [weak self] (roomsAdded) in
            guard let self = self else { return }
            self.update(viewState: .loaded(self.sections))
            self.currentOperation = nil
        }, failure: { [weak self] (error) in
            guard let self = self else { return }
            guard let error = error else { return }
            self.update(viewState: .error(error))
            self.currentOperation = nil
        })
    }
    
    private func resetSections() {
        self.lastSearchInputViewData = nil
        self.updateSectionsIfNeeded()
    }
    
    private func switchServer() {
        self.coordinatorDelegate?.showDirectoryViewModelWantsToShowDirectoryServerPicker(self)
    }
    
    private func joinRoom(withRoomIdOrAlias roomIdOrAlias: String) {
        session.joinRoom(roomIdOrAlias) { [weak self] (response) in
            guard let self = self else { return }
            switch response {
            case .success:
                self.updateSectionsIfNeeded()
                self.update(viewState: .loaded(self.sections))
            case .failure(let error):
                self.update(viewState: .error(error))
            }
        }
    }
    
    private func publicRoom(at row: Int) -> MXPublicRoom? {
        return dataSource.room(at: IndexPath(row: row, section: 0))
    }
    
    private func search(with pattern: String?) {
        self.dataSource.searchPattern = pattern
        
        var sections: [ShowDirectorySection] = []
        
        var shouldUpdate = false
                
        // If the search text is a room id or alias we add search input entry in sections
        if let searchText = pattern, let searchInputViewData = self.searchInputViewData(from: searchText) {
            sections.append(.searchInput(searchInputViewData))
            
            self.lastSearchInputViewData = searchInputViewData
            shouldUpdate = true
        } else {
            self.lastSearchInputViewData = nil
        }
        
        sections.append(self.publicRoomsDirectorySection)
        
        self.sections = sections
        
        if shouldUpdate {
            self.update(viewState: .loaded(self.sections))
        }
        
        self.paginatePublicRoomsDirectory(force: true)
    }
    
    private func updateSectionsIfNeeded() {
                      
        var sections: [ShowDirectorySection] = []
        
        // Refresh search input view data if needed
        // Useful when a room has been joined
        if let lastSearchInputViewData = self.lastSearchInputViewData, let newSearchInputViewData = self.searchInputViewData(from: lastSearchInputViewData.roomId) {
            sections.append(.searchInput(newSearchInputViewData))
        }
        
        sections.append(self.publicRoomsDirectorySection)
        
        self.sections = sections
    }
    
    private func searchInputViewData(from searchText: String) -> DirectoryRoomTableViewCellVM? {
        guard MXTools.isMatrixRoomAlias(searchText) || MXTools.isMatrixRoomIdentifier(searchText) else {
            return nil
        }
        
        let roomIdOrAlias = searchText
        
        let searchInputViewData: DirectoryRoomTableViewCellVM
        
        if let room = self.session.vc_room(withIdOrAlias: roomIdOrAlias) {
            searchInputViewData = self.roomCellViewModel(with: room)
        } else {
            searchInputViewData = self.roomCellViewModel(with: roomIdOrAlias)
        }
        
        return searchInputViewData
    }
    
    private func roomCellViewModel(with room: MXRoom) -> DirectoryRoomTableViewCellVM {
        let displayName = room.summary.displayName
        let joinedMembersCount = Int(room.summary.membersCount.joined)
        let topic = MXTools.stripNewlineCharacters(room.summary.topic)
        let isJoined = room.summary.membership == .join || room.summary.membershipTransitionState == .joined
        let avatarStringUrl = room.summary.avatar
        let mediaManager: MXMediaManager = self.session.mediaManager
        
        return DirectoryRoomTableViewCellVM(title: displayName, numberOfUsers: joinedMembersCount, subtitle: topic, isJoined: isJoined, roomId: room.roomId, avatarUrl: avatarStringUrl, mediaManager: mediaManager)
    }
    
    private func roomCellViewModel(with roomIdOrAlias: String) -> DirectoryRoomTableViewCellVM {
        
        let directoryRoomTableViewCellVM: DirectoryRoomTableViewCellVM
        
        if let room = self.session.vc_room(withIdOrAlias: roomIdOrAlias) {
            directoryRoomTableViewCellVM = self.roomCellViewModel(with: room)
        } else {
            let displayName = roomIdOrAlias
            let mediaManager: MXMediaManager = self.session.mediaManager
            
            
            directoryRoomTableViewCellVM = DirectoryRoomTableViewCellVM(title: displayName, numberOfUsers: 0, subtitle: nil, isJoined: false, roomId: roomIdOrAlias, avatarUrl: nil, mediaManager: mediaManager)
        }
        
        return directoryRoomTableViewCellVM
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
        self.updateSectionsIfNeeded()
        self.update(viewState: .loaded(self.sections))
    }
    
}
