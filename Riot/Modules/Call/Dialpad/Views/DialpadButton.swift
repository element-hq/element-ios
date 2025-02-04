// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Digit button class for Dialpad screen
class DialpadButton: UIButton {
    
    struct ViewData {
        let title: String
        let tone: SystemSoundID
        let subtitle: String?
        let showsSubtitleSpace: Bool
        
        init(title: String, tone: SystemSoundID, subtitle: String? = nil, showsSubtitleSpace: Bool = false) {
            self.title = title
            self.tone = tone
            self.subtitle = subtitle
            self.showsSubtitleSpace = showsSubtitleSpace
        }
    }
    
    private var viewData: ViewData?
    private var theme: Theme = ThemeService.shared().theme
    
    private enum Constants {
        static let size: CGSize = CGSize(width: 68, height: 68)
        static let titleFont: UIFont = .boldSystemFont(ofSize: 32)
        static let subtitleFont: UIFont = .boldSystemFont(ofSize: 12)
    }
    
    init() {
        super.init(frame: CGRect(origin: .zero, size: Constants.size))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        clipsToBounds = true
        layer.cornerRadius = Constants.size.width/2
        vc_enableMultiLinesTitle()
    }
    
    func render(withViewData viewData: ViewData) {
        self.viewData = viewData
        
        let totalAttributedString = NSMutableAttributedString(string: viewData.title,
                                                              attributes: [
                                                                .font: Constants.titleFont,
                                                                .foregroundColor: theme.textPrimaryColor
                                                              ])
        
        if let subtitle = viewData.subtitle {
            totalAttributedString.append(NSAttributedString(string: "\n" + subtitle, attributes: [
                .font: Constants.subtitleFont,
                .foregroundColor: theme.textPrimaryColor
            ]))
        } else if viewData.showsSubtitleSpace {
            totalAttributedString.append(NSAttributedString(string: "\n ", attributes: [
                .font: Constants.subtitleFont,
                .foregroundColor: theme.textPrimaryColor
            ]))
        }
        
        setAttributedTitle(totalAttributedString, for: .normal)
    }
    
}

//  MARK: - Themable

extension DialpadButton: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        backgroundColor = theme.headerBackgroundColor
        
        //  re-render view data if set
        if let viewData = self.viewData {
            render(withViewData: viewData)
        }
    }
    
}
