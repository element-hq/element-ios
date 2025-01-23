// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class ContactsPickerViewModel: NSObject, ContactsPickerViewModelProtocol {
    
    private class RoomMembers {
        var actualParticipants: [Contact] = []
        var invitedParticipants: [Contact] = []
        var userParticipant: Contact?
    }
    
    // MARK: - Properties
    
    weak var coordinatorDelegate: ContactsPickerViewModelCoordinatorDelegate?
    private(set) var areParticipantsLoaded: Bool = false

    // MARK: - Private
    
    private let room: MXRoom
    private var actualParticipants: [Contact]?
    private var invitedParticipants: [Contact]?
    private var userParticipant: Contact?

    // MARK: - Setup
    
    init(room: MXRoom, actualParticipants: [Contact]?, invitedParticipants: [Contact]?, userParticipant: Contact?) {
        self.room = room
        self.actualParticipants = actualParticipants
        self.invitedParticipants = invitedParticipants
        self.userParticipant = userParticipant
        
        areParticipantsLoaded = actualParticipants != nil && invitedParticipants != nil && userParticipant != nil

        super.init()
    }
    
    // MARK: - Public
    
    func loadParticipants() {
        coordinatorDelegate?.contactsPickerViewModelDidStartLoading(self)
        
        let roomMembers = RoomMembers()
        
        // Retrieve the current members from the room state
        room.state { [weak self] roomState in
            guard let self = self else {
                return
            }
            
            guard let roomState = roomState, let members = roomState.members.membersWithoutConferenceUser(), let session = self.room.mxSession, let myUserId = session.myUserId, let roomThirdPartyInvites = roomState.thirdPartyInvites else {
                self.finalize(participants: roomMembers)
                return
            }

            for member in members {
                if member.userId == myUserId {
                    if member.membership == .join || member.membership == .invite {
                        let displayName = VectorL10n.you
                        if let participant = Contact(matrixContactWithDisplayName: displayName, andMatrixID: myUserId) {
                            participant.mxMember = roomState.members.member(withUserId: myUserId)
                            roomMembers.userParticipant = participant
                        }
                    }
                } else {
                    self.handle(roomMember: member, session: session, members: roomMembers)
                }
            }
            
            for invite in roomThirdPartyInvites {
                self.add(thirdPartyParticipant: invite, roomState: roomState, members: roomMembers)
            }
            
            self.finalize(participants: roomMembers)
        }
    }
    
    func prepare(contactsViewController: RoomInviteViewController, currentSearchText: String?) -> Bool {
        contactsViewController.room = self.room

        // Set delegate to handle action on member (start chat, mention)
        contactsViewController.contactsTableViewControllerDelegate = self
        
        // Prepare its data source
        guard let contactsDataSource = ContactsDataSource(matrixSession: room.mxSession) else {
            MXLog.error("[ContactsPickerViewModel] prepare: failed to instantiate ContactsDataSource")
            return false
        }
        contactsDataSource.areSectionsShrinkable = true
        contactsDataSource.displaySearchInputInContactsList = true
        contactsDataSource.forceMatrixIdInDisplayName = true
        
        // Add a plus icon to the contact cell in the contacts picker, in order to make it more understandable for the end user.
        contactsDataSource.contactCellAccessoryImage = Asset.Images.plusIcon.image.vc_tintedImage(usingColor: ThemeService.shared().theme.textPrimaryColor)
        
        // List all the participants matrix user id to ignore them during the contacts search.
        for contact in actualParticipants ?? [] {
            if let userId = contact.mxMember.userId {
                contactsDataSource.ignoredContactsByMatrixId[userId] = contact
            }
        }
        
        for contact in invitedParticipants ?? [] {
            if let userId = contact.mxMember?.userId {
                contactsDataSource.ignoredContactsByMatrixId[userId] = contact
            }
        }
        
        if let userParticipantId = self.userParticipant?.mxMember.userId {
            contactsDataSource.ignoredContactsByMatrixId[userParticipantId] = userParticipant
        }
        
        contactsViewController.showSearch(true)
        contactsViewController.searchBar.placeholder = VectorL10n.roomParticipantsInviteAnotherUser
        contactsViewController.searchBar.resignFirstResponder()
        
        // Apply the search pattern if any
        if currentSearchText != nil {
            contactsViewController.searchBar.text = currentSearchText
            contactsDataSource.search(withPattern: currentSearchText, forceReset: true)
        }
        
        contactsViewController.displayList(contactsDataSource)
        
        return true
    }
    
    // MARK: - Private
    
    private func handle(roomMember: MXRoomMember, session: MXSession, members: RoomMembers) {
        // Add this member after checking his status
        guard roomMember.membership == .join || roomMember.membership == .invite else {
            return
        }
        
        // Prepare the display name of this member
        var displayName = roomMember.displayname
        if displayName.isEmptyOrNil {
            // Look for the corresponding MXUser in matrix session
            if let user = session.user(withUserId: roomMember.userId) {
                displayName = user.displayname.isEmptyOrNil ? user.userId : user.displayname
            } else {
                displayName = roomMember.userId
            }
        }
        
        // Create the contact related to this member
        if let contact = Contact(matrixContactWithDisplayName: displayName, andMatrixID: roomMember.userId) {
            contact.mxMember = roomMember
            
            if roomMember.membership == .invite {
                members.invitedParticipants.append(contact)
            } else {
                members.actualParticipants.append(contact)
            }
        }
    }
    
    private func add(thirdPartyParticipant invite: MXRoomThirdPartyInvite, roomState: MXRoomState, members: RoomMembers) {
        // If the homeserver has converted the 3pid invite into a room member, do no show it
        // If the invite has been revoked (null display name), do not show it too.
        guard let displayName = invite.displayname, roomState.member(withThirdPartyInviteToken: invite.token) == nil else {
            return
        }
        
        if let contact = Contact(matrixContactWithDisplayName: displayName, andMatrixID: nil) {
            contact.isThirdPartyInvite = true
            contact.mxThirdPartyInvite = invite
            members.invitedParticipants.append(contact)
        }
    }
    
    private func finalize(participants roomMembers: RoomMembers) {
        self.actualParticipants = roomMembers.actualParticipants
        self.invitedParticipants = roomMembers.invitedParticipants
        self.userParticipant = roomMembers.userParticipant
        self.coordinatorDelegate?.contactsPickerViewModelDidEndLoading(self)
    }
}

// MARK: - ContactsTableViewControllerDelegate
extension ContactsPickerViewModel: ContactsTableViewControllerDelegate {
    
    func contactsTableViewController(_ contactsTableViewController: ContactsTableViewController!, didSelect contact: MXKContact?) {
        guard let contact = contact else {
            MXLog.error("[ContactsPickerViewModel] contactsTableViewController: nil contact found")
            return
        }
        
        // Check for user
        if MXTools.isMatrixUserIdentifier(contact.displayName) {
            let user = MXUser(userId: contact.displayName)
            coordinatorDelegate?.contactsPickerViewModelDidStartValidatingUser(self)
            user?.update(fromHomeserverOfMatrixSession: self.room.mxSession, success: { [weak self] in
                guard let self = self else { return }
                self.coordinatorDelegate?.contactsPickerViewModelDidEndValidatingUser(self)
                self.displayInvitePrompt(contact: contact)
            }, failure: { [weak self] error in
                guard let self = self else { return }
                self.coordinatorDelegate?.contactsPickerViewModelDidEndValidatingUser(self)
                self.displayInvitePrompt(contact: contact, isUnknownUser: true)
            })
        } else {
            displayInvitePrompt(contact: contact)
        }
    }
    
    private func displayInvitePrompt(contact: MXKContact, isUnknownUser: Bool = false) {
        let roomName = room.displayName ?? VectorL10n.spaceTag
        let message = isUnknownUser ? VectorL10n.roomParticipantsInviteUnknownParticipantPromptToMsg(contact.displayName, roomName) : VectorL10n.roomParticipantsInvitePromptToMsg(contact.displayName, roomName)
        let inviteActionTitle = isUnknownUser ? VectorL10n.roomParticipantsInviteAnyway : VectorL10n.invite
        coordinatorDelegate?.contactsPickerViewModel(self, display: message, title: VectorL10n.roomParticipantsInvitePromptTitle, actions: [
            UIAlertAction(title: VectorL10n.cancel, style: .cancel),
            UIAlertAction(title: VectorL10n.invite, style: .default, handler: { [weak self] _ in
                self?.invite(contact: contact)
            })
        ])
    }
    
    private func invite(contact: MXKContact) {
        if let identifiers = contact.matrixIdentifiers as? [String], let participantId = identifiers.first {

            // Invite this user if a room is defined
            self.coordinatorDelegate?.contactsPickerViewModelDidStartInvite(self)
            room.invite(.userId(participantId)) { [weak self] response in
                guard let self = self else { return }
                
                switch response {
                case .success:
                    self.coordinatorDelegate?.contactsPickerViewModelDidEndInvite(self)
                case .failure:
                    MXLog.error("[ContactsPickerViewModel] Failed to invite participant", context: response.error)
                    self.coordinatorDelegate?.contactsPickerViewModel(self, inviteFailedWithError: response.error)
                }
            }
        } else {
            let _participantId: String?
            
            if let emailAddresses = contact.emailAddresses as? [MXKEmail], let email = emailAddresses.first {
                // This is a local contact, consider the first email by default.
                // TODO: Prompt the user to select the right email.
                _participantId = email.emailAddress
            } else {
                // This is the text filled by the user.
                _participantId = contact.displayName
            }
            
            guard let participantId = _participantId else {
                MXLog.error("[ContactsPickerViewModel] invite: unexpectedly found participantId nil")
                return
            }

            self.coordinatorDelegate?.contactsPickerViewModelDidStartInvite(self)
            // Is it an email or a Matrix user ID?
            if MXTools.isEmailAddress(participantId) {
                room.invite(.email(participantId)) { [weak self] response in
                    guard let self = self else { return }
                    
                    switch response {
                    case .success:
                        self.coordinatorDelegate?.contactsPickerViewModelDidEndInvite(self)
                    case .failure:
                        MXLog.error("[ContactsPickerViewModel] Failed to invite participant by email", context: response.error)
                        
                        if let error = response.error as NSError?, error.domain == kMXRestClientErrorDomain, error.code == MXRestClientErrorMissingIdentityServer {
                            self.coordinatorDelegate?.contactsPickerViewModel(self, inviteFailedWithError: nil)
                            AppDelegate.theDelegate().showAlert(withTitle: VectorL10n.errorInvite3pidWithNoIdentityServer, message: nil)
                        } else {
                            self.coordinatorDelegate?.contactsPickerViewModel(self, inviteFailedWithError: response.error)
                        }
                    }
                }
            } else {
                room.invite(.userId(participantId)) { [weak self] response in
                    guard let self = self else { return }
                    
                    switch response {
                    case .success:
                        self.coordinatorDelegate?.contactsPickerViewModelDidEndInvite(self)
                    case .failure:
                        MXLog.error("[ContactsPickerViewModel] Failed to invite participant", context: response.error)
                        self.coordinatorDelegate?.contactsPickerViewModel(self, inviteFailedWithError: response.error)
                    }
                }
            }
        }
    }
    
}
