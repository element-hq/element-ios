/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import MatrixSDK
import Reusable
import UIKit
import UICollectionViewRightAlignedLayout
import UICollectionViewLeftAlignedLayout

/// RoomReactionsView items alignment
enum RoomReactionsViewAlignment {
    case left
    case right
}

@objcMembers
final class RoomReactionsView: UIView, NibOwnerLoadable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let minimumInteritemSpacing: CGFloat = 6.0
        static let minimumLineSpacing: CGFloat = 2.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var collectionView: UICollectionView!
    
    // MARK: Private
    
    private var reactionsViewData: [RoomReactionViewData] = []
    private var remainingViewData: [RoomReactionViewData] = []
    private var showAllButtonState: RoomReactionsViewState.ShowAllButtonState = .none
    private var showAddReaction: Bool = false
    private var theme: Theme?
    
    // MARK: Public
    
    // Do not use `RoomReactionsViewModelType` here due to Objective-C incompatibily
    var viewModel: RoomReactionsViewModel? {
        didSet {
            self.viewModel?.viewDelegate = self
            self.viewModel?.process(viewAction: .loadData)
        }
    }
    
    var alignment: RoomReactionsViewAlignment = .left {
        didSet {
            self.updateCollectionViewLayout(for: alignment)
        }
    }
    
    // MARK: - Setup
    
    private func commonInit() {
        self.setupCollectionView()
        self.setupLongPressGestureRecognizer()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }

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
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.theme = theme
        self.collectionView.reloadData()
    }

    // MARK: - Private
    
    private func setupCollectionView() {
        self.collectionView.isScrollEnabled = false
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.alignment = .left
        
        self.collectionView.register(cellType: RoomReactionViewCell.self)
        self.collectionView.register(cellType: RoomReactionActionViewCell.self)
        self.collectionView.register(cellType: RoomReactionImageViewCell.self)
        self.collectionView.reloadData()
    }
    
    private func updateCollectionViewLayout(for alignment: RoomReactionsViewAlignment) {
        
        let collectionViewLayout = self.collectionViewLayout(for: alignment)
        
        self.collectionView.collectionViewLayout = collectionViewLayout
        
        if let collectionViewFlowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            collectionViewFlowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            collectionViewFlowLayout.minimumInteritemSpacing = Constants.minimumInteritemSpacing
            collectionViewFlowLayout.minimumLineSpacing = Constants.minimumLineSpacing
        }
        
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func collectionViewLayout(for alignment: RoomReactionsViewAlignment) -> UICollectionViewLayout {
        
        let collectionViewLayout: UICollectionViewLayout
        
        switch alignment {
        case .left:
            collectionViewLayout = UICollectionViewLeftAlignedLayout()
        case .right:
            collectionViewLayout = UICollectionViewRightAlignedLayout()
        }
        
        return collectionViewLayout
    }
    
    private func setupLongPressGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gestureRecognizer.delaysTouchesBegan = true
        self.collectionView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else {
            return
        }
        self.viewModel?.process(viewAction: .longPress)
    }
    
    private func fill(reactionsViewData: [RoomReactionViewData], remainingViewData: [RoomReactionViewData], showAllButtonState: RoomReactionsViewState.ShowAllButtonState, showAddReaction: Bool) {
        self.reactionsViewData = reactionsViewData
        self.remainingViewData = remainingViewData
        self.showAllButtonState = showAllButtonState
        self.showAddReaction = showAddReaction
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    private func actionButtonString(at indexPath: IndexPath) -> String {
        let actionString: String
        if indexPath.row == self.reactionsViewData.count && self.showAllButtonState != .none {
            switch self.showAllButtonState {
            case .showAll:
                actionString = VectorL10n.roomEventActionReactionMore("\(remainingViewData.count)")
            case .showLess:
                actionString = VectorL10n.roomEventActionReactionShowLess
            case .none:
                actionString = ""
            }
        } else {
            actionString = VectorL10n.add.capitalized
        }

        return actionString
    }
}

// MARK: - UICollectionViewDataSource
extension RoomReactionsView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // "Show all" or "Show less" is a cell in the same section as reactions cells
        var additionalItems = self.showAllButtonState == .none ? 0 : 1
        if self.showAddReaction {
            additionalItems += 1
        }

        return self.reactionsViewData.count + additionalItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row < self.reactionsViewData.count {
            let cell: RoomReactionViewCell = collectionView.dequeueReusableCell(for: indexPath)

            if let theme = self.theme {
                cell.update(theme: theme)
            }

            let viewData = self.reactionsViewData[indexPath.row]
            cell.fill(viewData: viewData)

            return cell
        } else {
            if indexPath.row == self.reactionsViewData.count && self.showAllButtonState != .none {
                let cell: RoomReactionActionViewCell = collectionView.dequeueReusableCell(for: indexPath)

                if let theme = self.theme {
                    cell.update(theme: theme)
                }

                let actionString = self.actionButtonString(at: indexPath)
                cell.fill(actionString: actionString)
                
                return cell
            } else {
                let cell: RoomReactionImageViewCell = collectionView.dequeueReusableCell(for: indexPath)

                if let theme = self.theme {
                    cell.update(theme: theme)
                }

                cell.fill(actionIcon: Asset.Images.reactionsMoreAction.image)
                
                return cell
            }

        }
    }
}

// MARK: - UICollectionViewDelegate
extension RoomReactionsView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row < self.reactionsViewData.count {
            self.viewModel?.process(viewAction: .tapReaction(index: indexPath.row))
        } else {
            if indexPath.row == self.reactionsViewData.count && self.showAllButtonState != .none {
                switch self.showAllButtonState {
                case .showAll:
                    self.viewModel?.process(viewAction: .tapShowAction(action: .showAll))
                case .showLess:
                    self.viewModel?.process(viewAction: .tapShowAction(action: .showLess))
                case .none:
                    break
                }
            } else {
                self.viewModel?.process(viewAction: .tapShowAction(action: .addReaction))
            }
        }
    }
}

// MARK: - RoomReactionsViewModelViewDelegate
extension RoomReactionsView: RoomReactionsViewModelViewDelegate {
    
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didUpdateViewState viewState: RoomReactionsViewState) {
        switch viewState {
        case .loaded(reactionsViewData: let reactionsViewData, remainingViewData: let remainingViewData, showAllButtonState: let showAllButtonState, showAddReaction: let showAddReaction):
            self.fill(reactionsViewData: reactionsViewData, remainingViewData: remainingViewData, showAllButtonState: showAllButtonState, showAddReaction: showAddReaction)
        }
    }
}
