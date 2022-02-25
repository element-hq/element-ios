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
        static let padding = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        static let shadowOffset = CGSize(width: 0, height: 4)
        static let shadowRadius = CGFloat(12)
        static let shadowOpacity = Float(0.1)
    }
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 5
        return stack
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.transform = .init(scaleX: 0.75, y: 0.75)
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
        setupLayer()
        setupStackView()
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(label)
        label.text = text
    }
    
    private func setupStackView() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.padding.top),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.padding.bottom),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding.right)
        ])
    }
    
    private func setupLayer() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = Constants.shadowOffset
        layer.shadowRadius = Constants.shadowRadius
        layer.shadowOpacity = Constants.shadowOpacity
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = layer.frame.height / 2
    }
    
    func update(theme: Theme) {
        backgroundColor = UIColor.white
        label.font = theme.fonts.subheadline
    }
}
