// 
// Copyright 2021 New Vector Ltd
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

import UIKit

/// A view controller that provides a preview of a room for use in context menus.
@objcMembers
class RoomPreviewViewController: UIViewController {
    
    // MARK: - Constants
    private enum Constants {
        static let size = CGSize(width: 80, height: 115)
    }
    
    // MARK: - Private
    
    private var cellData: MXKCellData
    
    // MARK: - Setup
    
    init(cellData: MXKCellData) {
        self.cellData = cellData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecyle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cell = RoomCollectionViewCell(frame: CGRect(origin: .zero, size: Constants.size))
        cell.render(cellData)
        view.vc_addSubViewMatchingParent(cell)
        
        preferredContentSize = Constants.size
    }
    
}
