// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit
import MatrixSDK

final class LabelledActivityIndicatorView: UIView, Themable {
    private enum Constants {
        static let padding = UIEdgeInsets(top: 20, left: 40, bottom: 15, right: 40)
        static let activityIndicatorScale = CGFloat(1.5)
        static let cornerRadius: CGFloat = 12.0
        static let stackBackgroundOpacity: CGFloat = 0.9
        static let stackSpacing: CGFloat = 15
        static let backgroundOpacity: CGFloat = 0.5
    }
    
    private let stackBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Constants.cornerRadius
        view.alpha = Constants.stackBackgroundOpacity
        return view
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = Constants.stackSpacing
        return stack
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.transform = .init(scaleX: Constants.activityIndicatorScale, y: Constants.activityIndicatorScale)
        view.startAnimating()
        return view
    }()
    
    private let label: UILabel = {
        return UILabel()
    }()
    
    init(text: String) {
        super.init(frame: .zero)
        setup(text: text)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(text: String) {
        setupStackView()
        label.text = text
    }
        
    private func setupStackView() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(label)
        
        insertSubview(stackBackgroundView, belowSubview: stackView)
        stackBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackBackgroundView.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -Constants.padding.top),
            stackBackgroundView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: Constants.padding.bottom),
            stackBackgroundView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -Constants.padding.left),
            stackBackgroundView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: Constants.padding.right)
        ])
    }
    
    func update(theme: Theme) {
        backgroundColor = theme.colors.primaryContent.withAlphaComponent(Constants.backgroundOpacity)
        stackBackgroundView.backgroundColor = theme.colors.system
        activityIndicator.color = theme.colors.secondaryContent
        label.font = theme.fonts.calloutSB
        label.textColor = theme.colors.secondaryContent
    }
}
