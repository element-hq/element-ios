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

class ReactionsMenuButton: UIButton, Themable {

    // MARK: - Constants
    
    private enum Constants {
        static let borderWidthSelected: CGFloat = 1/UIScreen.main.scale
        static let borderColorAlpha: CGFloat = 0.15
    }
    
    // MARK: - Properties

    private var theme: Theme!

    // MARK: - Setup

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    // MARK: - Life cycle

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.size.height / 3
        self.layer.borderWidth = self.isSelected ? Constants.borderWidthSelected : 0
    }

    // MARK: - Private

    private func commonInit() {
        self.layer.masksToBounds = true

        self.update(theme: ThemeService.shared().theme)

        customizeViewRendering()
        updateView()
    }

    private func customizeViewRendering() {
        self.tintColor = UIColor.clear
    }

    func update(theme: Theme) {
        self.theme = theme
        
        self.setTitleColor(self.theme.textPrimaryColor, for: .normal)
        self.setTitleColor(self.theme.textPrimaryColor, for: .selected)

        self.layer.borderColor = self.theme.tintColor.withAlphaComponent(Constants.borderColorAlpha).cgColor
    }

    private func updateView() {
        backgroundColor = isSelected ? self.theme.tintBackgroundColor : UIColor.clear
    }

    override open var isSelected: Bool {
        didSet {
            self.updateView()
        }
    }
}
