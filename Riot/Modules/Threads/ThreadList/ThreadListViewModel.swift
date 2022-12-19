// File created from ScreenTemplate
// $ createScreen.sh Threads/ThreadList ThreadList
/*
 Copyright 2021 New Vector Ltd
 
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

final class ThreadListViewModel: ThreadListViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let roomId: String
    private var threads: [MXThreadProtocol] = []
    private var eventFormatter: MXKEventFormatter?
    private var roomState: MXRoomState?
    private var nextBatch: String?
    private var currentOperation: MXHTTPOperation?
    private var longPressedThread: MXThreadProtocol?
    
    // MARK: Public

    weak var viewDelegate: ThreadListViewModelViewDelegate?
    weak var coordinatorDelegate: ThreadListViewModelCoordinatorDelegate?
    var selectedFilterType: ThreadListFilterType = .all
    
    private(set) var viewState: ThreadListViewState = .idle {
        didSet {
            self.viewDelegate?.threadListViewModel(self, didUpdateViewState: viewState)
        }
    }
    
    // MARK: - Setup
    
    init(session: MXSession,
         roomId: String) {
        self.session = session
        self.roomId = roomId
        session.threadingService.addDelegate(self)
    }
    
    deinit {
        session.threadingService.removeDelegate(self)
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: ThreadListViewAction) {
        switch viewAction {
        case .loadData:
            loadData()
        case .complete:
            coordinatorDelegate?.threadListViewModelDidLoadThreads(self)
        case .showFilterTypes:
            viewState = .showingFilterTypes
        case .selectFilterType(let type):
            selectedFilterType = type
            resetData()
            loadData()
        case .selectThread(let index):
            selectThread(index)
        case .longPressThread(let index):
            longPressThread(index)
        case .actionViewInRoom:
            actionViewInRoom()
        case .actionCopyLinkToThread:
            actionCopyLinkToThread()
        case .actionShare:
            actionShare()
        case .cancel:
            cancelOperations()
            coordinatorDelegate?.threadListViewModelDidCancel(self)
        }
    }
    
    var numberOfThreads: Int {
        return threads.count
    }
    
    func threadModel(at index: Int) -> ThreadModel? {
        guard index < threads.count else {
            return nil
        }
        return model(forThread: threads[index])
    }
    
    var titleModel: ThreadRoomTitleModel {
        guard let room = session.room(withRoomId: roomId) else {
            return .empty
        }
        
        let avatarViewData = AvatarViewData(matrixItemId: room.matrixItemId,
                                            displayName: room.displayName,
                                            avatarUrl: room.mxContentUri,
                                            mediaManager: room.mxSession.mediaManager,
                                            fallbackImage: AvatarFallbackImage.matrixItem(room.matrixItemId,
                                                                                          room.displayName))
        
        let encrpytionBadge: UIImage?
        if let summary = room.summary, summary.isEncrypted, session.crypto != nil {
            encrpytionBadge = EncryptionTrustLevelBadgeImageHelper.roomBadgeImage(for: summary.roomEncryptionTrustLevel())
        } else {
            encrpytionBadge = nil
        }
        
        return ThreadRoomTitleModel(roomAvatar: avatarViewData,
                                    roomEncryptionBadge: encrpytionBadge,
                                    roomDisplayName: room.displayName)
    }
    
    private var emptyViewModel: ThreadListEmptyModel {
        switch selectedFilterType {
        case .all:
            return ThreadListEmptyModel(icon: Asset.Images.threadsIcon.image,
                                        title: VectorL10n.threadsEmptyTitle,
                                        info: VectorL10n.threadsEmptyInfoAll,
                                        tip: VectorL10n.threadsEmptyTip,
                                        showAllThreadsButtonTitle: VectorL10n.threadsEmptyShowAllThreads,
                                        showAllThreadsButtonHidden: true)
        case .myThreads:
            return ThreadListEmptyModel(icon: Asset.Images.threadsIcon.image,
                                        title: VectorL10n.threadsEmptyTitle,
                                        info: VectorL10n.threadsEmptyInfoMy,
                                        tip: nil,
                                        showAllThreadsButtonTitle: VectorL10n.threadsEmptyShowAllThreads,
                                        showAllThreadsButtonHidden: false)
        }
    }
    
    // MARK: - Private
    
    private func model(forThread thread: MXThreadProtocol) -> ThreadModel {
        let rootAvatarViewData: AvatarViewData?
        let rootMessageSender: MXUser?
        let lastAvatarViewData: AvatarViewData?
        let lastMessageSender: MXUser?
        let rootMessageText = rootMessageText(forThread: thread)
        let (lastMessageText, lastMessageTime) = lastMessageTextAndTime(forThread: thread)
        let notificationStatus = ThreadNotificationStatus(withThread: thread)
        
        //  root message
        if let rootMessage = thread.rootMessage, let senderId = rootMessage.sender {
            rootMessageSender = session.user(withUserId: rootMessage.sender)
            
            let fallbackImage = AvatarFallbackImage.matrixItem(senderId,
                                                               rootMessageSender?.displayname)
            rootAvatarViewData = AvatarViewData(matrixItemId: senderId,
                                                displayName: rootMessageSender?.displayname,
                                                avatarUrl: rootMessageSender?.avatarUrl,
                                                mediaManager: session.mediaManager,
                                                fallbackImage: fallbackImage)
        } else {
            rootAvatarViewData = nil
            rootMessageSender = nil
        }
        
        //  last message
        if let lastMessage = thread.lastMessage, let senderId = lastMessage.sender {
            lastMessageSender = session.user(withUserId: lastMessage.sender)
            
            let fallbackImage = AvatarFallbackImage.matrixItem(senderId,
                                                               lastMessageSender?.displayname)
            lastAvatarViewData = AvatarViewData(matrixItemId: senderId,
                                                displayName: lastMessageSender?.displayname,
                                                avatarUrl: lastMessageSender?.avatarUrl,
                                                mediaManager: session.mediaManager,
                                                fallbackImage: fallbackImage)
        } else {
            lastAvatarViewData = nil
            lastMessageSender = nil
        }

        let summaryModel = ThreadSummaryModel(numberOfReplies: thread.numberOfReplies,
                                              lastMessageSenderAvatar: lastAvatarViewData,
                                              lastMessageText: lastMessageText)

        return ThreadModel(rootMessageSenderUserId: rootMessageSender?.userId,
                           rootMessageSenderAvatar: rootAvatarViewData,
                           rootMessageSenderDisplayName: rootMessageSender?.displayname,
                           rootMessageText: rootMessageText,
                           rootMessageRedacted: thread.rootMessage?.isRedactedEvent() ?? false,
                           lastMessageTime: lastMessageTime,
                           summaryModel: summaryModel,
                           notificationStatus: notificationStatus)
    }
    
    private func rootMessageText(forThread thread: MXThreadProtocol) -> NSAttributedString? {
        guard let eventFormatter = eventFormatter else {
            return nil
        }
        guard let message = thread.rootMessage else {
            return nil
        }
        let formatterError = UnsafeMutablePointer<MXKEventFormatterError>.allocate(capacity: 1)
        return eventFormatter.attributedString(from: message.replyStrippedVersion,
                                               with: roomState,
                                               andLatestRoomState: nil,
                                               error: formatterError)?.vc_byRemovingLinks
    }
    
    private func lastMessageTextAndTime(forThread thread: MXThreadProtocol) -> (NSAttributedString?, String?) {
        guard let eventFormatter = eventFormatter else {
            return (nil, nil)
        }
        guard let message = thread.lastMessage else {
            return (nil, nil)
        }
        let formatterError = UnsafeMutablePointer<MXKEventFormatterError>.allocate(capacity: 1)
        return (
            eventFormatter.attributedString(from: message.replyStrippedVersion,
                                            with: roomState,
                                            andLatestRoomState: nil,
                                            error: formatterError),
            eventFormatter.dateString(from: message, withTime: true)
        )
    }
    
    private func resetData() {
        nextBatch = nil
        threads = []
    }
    
    private func loadData(showLoading: Bool = true) {
        guard threads.isEmpty || nextBatch != nil else {
            return
        }

        if showLoading {
            viewState = .loading
        }

        let onlyParticipated: Bool
        
        switch selectedFilterType {
        case .all:
            onlyParticipated = false
        case .myThreads:
            onlyParticipated = true
        }
        
        session.threadingService.allThreads(inRoom: roomId, from: nextBatch, onlyParticipated: onlyParticipated) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let value):
                self.threads = self.threads + value.threads
                self.nextBatch = value.nextBatch
                self.threadsLoaded()
            case .failure(let error):
                MXLog.error("[ThreadListViewModel] loadData", context: error)
                self.viewState = .error(error)
            }
        }
    }
    
    private func threadsLoaded() {
        if threads.isEmpty {
            viewState = .empty(emptyViewModel)
            return
        }

        guard let eventFormatter = session.roomSummaryUpdateDelegate as? MXKEventFormatter,
              let room = session.room(withRoomId: roomId) else {
            //  go into loaded state
            self.viewState = .loaded
            
            return
        }
        
        room.state { [weak self] roomState in
            guard let self = self else { return }
            self.eventFormatter = eventFormatter
            self.roomState = roomState
            
            //  go into loaded state
            self.viewState = .loaded
        }
    }
    
    private func selectThread(_ index: Int) {
        guard index < threads.count else {
            return
        }
        let thread = threads[index]
        coordinatorDelegate?.threadListViewModelDidSelectThread(self, thread: thread)
    }
    
    private func longPressThread(_ index: Int) {
        guard index < threads.count else {
            return
        }
        longPressedThread = threads[index]
        viewState = .showingLongPressActions(index)
    }
    
    private func actionViewInRoom() {
        guard let thread = longPressedThread else {
            return
        }
        coordinatorDelegate?.threadListViewModelDidSelectThreadViewInRoom(self, thread: thread)
        longPressedThread = nil
    }
    
    private func actionCopyLinkToThread() {
        guard let thread = longPressedThread else {
            return
        }
        if let permalink = MXTools.permalink(toEvent: thread.id, inRoom: thread.roomId),
           let url = URL(string: permalink) {
            MXKPasteboardManager.shared.pasteboard.url = url
            viewState = .toastForCopyLink
        }
        longPressedThread = nil
    }
    
    private func actionShare() {
        guard let thread = longPressedThread,
              let index = threads.firstIndex(where: { thread.id == $0.id }) else {
            return
        }
        if let permalink = MXTools.permalink(toEvent: thread.id, inRoom: thread.roomId),
           let url = URL(string: permalink) {
            viewState = .share(url, index)
        }
        longPressedThread = nil
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}

extension ThreadListViewModel: MXThreadingServiceDelegate {
    
    func threadingServiceDidUpdateThreads(_ service: MXThreadingService) {
        loadData(showLoading: false)
    }
    
}
