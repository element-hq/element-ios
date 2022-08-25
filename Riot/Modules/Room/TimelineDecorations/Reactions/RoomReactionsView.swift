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
import MatrixSDK
import Reusable
import UICollectionViewLeftAlignedLayout
import UICollectionViewRightAlignedLayout
import UIKit

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

    @IBOutlet private var collectionView: UICollectionView!
    
    // MARK: Private
    
    private var reactionsViewData: [RoomReactionViewData] = []
    private var remainingViewData: [RoomReactionViewData] = []
    private var showAllButtonState: RoomReactionsViewState.ShowAllButtonState = .none
    private var showAddReaction = false
    private var theme: Theme?
    
    // MARK: Public
    
    // Do not use `RoomReactionsViewModelType` here due to Objective-C incompatibily
    var viewModel: RoomReactionsViewModel? {
        didSet {
            viewModel?.viewDelegate = self
            viewModel?.process(viewAction: .loadData)
        }
    }
    
    var alignment: RoomReactionsViewAlignment = .left {
        didSet {
            updateCollectionViewLayout(for: alignment)
        }
    }
    
    // MARK: - Setup
    
    private func commonInit() {
        setupCollectionView()
        setupLongPressGestureRecognizer()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
        commonInit()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.theme = theme
        collectionView.reloadData()
    }

    // MARK: - Private
    
    private func setupCollectionView() {
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        alignment = .left
        
        collectionView.register(cellType: RoomReactionViewCell.self)
        collectionView.register(cellType: RoomReactionActionViewCell.self)
        collectionView.register(cellType: RoomReactionImageViewCell.self)
        collectionView.reloadData()
    }
    
    private func updateCollectionViewLayout(for alignment: RoomReactionsViewAlignment) {
        let collectionViewLayout = collectionViewLayout(for: alignment)
        
        collectionView.collectionViewLayout = collectionViewLayout
        
        if let collectionViewFlowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            collectionViewFlowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            collectionViewFlowLayout.minimumInteritemSpacing = Constants.minimumInteritemSpacing
            collectionViewFlowLayout.minimumLineSpacing = Constants.minimumLineSpacing
        }
        
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
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
        collectionView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else {
            return
        }
        viewModel?.process(viewAction: .longPress)
    }
    
    private func fill(reactionsViewData: [RoomReactionViewData], remainingViewData: [RoomReactionViewData], showAllButtonState: RoomReactionsViewState.ShowAllButtonState, showAddReaction: Bool) {
        self.reactionsViewData = reactionsViewData
        self.remainingViewData = remainingViewData
        self.showAllButtonState = showAllButtonState
        self.showAddReaction = showAddReaction
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func actionButtonString(at indexPath: IndexPath) -> String {
        let actionString: String
        if indexPath.row == reactionsViewData.count, showAllButtonState != .none {
            switch showAllButtonState {
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
        var additionalItems = showAllButtonState == .none ? 0 : 1
        if showAddReaction {
            additionalItems += 1
        }

        return reactionsViewData.count + additionalItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row < reactionsViewData.count {
            let cell: RoomReactionViewCell = collectionView.dequeueReusableCell(for: indexPath)

            if let theme = theme {
                cell.update(theme: theme)
            }

            let viewData = reactionsViewData[indexPath.row]
            cell.fill(viewData: viewData)

            return cell
        } else {
            if indexPath.row == reactionsViewData.count, showAllButtonState != .none {
                let cell: RoomReactionActionViewCell = collectionView.dequeueReusableCell(for: indexPath)

                if let theme = theme {
                    cell.update(theme: theme)
                }

                let actionString = actionButtonString(at: indexPath)
                cell.fill(actionString: actionString)
                
                return cell
            } else {
                let cell: RoomReactionImageViewCell = collectionView.dequeueReusableCell(for: indexPath)

                if let theme = theme {
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
        if indexPath.row < reactionsViewData.count {
            viewModel?.process(viewAction: .tapReaction(index: indexPath.row))
        } else {
            if indexPath.row == reactionsViewData.count, showAllButtonState != .none {
                switch showAllButtonState {
                case .showAll:
                    viewModel?.process(viewAction: .tapShowAction(action: .showAll))
                case .showLess:
                    viewModel?.process(viewAction: .tapShowAction(action: .showLess))
                case .none:
                    break
                }
            } else {
                viewModel?.process(viewAction: .tapShowAction(action: .addReaction))
            }
        }
    }
}

// MARK: - RoomReactionsViewModelViewDelegate

extension RoomReactionsView: RoomReactionsViewModelViewDelegate {
    func roomReactionsViewModel(_ viewModel: RoomReactionsViewModel, didUpdateViewState viewState: RoomReactionsViewState) {
        switch viewState {
        case .loaded(reactionsViewData: let reactionsViewData, remainingViewData: let remainingViewData, showAllButtonState: let showAllButtonState, showAddReaction: let showAddReaction):
            fill(reactionsViewData: reactionsViewData, remainingViewData: remainingViewData, showAllButtonState: showAllButtonState, showAddReaction: showAddReaction)
        }
    }
}
