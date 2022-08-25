// File created from ScreenTemplate
// $ createScreen.sh toto EmojiPicker
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

import Reusable
import UIKit

final class EmojiPickerViewController: UIViewController {
    // MARK: - Constants
    
    private enum CollectionViewLayout {
        static let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        static let minimumInteritemSpacing: CGFloat = 6.0
        static let minimumLineSpacing: CGFloat = 2.0
        static let itemSize = CGSize(width: 50, height: 50)
    }
    
    private static let sizingHeaderView = EmojiPickerHeaderView.loadFromNib()
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private var collectionView: UICollectionView!
    
    // MARK: Private

    private var viewModel: EmojiPickerViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var searchController: UISearchController?
    private var emojiCategories: [EmojiPickerCategoryViewData] = []

    // MARK: - Setup
    
    class func instantiate(with viewModel: EmojiPickerViewModelType) -> EmojiPickerViewController {
        let viewController = StoryboardScene.EmojiPickerViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        title = VectorL10n.emojiPickerTitle
        
        setupViews()
        keyboardAvoider = KeyboardAvoider(scrollViewContainerView: view, scrollView: collectionView)
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self
        viewModel.process(viewAction: .loadData)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        keyboardAvoider?.startAvoiding()
        
        // Update theme here otherwise the UISearchBar search text color is not updated
        update(theme: theme)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Enable to hide search bar on scrolling after first time view appear
        // Commenting out below code for now. It broke the navigation bar background. For details: https://github.com/vector-im/riot-ios/issues/3271
        // self.navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        keyboardAvoider?.stopAvoiding()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.backgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        if let searchController = searchController {
            theme.applyStyle(onSearchBar: searchController.searchBar)
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        setupCollectionView()
        
        setupSearchController()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.keyboardDismissMode = .interactive
        
        if let collectionViewFlowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            collectionViewFlowLayout.minimumInteritemSpacing = CollectionViewLayout.minimumInteritemSpacing
            collectionViewFlowLayout.minimumLineSpacing = CollectionViewLayout.minimumLineSpacing
            collectionViewFlowLayout.itemSize = CollectionViewLayout.itemSize
            collectionViewFlowLayout.sectionInset = CollectionViewLayout.sectionInsets
            collectionViewFlowLayout.sectionHeadersPinToVisibleBounds = true // Enable sticky headers
            
            // Avoid device notch in landscape (e.g. iPhone X)
            collectionViewFlowLayout.sectionInsetReference = .fromSafeArea
        }
        
        collectionView.register(supplementaryViewType: EmojiPickerHeaderView.self, ofKind: UICollectionView.elementKindSectionHeader)
        collectionView.register(cellType: EmojiPickerViewCell.self)
    }
    
    private func setupSearchController() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = VectorL10n.searchDefaultPlaceholder
        searchController.hidesNavigationBarDuringPresentation = false
        
        navigationItem.searchController = searchController
        // Make the search bar visible on first view appearance
        navigationItem.hidesSearchBarWhenScrolling = false
        
        definesPresentationContext = true
        
        self.searchController = searchController
    }

    private func render(viewState: EmojiPickerViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(emojiCategories: let emojiCategories):
            renderLoaded(emojiCategories: emojiCategories)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(emojiCategories: [EmojiPickerCategoryViewData]) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        update(emojiCategories: emojiCategories)
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func update(emojiCategories: [EmojiPickerCategoryViewData]) {
        self.emojiCategories = emojiCategories
        collectionView.reloadData()
    }
    
    private func emojiItemViewData(at indexPath: IndexPath) -> EmojiPickerItemViewData {
        emojiCategories[indexPath.section].emojiViewDataList[indexPath.row]
    }
    
    private func emojiCategoryViewData(at section: Int) -> EmojiPickerCategoryViewData? {
        emojiCategories[section]
    }
    
    private func headerViewSize(for title: String) -> CGSize {
        let sizingHeaderView = EmojiPickerViewController.sizingHeaderView
        
        sizingHeaderView.fill(with: title)
        sizingHeaderView.setNeedsLayout()
        sizingHeaderView.layoutIfNeeded()
        
        var fittingSize = UIView.layoutFittingCompressedSize
        fittingSize.width = collectionView.bounds.size.width
        
        return sizingHeaderView.systemLayoutSizeFitting(fittingSize)
    }
    
    // MARK: - Actions

    private func cancelButtonAction() {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - UICollectionViewDataSource

extension EmojiPickerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        emojiCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        emojiCategories[section].emojiViewDataList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let emojiPickerCategory = emojiCategories[indexPath.section]
        
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, for: indexPath) as EmojiPickerHeaderView
        headerView.update(theme: theme)
        headerView.fill(with: emojiPickerCategory.name)
        
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: EmojiPickerViewCell = collectionView.dequeueReusableCell(for: indexPath)
        
        if let theme = theme {
            cell.update(theme: theme)
        }
        
        let viewData = emojiItemViewData(at: indexPath)
        cell.fill(viewData: viewData)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension EmojiPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emojiItemViewData = emojiItemViewData(at: indexPath)
        viewModel.process(viewAction: .tap(emojiItemViewData: emojiItemViewData))
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        // Fix UICollectionView scroll bar appears underneath header view
        view.layer.zPosition = 0.0
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension EmojiPickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let emojiCategory = emojiCategories[section]
        let headerSize = headerViewSize(for: emojiCategory.name)
        return headerSize
    }
}

// MARK: - EmojiPickerViewModelViewDelegate

extension EmojiPickerViewController: EmojiPickerViewModelViewDelegate {
    func emojiPickerViewModel(_ viewModel: EmojiPickerViewModelType, didUpdateViewState viewSate: EmojiPickerViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - UISearchResultsUpdating

extension EmojiPickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        viewModel.process(viewAction: .search(text: searchText))
    }
}
