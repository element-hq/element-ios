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

class UserAnnotationCalloutContentView: UIView, Themable, NibLoadable {
    // MARK: - Constants
    
    private static let sizingView = UserAnnotationCalloutContentView.instantiate()
    
    private enum Constants {
        static let height: CGFloat = 44.0
        static let cornerRadius: CGFloat = 8.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var shareButton: UIButton!
    
    // MARK: - Setup
    
    static func instantiate() -> UserAnnotationCalloutContentView {
        UserAnnotationCalloutContentView.loadFromNib()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        backgroundView.backgroundColor = theme.colors.background
        titleLabel.textColor = theme.colors.secondaryContent
        titleLabel.font = theme.fonts.callout
        shareButton.tintColor = theme.colors.secondaryContent
    }

    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.text = VectorL10n.locationSharingLiveMapCalloutTitle
        backgroundView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundView.layer.cornerRadius = Constants.cornerRadius
    }
    
    static func contentViewSize() -> CGSize {
        let sizingView = sizingView

        sizingView.frame = CGRect(x: 0, y: 0, width: 1, height: Constants.height)

        sizingView.setNeedsLayout()
        sizingView.layoutIfNeeded()

        let fittingSize = CGSize(width: UIView.layoutFittingCompressedSize.width, height: Constants.height)

        let size = sizingView.systemLayoutSizeFitting(fittingSize,
                                                      withHorizontalFittingPriority: .fittingSizeLevel,
                                                      verticalFittingPriority: .required)

        return size
    }
}
