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

class HomeViewControllerWithBannerWrapperViewController: UIViewController, MXKViewControllerActivityHandling, BannerPresentationProtocol, MasterTabBarItemDisplayProtocol {
    
    @objc let homeViewController: HomeViewController
    private var bannerContainerView: UIView!
    private var stackView: UIStackView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        homeViewController.preferredStatusBarStyle
    }
    
    init(viewController: HomeViewController) {
        self.homeViewController = viewController
        
        super.init(nibName: nil, bundle: nil)
        
        extendedLayoutIncludesOpaqueBars = true
        
        self.tabBarItem.tag = viewController.tabBarItem.tag
        self.tabBarItem.image = viewController.tabBarItem.image
        self.accessibilityLabel = viewController.accessibilityLabel
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([stackView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                                     stackView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                                     stackView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                                     stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)])

        addChild(homeViewController)
        stackView.addArrangedSubview(homeViewController.view)
        homeViewController.didMove(toParent: self)
    }
        
    // MARK: - BannerPresentationProtocol
    
    func presentBannerView(_ bannerView: UIView, animated: Bool) {
        bannerView.alpha = 0.0
        bannerView.isHidden = true
        self.stackView.insertArrangedSubview(bannerView, at: 0)
        self.stackView.layoutIfNeeded()
        
        UIView.animate(withDuration: (animated ? 0.25 : 0.0)) {
            bannerView.alpha = 1.0
            bannerView.isHidden = false
            self.stackView.layoutIfNeeded()
        }
    }
    
    func dismissBannerView(animated: Bool) {
        guard stackView.arrangedSubviews.count > 1, let bannerView = self.stackView.arrangedSubviews.first else {
            return
        }
        
        UIView.animate(withDuration: (animated ? 0.25 : 0.0)) {
            bannerView.alpha = 0.0
            bannerView.isHidden = true
            self.stackView.layoutIfNeeded()
        } completion: { _ in
            bannerView.removeFromSuperview()
        }
    }
    
    // MARK: - MXKViewControllerActivityHandling
    var activityIndicator: UIActivityIndicatorView! {
        get {
            return homeViewController.activityIndicator
        }
        set {
            homeViewController.activityIndicator = newValue
        }
    }
    
    var providesCustomActivityIndicator: Bool {
        return homeViewController.providesCustomActivityIndicator
    }

    func startActivityIndicator() {
        homeViewController.startActivityIndicator()
    }

    func stopActivityIndicator() {
        homeViewController.stopActivityIndicator()
    }
    
    // MARK: - MasterTabBarItemDisplayProtocol
    
    var masterTabBarItemTitle: String {
        return VectorL10n.titleHome
    }
}
