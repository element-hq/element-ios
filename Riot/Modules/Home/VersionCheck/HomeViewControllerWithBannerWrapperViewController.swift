// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
