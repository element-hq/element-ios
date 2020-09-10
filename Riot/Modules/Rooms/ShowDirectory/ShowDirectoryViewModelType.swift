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

protocol ShowDirectoryViewModelViewDelegate: class {
    func showDirectoryViewModel(_ viewModel: ShowDirectoryViewModelType, didUpdateViewState viewSate: ShowDirectoryViewState)
    func showDirectoryViewModelDidUpdateDataSource(_ viewModel: ShowDirectoryViewModelType)
}

protocol ShowDirectoryViewModelCoordinatorDelegate: class {
    func showDirectoryViewModelDidSelect(_ viewModel: ShowDirectoryViewModelType, room: MXPublicRoom)
    func showDirectoryViewModelDidTapCreateNewRoom(_ viewModel: ShowDirectoryViewModelType)
    func showDirectoryViewModelDidCancel(_ viewModel: ShowDirectoryViewModelType)
    func showDirectoryViewModelWantsToShow(_ viewModel: ShowDirectoryViewModelType, controller: UIViewController)
}

/// Protocol describing the view model used by `ShowDirectoryViewController`
protocol ShowDirectoryViewModelType {        
        
    var viewDelegate: ShowDirectoryViewModelViewDelegate? { get set }
    var coordinatorDelegate: ShowDirectoryViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: ShowDirectoryViewAction)
    
    var roomsCount: Int { get }
    var directoryServerDisplayname: String? { get }
    func roomViewModel(at indexPath: IndexPath) -> DirectoryRoomTableViewCellVM?
}
