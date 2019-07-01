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

    // MARK: - Constants

    private enum Pagination {
        static let count: UInt = 2
    }

    // MARK: - Properties
    
    // MARK: Private

    private let aggregations: MXAggregations
    private let formatter: MXKEventFormatter
    private let roomId: String
    private let event: MXEvent
    private let messageFormattingQueue: DispatchQueue

    private var nextBatch: String?
    
    // MARK: Public
    
    var messages: [EditHistoryMessage] = []
    var operation: MXHTTPOperation?

    weak var viewDelegate: EditHistoryViewModelViewDelegate?
    weak var coordinatorDelegate: EditHistoryViewModelCoordinatorDelegate?
    
    
    // MARK: - Setup
    
    init(aggregations: MXAggregations,
         formatter: MXKEventFormatter,
         event: MXEvent) {
        self.aggregations = aggregations
        self.formatter = formatter
        self.event = event
        self.roomId = event.roomId
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
        self.operation = self.aggregations.replaceEvents(forEvent: self.event.eventId, inRoom: self.roomId, from: self.nextBatch, limit: Pagination.count, success: { [weak self] (response) in
            guard let sself = self else {
                return
            }

            sself.nextBatch = response.nextBatch
            sself.operation = nil

            sself.process(editEvents: response.chunk)

            if sself.nextBatch == nil {
                sself.update(viewState: .allLoaded)
            }

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
        // Create a temporary MXEvent that represents this edition
        guard let editedEvent = self.event.editedEvent(fromReplacementEvent: editEvent) else {
            print("[EditHistoryViewModel] processEditEvent: Cannot build edited event: \(editEvent.eventId ?? "")")
            return nil
        }

        let formatterError = UnsafeMutablePointer<MXKEventFormatterError>.allocate(capacity: 1)
        guard let message = self.formatter.attributedString(from: editedEvent, with: nil, error: formatterError) else {
            print("[EditHistoryViewModel] processEditEvent: cannot format(error: \(formatterError)) edited event: \(editEvent.eventId ?? "")")
            return nil
        }

        let date = Date(timeIntervalSince1970: TimeInterval(editEvent.originServerTs) / 1000)

        return EditHistoryMessage(date: date, message: message)
    }
    
    private func update(viewState: EditHistoryViewState) {
        self.viewDelegate?.editHistoryViewModel(self, didUpdateViewState: viewState)
    }
}
