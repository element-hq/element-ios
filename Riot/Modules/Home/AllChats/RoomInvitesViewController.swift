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

class RoomInvitesViewController: RecentsViewController {
    
    // MARK: - Class methods
    
    static override func nib() -> UINib! {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self.classForCoder()))
    }
    
    static func instantiate() -> Self {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "RoomInvitesViewController") as? Self else {
            fatalError("No view controller of type \(self) in the main storyboard")
        }
        return viewController
    }
    
    // MARK: - Private
    
    private var recentsDataSource: RecentsDataSource?
    private var tableViewPaginationThrottler: MXThrottler!

    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.enableSearchBar = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.recentsTableView.clipsToBounds = false
        self.recentsTableView.tag = RecentsDataSourceMode.roomInvites.rawValue
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let recentsDataSource = self.dataSource as? RecentsDataSource else {
            return
        }
        
        self.recentsDataSource = recentsDataSource
        
        if recentsDataSource.recentsDataSourceMode != .roomInvites {
            recentsDataSource.setDelegate(self, andRecentsDataSourceMode: .roomInvites)
            recentsDataSource.search(withPatterns: nil)
            recentsSearchBar?.text = nil
        }
    }
    
    // MARK: - RecentsViewController
    
    override func finalizeInit() {
        super.finalizeInit()
        
        title = VectorL10n.roomRecentsInvitesSection.capitalized
        self.screenTracker = AnalyticsScreenTracker(screen: .invites)
        tableViewPaginationThrottler = MXThrottler(minimumDelay: 0.1)
    }

    override func refreshCurrentSelectedCell(_ forceVisible: Bool) {
        // Check whether the recents data source is correctly configured.
        guard self.recentsDataSource?.recentsDataSourceMode == .roomInvites else {
            return
        }
        
        super.refreshCurrentSelectedCell(forceVisible)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
        
        guard tableView.numberOfSections > indexPath.section else {
            return
        }

        let numberOfRowsInSection = tableView.numberOfRows(inSection: indexPath.section)
        guard indexPath.row == numberOfRowsInSection - 1 else {
            return
        }
        
        tableViewPaginationThrottler .throttle { [weak self] in
            self?.recentsDataSource?.paginate(inSection: indexPath.section)
        }
    }
    
    // MARK: - Empty view management
    
    override func updateEmptyView() {
        let image = UIImage(systemName: "envelope.open.fill") ?? UIImage()
        emptyView?.fill(with: image,
                        title: VectorL10n.roomInvitesEmptyViewTitle,
                        informationText: VectorL10n.roomInvitesEmptyViewInformation,
                        displayMode: .icon)
    }
    
}
