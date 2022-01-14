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
import UIKit
import SwiftUI

struct PollEditFormCoordinatorParameters {
    let room: MXRoom
    let pollStartEvent: MXEvent?
}

final class PollEditFormCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: PollEditFormCoordinatorParameters
    private let pollEditFormHostingController: UIViewController
    private var _pollEditFormViewModel: Any? = nil
    
    @available(iOS 14.0, *)
    fileprivate var pollEditFormViewModel: PollEditFormViewModel {
        return _pollEditFormViewModel as! PollEditFormViewModel
    }
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: PollEditFormCoordinatorParameters) {
        self.parameters = parameters
        
        var viewModel: PollEditFormViewModel
        if let startEvent = parameters.pollStartEvent,
           let pollContent = MXEventContentPollStart(fromJSON: startEvent.content) {
            viewModel = PollEditFormViewModel(parameters: PollEditFormViewModelParameters(mode: .editing,
                                                                                          pollDetails: EditFormPollDetails(type: Self.pollKindKeyToDetailsType(pollContent.kind),
                                                                                                                           question: pollContent.question,
                                                                                                                           answerOptions: pollContent.answerOptions.map { $0.text })))
            
        } else {
            viewModel = PollEditFormViewModel(parameters: PollEditFormViewModelParameters(mode: .creation, pollDetails: .default))
        }
        
        let view = PollEditForm(viewModel: viewModel.context)
        
        _pollEditFormViewModel = viewModel
        pollEditFormHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    func start() {
        guard #available(iOS 14.0, *) else {
            MXLog.error("[PollEditFormCoordinator] start: Invalid iOS version, returning.")
            return
        }
        
        pollEditFormViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.completion?()
            case .create(let details):
                
                let pollStartContent = self.buildPollContentWithDetails(details)
                
                self.pollEditFormViewModel.dispatch(action: .startLoading)
                
                self.parameters.room.sendPollStart(withContent: pollStartContent, localEcho: nil) { [weak self] result in
                    guard let self = self else { return }
                    
                    self.pollEditFormViewModel.dispatch(action: .stopLoading(nil))
                    self.completion?()
                } failure: { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("Failed creating poll with error: \(String(describing: error))")
                    self.pollEditFormViewModel.dispatch(action: .stopLoading(.failedCreatingPoll))
                }
                
            case .update(let details):
                guard let pollStartEvent = self.parameters.pollStartEvent else {
                    fatalError()
                }
                
                self.pollEditFormViewModel.dispatch(action: .startLoading)
                
                guard let oldPollContent = MXEventContentPollStart(fromJSON: pollStartEvent.content) else {
                    self.pollEditFormViewModel.dispatch(action: .stopLoading(.failedUpdatingPoll))
                    return
                }
                
                let newPollContent = self.buildPollContentWithDetails(details)
                
                self.parameters.room.sendPollUpdate(for: pollStartEvent,
                                                    oldContent: oldPollContent,
                                                    newContent: newPollContent, localEcho: nil) { [weak self] result in
                    guard let self = self else { return }
                    
                    self.pollEditFormViewModel.dispatch(action: .stopLoading(nil))
                    self.completion?()
                } failure: { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("Failed updating poll with error: \(String(describing: error))")
                    self.pollEditFormViewModel.dispatch(action: .stopLoading(.failedUpdatingPoll))
                }   
            }
        }
    }
    
    // MARK: - Presentable
    
    func toPresentable() -> UIViewController {
        return pollEditFormHostingController
    }
    
    // MARK: - Private
    
    private func buildPollContentWithDetails(_ details: EditFormPollDetails) -> MXEventContentPollStart {
        var options = [MXEventContentPollStartAnswerOption]()
        for answerOption in details.answerOptions {
            options.append(MXEventContentPollStartAnswerOption(uuid: UUID().uuidString, text: answerOption))
        }
        
        return MXEventContentPollStart(question: details.question,
                                       kind: Self.pollDetailsTypeToKindKey(details.type),
                                       maxSelections: NSNumber(value: details.maxSelections),
                                       answerOptions: options)
        
    }
    
    private static func pollDetailsTypeToKindKey(_ type: EditFormPollType) -> String {
        let mapping = [EditFormPollType.disclosed : kMXMessageContentKeyExtensiblePollKindDisclosed,
                       EditFormPollType.undisclosed : kMXMessageContentKeyExtensiblePollKindUndisclosed]
        
        return mapping[type] ?? kMXMessageContentKeyExtensiblePollKindDisclosed
    }
    
    private static func pollKindKeyToDetailsType(_ key: String) -> EditFormPollType {
        let mapping = [kMXMessageContentKeyExtensiblePollKindDisclosed : EditFormPollType.disclosed,
                       kMXMessageContentKeyExtensiblePollKindUndisclosed : EditFormPollType.undisclosed]
        
        return mapping[key] ?? EditFormPollType.disclosed
    }
}
