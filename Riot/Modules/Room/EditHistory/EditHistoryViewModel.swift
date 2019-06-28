// File created from ScreenTemplate
// $ createScreen.sh Room/EditHistory EditHistory
/*
 Copyright 2019 New Vector Ltd
 
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

final class EditHistoryViewModel: EditHistoryViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let aggregations: MXAggregations
    private let roomId: String
    private let eventId: String
    private let messageFormattingQueue: DispatchQueue

    private var nextBatch: String?
    
    // MARK: Public
    
    var messages: [EditHistoryMessage] = []
    var operation: MXHTTPOperation?

    weak var viewDelegate: EditHistoryViewModelViewDelegate?
    weak var coordinatorDelegate: EditHistoryViewModelCoordinatorDelegate?
    
    
    // MARK: - Setup
    
    init(aggregations: MXAggregations,
         roomId: String,
         eventId: String) {
        self.aggregations = aggregations
        self.roomId = roomId
        self.eventId = eventId
        self.messageFormattingQueue = DispatchQueue(label: "\(type(of: self)).messageFormattingQueue")
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: EditHistoryViewAction) {
        switch viewAction {
        case .loadMore:
            self.loadMoreHistory()
        case .close:
            self.coordinatorDelegate?.editHistoryViewModelDidClose(self)
        }
    }
    
    // MARK: - Private
    
    func loadMoreHistory() {
        if self.operation != nil {
            print("[EditHistoryViewModel] loadMoreHistory: operation already pending")
            return
        }

        self.update(viewState: .loading)
        self.operation = self.aggregations.replaceEvents(forEvent: self.eventId, inRoom: self.roomId, from: self.nextBatch, limit: 10, success: { [weak self] (response) in
            guard let sself = self else {
                return
            }

            sself.nextBatch = response.nextBatch
            sself.operation = nil

            sself.process(editEvents: response.chunk)

            }, failure: { [weak self] error in
                guard let sself = self else {
                    return
                }

                sself.operation = nil
                sself.update(viewState: .error(error))
        })
    }

    func process(editEvents: [MXEvent]) {
        self.messageFormattingQueue.async {
            
            let newMessages = editEvents.reversed()
                .compactMap { (editEvent) -> EditHistoryMessage? in
                    return self.process(editEvent: editEvent)
            }

            if newMessages.count > 0 {
                DispatchQueue.main.async {
                    self.messages = newMessages + self.messages
                    self.update(viewState: .loaded(messages: self.messages, addedCount: newMessages.count))
                }
            }
        }
    }

    func process(editEvent: MXEvent) -> EditHistoryMessage? {

        guard let body: String = (editEvent.content?["m.new_content"] as? [String: Any])?["body"] as? String else {
            print("[EditHistoryViewModel] processEditEvent: invalid edit event: \(editEvent.eventId ?? "")")
            return nil
        }

        // TODO: Using MXKEventFormatter
        return EditHistoryMessage(date: Date(), message: NSAttributedString(string: body))
    }
    
    private func update(viewState: EditHistoryViewState) {
        self.viewDelegate?.editHistoryViewModel(self, didUpdateViewState: viewState)
    }
}
