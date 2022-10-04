// 
// Copyright 2022 New Vector Ltd
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
import Reusable
import WysiwygComposer
import SwiftUI
import Combine
import UIKit
import CoreGraphics

@available(iOS 16.0, *)
class WysiwygInputToolbarView: MXKRoomInputToolbarView, NibLoadable, RoomInputToolbarViewProtocol {
    
    override class func instantiate() -> MXKRoomInputToolbarView! {
        return loadFromNib()
    }
    
    @objc var startModuleAction: ((ComposerModule) -> Void)?
    private weak var toolbarViewDelegate: RoomInputToolbarViewDelegate? {
        return (delegate as? RoomInputToolbarViewDelegate) ?? nil
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var heightConstraint: NSLayoutConstraint!
    private var hostingViewController: UIHostingController<Composer>!
    private static let minToolbarHeight: CGFloat = 100
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let viewModel = WysiwygComposerViewModel()
        let composer = Composer(viewModel: viewModel, sendMessageAction: { [weak self] content in
            guard let self = self else { return }
            self.sendWysiwygMessage(content: content)
        }, startModuleAction: { [weak self] module in
            guard let self = self else { return }
            self.startModuleAction?(module)
        })
        
        
        hostingViewController = UIHostingController(rootView: composer)
        let h = hostingViewController.sizeThatFits(in: CGSize(width: self.frame.width, height: 800)).height
        let subView: UIView = hostingViewController.view
        self.addSubview(subView)
        
        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        subView.translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = subView.heightAnchor.constraint(equalToConstant: h)
        NSLayoutConstraint.activate([
            heightConstraint,
            subView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            //                subView.topAnchor.constraint(equalTo: self.topAnchor),
            subView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            subView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        cancellables = [
//            viewModel.$isContentEmpty
//                .removeDuplicates()
//                .sink(receiveValue: { [weak self] isContentEmpty in
//                    //                    guard let self = self else { return }
//                    //                    self.delegate?.isContentEmptyDidChange(isContentEmpty)
//                }),
//            viewModel.$content
//                .map { $0.attributed }
//                .removeDuplicates()
//                .sink(receiveValue: { [weak self] attributed in
//                    print(attributed)
//                    //                    guard let self = self else { return }
//                    //                    self.delegate?.isContentEmptyDidChange(isContentEmpty)
//                }),
            viewModel.$idealHeight
                .removeDuplicates()
                .sink(receiveValue: { [weak self] idealHeight in
                    guard let self = self else { return }
                    let h = self.hostingViewController.sizeThatFits(in: CGSize(width: self.frame.width, height: 800)).height
                    self.updateToolbarHeight(wysiwygHeight: h)
                })
        ]
    }
    
    func setVoiceMessageToolbarView(_ voiceMessageToolbarView: UIView!) {
        //TODO embed the voice messages UI
    }
    
    func toolbarHeight() -> CGFloat {
        return heightConstraint.constant
    }
    
   private func updateToolbarHeight(wysiwygHeight: CGFloat) {
        heightConstraint.constant = wysiwygHeight
        toolbarViewDelegate?.roomInputToolbarView?(self, heightDidChanged: wysiwygHeight, completion: { _ in
            
        })
    }
    
    private func sendWysiwygMessage(content: WysiwygComposerContent) {
        delegate?.roomInputToolbarView?(self, sendFormattedTextMessage: content.html, withRawText: content.plainText)
    }
    
}
