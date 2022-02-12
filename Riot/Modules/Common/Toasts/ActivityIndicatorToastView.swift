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

import Foundation
import UIKit
import DesignKit

class ActivityIndicatorToastView: UIView, Themable {
    private struct Constants {
        static let padding: UIEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
    }
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 5
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Constants.padding.top),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.padding.bottom),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding.left),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding.right)
        ])
        
        return stack
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.transform = .init(scaleX: 0.75, y: 0.75)
        view.startAnimating()
        return view
    }()
    
    private lazy var label: UILabel = {
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
        setupLayer()
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(label)
        label.text = text
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupLayer() {
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .init(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.shadowOpacity = 0.1
    }
    
    func update(theme: Theme) {
        backgroundColor = UIColor.white
        label.font = theme.fonts.subheadline
    }
}
