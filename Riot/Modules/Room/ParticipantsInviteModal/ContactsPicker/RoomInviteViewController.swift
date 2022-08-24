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

class RoomInviteViewController: ContactsTableViewController {
    
    var room: MXRoom?
    private var roomAlias: String?
    private var joinRule: MXRoomJoinRule?
    
    private lazy var shareLinkPresenter: ShareInviteLinkPresenter = ShareInviteLinkPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomAlias = room?.summary?.aliases?.first
        joinRule = MXRoomJoinRule(identifier: room?.summary?.joinRule)
        setupShareInviteLinkHeader()
    }
    
    private func setupShareInviteLinkHeader() {
        guard roomAlias != nil,
              RiotSettings.shared.allowInviteExernalUsers,
              joinRule != .invite,
              joinRule != .restricted else {
            contactsTableView.tableHeaderView = nil
            return
        }
        
        let inviteHeaderView = ShareInviteLinkHeaderView.instantiate()
        inviteHeaderView.delegate = self
        contactsTableView.tableHeaderView = inviteHeaderView
    }
    
    private func showInviteLink(from sourceView: UIView?) {
        guard let room = room else {
            return
        }
        shareLinkPresenter.present(for: room, from: self, sourceView: sourceView, animated: true)
    }
}

// MARK: - ShareInviteLinkHeaderViewDelegate
extension RoomInviteViewController: ShareInviteLinkHeaderViewDelegate {
    func shareInviteLinkHeaderView(_ headerView: ShareInviteLinkHeaderView, didTapButton button: UIButton) {
        showInviteLink(from: button)
    }
}
