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

import UIKit
import Reusable

final class ReactionsMenuView: UIView, NibOwnerLoadable {

    // MARK: - Properties

    // MARK: Outlets
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var disagreeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dislikeButton: UIButton!

    // MARK: Private

    // MARK: Public

    var viewModel: ReactionsMenuViewModelType? {
        didSet {
            self.updateView()
            self.viewModel?.viewDelegate = self
        }
    }

    // MARK: - Setup

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        self.commonInit()
    }

    // MARK: - Actions

    @IBAction private func agreeButtonAction(_ sender: Any) {
        self.viewModel?.process(viewAction: .toggleReaction(.agree))
    }

    @IBAction private func disagreeButtonAction(_ sender: Any) {
        self.viewModel?.process(viewAction: .toggleReaction(.disagree))
    }

    @IBAction private func likeButtonAction(_ sender: Any) {
        self.viewModel?.process(viewAction: .toggleReaction(.like))
    }

    @IBAction private func dislikeButtonAction(_ sender: Any) {
        self.viewModel?.process(viewAction: .toggleReaction(.dislike))
    }
    
    // MARK: - Private

    private func commonInit() {

        agreeButton.setTitle(VectorL10n.roomEventActionReactionAgree(ReactionsMenuReaction.agree.rawValue), for: .normal)
        agreeButton.setTitle(VectorL10n.roomEventActionReactionAgree(ReactionsMenuReaction.agree.rawValue), for: .highlighted)
        disagreeButton.setTitle(VectorL10n.roomEventActionReactionDisagree(ReactionsMenuReaction.disagree.rawValue), for: .normal)
        disagreeButton.setTitle(VectorL10n.roomEventActionReactionDisagree(ReactionsMenuReaction.disagree.rawValue), for: .highlighted)
        likeButton.setTitle(VectorL10n.roomEventActionReactionLike(ReactionsMenuReaction.like.rawValue), for: .normal)
        likeButton.setTitle(VectorL10n.roomEventActionReactionLike(ReactionsMenuReaction.like.rawValue), for: .highlighted)
        dislikeButton.setTitle(VectorL10n.roomEventActionReactionDislike(ReactionsMenuReaction.dislike.rawValue), for: .normal)
        dislikeButton.setTitle(VectorL10n.roomEventActionReactionDislike(ReactionsMenuReaction.dislike.rawValue), for: .highlighted)

        customizeViewRendering()
    }

    private func customizeViewRendering() {
        self.backgroundColor = UIColor.clear
    }

    private func updateView() {
        guard let viewModel = self.viewModel else {
            return
        }

        agreeButton.isSelected = viewModel.isAgreeButtonSelected
        disagreeButton.isSelected = viewModel.isDisagreeButtonSelected
        likeButton.isSelected = viewModel.isLikeButtonSelected
        dislikeButton.isSelected = viewModel.isDislikeButtonSelected
    }
}

extension ReactionsMenuView: ReactionsMenuViewModelDelegate {
    func reactionsMenuViewModelDidUpdate(_ viewModel: ReactionsMenuViewModelType) {
        self.updateView()
    }
}
