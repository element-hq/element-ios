/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit
import Reusable

final class ReactionsMenuView: UIView, Themable, NibLoadable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let selectedReactionAnimationScale: CGFloat = 1.2
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var reactionsBackgroundView: UIView!    
    @IBOutlet private weak var reactionsStackView: UIStackView!    
    @IBOutlet private weak var moreReactionsBackgroundView: UIView!
    @IBOutlet private weak var moreReactionsButton: UIButton!
    
    // MARK: Private
    
    private var reactionViewDatas: [ReactionMenuItemViewData] = []
    private var reactionButtons: [ReactionsMenuButton] = []
    private var tappedReactionButton: ReactionsMenuButton?
    
    // MARK: Public
    
    var viewModel: ReactionsMenuViewModelType? {
        didSet {
            self.viewModel?.viewDelegate = self
            self.viewModel?.process(viewAction: .loadData)
        }
    }
    
    var reactionHasBeenTapped: Bool {
        return self.tappedReactionButton != nil
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.reactionsBackgroundView.layer.masksToBounds = true
        self.moreReactionsButton.setImage(Asset.Images.moreReactions.image, for: .normal)
        self.update(theme: ThemeService.shared().theme)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.reactionsBackgroundView.layer.cornerRadius = self.reactionsBackgroundView.frame.size.height/2
        self.moreReactionsBackgroundView.layer.cornerRadius = self.moreReactionsBackgroundView.frame.size.height/2
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.reactionsBackgroundView.backgroundColor = theme.colors.system
        self.moreReactionsBackgroundView.backgroundColor = theme.colors.system
        self.moreReactionsButton.tintColor = theme.tintColor
    }
    
    func selectionAnimationInstructionPart1() {
        guard let tappedButton = self.tappedReactionButton else {
            return
        }
        let scale = Constants.selectedReactionAnimationScale
        tappedButton.superview?.bringSubviewToFront(tappedButton)
        tappedButton.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    
    func selectionAnimationInstructionPart2() {
        guard let tappedButton = self.tappedReactionButton else {
            return
        }
        tappedButton.transform = CGAffineTransform.identity
        tappedButton.isSelected.toggle()
    }
    
    // MARK: - Private
    
    private func fill(reactionsMenuViewDatas: [ReactionMenuItemViewData]) {
        self.reactionViewDatas = reactionsMenuViewDatas
        
        self.reactionsStackView.vc_removeAllArrangedSubviews()
        
        let reactionsStackViewCount = self.reactionsStackView.arrangedSubviews.count
        
        // Remove all menu buttons if reactions count has changed
        if reactionsStackViewCount != self.reactionViewDatas.count {
            self.reactionsStackView.vc_removeAllArrangedSubviews()
        }
        
        var index = 0
        
        for reactionViewData in self.reactionViewDatas {
            
            let reactionsMenuButton: ReactionsMenuButton
            
            if index < reactionsStackViewCount, let foundReactionsMenuButton = self.reactionsStackView.arrangedSubviews[index] as? ReactionsMenuButton {
                reactionsMenuButton = foundReactionsMenuButton
            } else {
                reactionsMenuButton = ReactionsMenuButton()
                reactionsMenuButton.addTarget(self, action: #selector(reactionButtonAction), for: .touchUpInside)
                self.reactionsStackView.addArrangedSubview(reactionsMenuButton)
                self.reactionButtons.append(reactionsMenuButton)
            }
            
            reactionsMenuButton.setTitle(reactionViewData.emoji, for: .normal)
            reactionsMenuButton.isSelected = reactionViewData.isSelected
            
            index+=1
        }
    }
    
    @objc private func reactionButtonAction(_ sender: ReactionsMenuButton) {
        guard let tappedReaction = sender.titleLabel?.text else {
            return
        }
        self.tappedReactionButton = sender
        self.viewModel?.process(viewAction: .tap(reaction: tappedReaction))
    }
    
    @IBAction private func moreReactionsAction(_ sender: Any) {
        self.viewModel?.process(viewAction: .moreReactions)
    }
}

// MARK: - ReactionsMenuViewModelViewDelegate
extension ReactionsMenuView: ReactionsMenuViewModelViewDelegate {
    
    func reactionsMenuViewModel(_ viewModel: ReactionsMenuViewModel, didUpdateViewState viewState: ReactionsMenuViewState) {
        switch viewState {
        case .loaded(reactionsViewData: let reactionsViewData):
            self.fill(reactionsMenuViewDatas: reactionsViewData)
        }
    }
}
