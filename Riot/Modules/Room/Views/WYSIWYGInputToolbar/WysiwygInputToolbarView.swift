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

@available(iOS 15.0, *)
class WysiwygInputToolbarView: MXKRoomInputToolbarView, NibLoadable, RoomInputToolbarViewProtocol {
    
    override class func instantiate() -> MXKRoomInputToolbarView! {
        return loadFromNib()
    }
    
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
//        let composerViewModel = ComposerViewModel()
        let composer = Composer(viewModel: viewModel)
        
        
        hostingViewController = UIHostingController(rootView: composer)
        //            hostingViewController.view.sizeToFit()
        //            let h = hostingViewController.view.frame.size.height
        
        let h = hostingViewController.sizeThatFits(in: CGSize(width: self.frame.width, height: 800)).height
        //            hostingViewController.view.invalidateIntrinsicContentSize()
        
        let subView: UIView = hostingViewController.view
        
        //            vc_addSubViewMatchingParent(subView)
        
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
        //            self.setNeedsLayout()
        //            self.layoutIfNeeded()
        
        //            composerViewModel.$totalHeight
        //                .removeDuplicates()
        //                .sink { [weak self] height in
        //                    guard let self = self else { return }
        //                    hostingViewController.view.sizeToFit()
        //                    let h = hostingViewController.view.frame.height
        //                    self.updateToolbarHeight(wysiwygHeight: height)
        //                }.store(in: &cancellables)
        //        // Subscribe to relevant events and map them to UIKit-style delegate.
        cancellables = [
//            viewModel.$isContentEmpty
//                .removeDuplicates()
//                .sink(receiveValue: { [weak self] isContentEmpty in
//                    //                    guard let self = self else { return }
//                    //                    self.delegate?.isContentEmptyDidChange(isContentEmpty)
//                }),
            viewModel.$idealHeight
                .removeDuplicates()
                .sink(receiveValue: { [weak self] idealHeight in
                    guard let self = self else { return }
                    let h = self.hostingViewController.sizeThatFits(in: CGSize(width: self.frame.width, height: 800)).height
                    self.updateToolbarHeight(wysiwygHeight: h)
                    //                    self.delegate?.idealHeightDidChange(idealHeight)
                })
        ]
        
        
    }
    
    func setVoiceMessageToolbarView(_ voiceMessageToolbarView: UIView!) {
        
    }
    
    func toolbarHeight() -> CGFloat {
        return heightConstraint.constant
    }
    
    
    func updateToolbarHeight(wysiwygHeight: CGFloat) {
        heightConstraint.constant = wysiwygHeight
        toolbarViewDelegate?.roomInputToolbarView?(self, heightDidChanged: wysiwygHeight, completion: { _ in
            
        })
    }
}
