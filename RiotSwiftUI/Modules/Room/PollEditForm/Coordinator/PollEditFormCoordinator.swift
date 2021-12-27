// File created from SimpleUserProfileExample
// $ createScreen.sh Room/PollEditForm PollEditForm
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
import UIKit
import SwiftUI

struct PollEditFormCoordinatorParameters {
    let navigationRouter: NavigationRouterType?
    let room: MXRoom
}

final class PollEditFormCoordinator: Coordinator {
    
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

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: PollEditFormCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = PollEditFormViewModel()
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
        
        parameters.navigationRouter?.present(pollEditFormHostingController, animated: true)
        
        pollEditFormViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.parameters.navigationRouter?.dismissModule(animated: true, completion: nil)
            case .create(let question, let answerOptions):
                var options = [MXEventContentPollStartAnswerOption]()
                for answerOption in answerOptions {
                    options.append(MXEventContentPollStartAnswerOption(uuid: UUID().uuidString, text: answerOption))
                }
                
                let pollStartContent = MXEventContentPollStart(question: question,
                                                               kind: kMXMessageContentKeyExtensiblePollKindDisclosed,
                                                               maxSelections: 1,
                                                               answerOptions: options)
                
                self.pollEditFormViewModel.dispatch(action: .startLoading)
                
                self.parameters.room.sendPollStart(withContent: pollStartContent, localEcho: nil) { [weak self] result in
                    guard let self = self else { return }
                    
                    self.parameters.navigationRouter?.dismissModule(animated: true, completion: nil)
                    self.pollEditFormViewModel.dispatch(action: .stopLoading(nil))
                } failure: { [weak self] error in
                    guard let self = self else { return }
                    
                    MXLog.error("Failed creating poll with error: \(String(describing: error))")
                    self.pollEditFormViewModel.dispatch(action: .stopLoading(error))
                }
            }
        }
    }
}
