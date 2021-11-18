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
    private var threads: [MXThread] = []
    private var eventFormatter: MXKEventFormatter?
    private var roomState: MXRoomState?
    
    private var currentOperation: MXHTTPOperation?
    
    // MARK: Public

    weak var viewDelegate: ThreadListViewModelViewDelegate?
    weak var coordinatorDelegate: ThreadListViewModelCoordinatorDelegate?
    
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
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: ThreadListViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .complete:
            self.coordinatorDelegate?.threadListViewModelDidLoadThreads(self)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.threadListViewModelDidCancel(self)
        }
    }
    
    var numberOfThreads: Int {
        return threads.count
    }
    
    func threadViewModel(at index: Int) -> ThreadViewModel? {
        guard index < threads.count else {
            return nil
        }
        return viewModel(forThread: threads[index])
    }
    
    // MARK: - Private
    
    private func viewModel(forThread thread: MXThread) -> ThreadViewModel {
        let rootAvatarViewData: AvatarViewData?
        let rootMessageSender: MXUser?
        let lastAvatarViewData: AvatarViewData?
        let lastMessageSender: MXUser?
        let rootMessageText: String?
        let lastMessageText: String?
        let lastMessageTime: String?
        
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
        
        if let eventFormatter = eventFormatter {
            let formatterError = UnsafeMutablePointer<MXKEventFormatterError>.allocate(capacity: 1)
            rootMessageText = eventFormatter.string(from: thread.rootMessage,
                                                    with: roomState,
                                                    error: formatterError)
            lastMessageText = eventFormatter.string(from: thread.lastMessage,
                                                    with: roomState,
                                                    error: formatterError)
            lastMessageTime = eventFormatter.dateString(from: thread.lastMessage, withTime: true)
        } else {
            rootMessageText = nil
            lastMessageText = nil
            lastMessageTime = nil
        }
        
        let summaryViewModel = ThreadSummaryViewModel(numberOfReplies: thread.numberOfReplies,
                                                      lastMessageSenderAvatar: lastAvatarViewData,
                                                      lastMessageText: lastMessageText)
        
        return ThreadViewModel(rootMessageSenderAvatar: rootAvatarViewData,
                               rootMessageSenderDisplayName: rootMessageSender?.displayname,
                               rootMessageText: rootMessageText,
                               lastMessageTime: lastMessageTime,
                               summaryViewModel: summaryViewModel)
    }
    
    private func loadData() {

        viewState = .loading
        
        threads = session.threadingService.threads(inRoom: roomId)
        session.threadingService.addDelegate(self)
        threadsLoaded()
    }
    
    private func threadsLoaded() {
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
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}

extension ThreadListViewModel: MXThreadingServiceDelegate {
    
    func threadingServiceDidUpdateThreads(_ service: MXThreadingService) {
        threads = service.threads(inRoom: roomId)
        viewState = .loaded
    }
    
}
