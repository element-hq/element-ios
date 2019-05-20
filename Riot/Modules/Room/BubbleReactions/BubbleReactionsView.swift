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
import DGCollectionViewLeftAlignFlowLayout

@objcMembers
final class BubbleReactionsView: UIView, NibOwnerLoadable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let minimumInteritemSpacing: CGFloat = 6.0
        static let minimumLineSpacing: CGFloat = 2.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var collectionView: UICollectionView!
    
    // MARK: Private
    
    private var reactionsViewData: [BubbleReactionViewData] = []
    private var theme: Theme?
    
    // MARK: Public
    
    // Do not use `BubbleReactionsViewModelType` here due to Objective-C incompatibily
    var viewModel: BubbleReactionsViewModel? {
        didSet {
            self.viewModel?.viewDelegate = self
            self.viewModel?.process(viewAction: .loadData)
        }
    }
    
    // MARK: - Setup
    
    private func commonInit() {
        self.collectionView.isScrollEnabled = false
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.collectionViewLayout = DGCollectionViewLeftAlignFlowLayout()
        
        if let collectionViewFlowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            collectionViewFlowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            collectionViewFlowLayout.minimumInteritemSpacing = Constants.minimumInteritemSpacing
            collectionViewFlowLayout.minimumLineSpacing = Constants.minimumLineSpacing
        }
        
        self.collectionView.register(cellType: BubbleReactionViewCell.self)
        self.collectionView.reloadData()
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
    
    func fill(reactionsViewData: [BubbleReactionViewData]) {
        self.reactionsViewData = reactionsViewData
        self.collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource
extension BubbleReactionsView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.reactionsViewData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: BubbleReactionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        
        if let theme = self.theme {
            cell.update(theme: theme)
        }
        
        let viewData = self.reactionsViewData[indexPath.row]
        cell.fill(viewData: viewData)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension BubbleReactionsView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.viewModel?.process(viewAction: .tapReaction(index: indexPath.row))
    }
}

// MARK: - BubbleReactionsViewModelViewDelegate
extension BubbleReactionsView: BubbleReactionsViewModelViewDelegate {
    
    func bubbleReactionsViewModel(_ viewModel: BubbleReactionsViewModel, didUpdateViewState viewState: BubbleReactionsViewState) {
        switch viewState {
        case .loaded(reactionsViewData: let reactionsViewData):
            self.fill(reactionsViewData: reactionsViewData)
        }
    }
}
