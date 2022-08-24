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
    private var pollEditFormViewModel: PollEditFormViewModelProtocol
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
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
        
        pollEditFormViewModel = viewModel
        pollEditFormHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    func start() {
        pollEditFormViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.completion?()
            case .create(let details):
                
                let pollStartContent = self.buildPollContentWithDetails(details)
                
                self.pollEditFormViewModel.startLoading()
                
                self.parameters.room.sendPollStart(withContent: pollStartContent, threadId: nil, localEcho: nil) { [weak self] result in
                    guard let self = self else { return }
                    
                    self.pollEditFormViewModel.stopLoading()
                    self.completion?()
                } failure: { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("Failed creating poll", context: error)
                    self.pollEditFormViewModel.stopLoading(errorAlertType: .failedCreatingPoll)
                }
                
            case .update(let details):
                guard let pollStartEvent = self.parameters.pollStartEvent else {
                    fatalError()
                }
                
                self.pollEditFormViewModel.startLoading()
                
                guard let oldPollContent = MXEventContentPollStart(fromJSON: pollStartEvent.content) else {
                    self.pollEditFormViewModel.stopLoading(errorAlertType: .failedUpdatingPoll)
                    return
                }
                
                let newPollContent = self.buildPollContentWithDetails(details)
                
                self.parameters.room.sendPollUpdate(for: pollStartEvent,
                                                    oldContent: oldPollContent,
                                                    newContent: newPollContent, localEcho: nil) { [weak self] result in
                    guard let self = self else { return }
                    
                    self.pollEditFormViewModel.stopLoading()
                    self.completion?()
                } failure: { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("Failed updating poll", context: error)
                    self.pollEditFormViewModel.stopLoading(errorAlertType: .failedUpdatingPoll)
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
        let mapping = [EditFormPollType.disclosed : kMXMessageContentKeyExtensiblePollKindDisclosedMSC3381,
                       EditFormPollType.undisclosed : kMXMessageContentKeyExtensiblePollKindUndisclosedMSC3381]
        
        return mapping[type] ?? kMXMessageContentKeyExtensiblePollKindDisclosedMSC3381
    }
    
    private static func pollKindKeyToDetailsType(_ key: String) -> EditFormPollType {
        let mapping = [kMXMessageContentKeyExtensiblePollKindDisclosed : EditFormPollType.disclosed,
                       kMXMessageContentKeyExtensiblePollKindDisclosedMSC3381 : EditFormPollType.disclosed,
                       kMXMessageContentKeyExtensiblePollKindUndisclosed : EditFormPollType.undisclosed,
                     kMXMessageContentKeyExtensiblePollKindUndisclosedMSC3381 : EditFormPollType.undisclosed]
        
        return mapping[key] ?? EditFormPollType.disclosed
    }
}
