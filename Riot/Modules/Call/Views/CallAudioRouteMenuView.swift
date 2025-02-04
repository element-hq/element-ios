// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc
protocol CallAudioRouteMenuViewDelegate: AnyObject {
    func callAudioRouteMenuView(_ view: CallAudioRouteMenuView, didSelectRoute route: MXiOSAudioOutputRoute)
}

@objcMembers
class CallAudioRouteMenuView: UIView {
    
    private enum Constants {
        static let routeHeight: CGFloat = 62
        static let stackViewInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        static let stackViewCornerRadius: CGFloat = 13
    }
    
    let routes: [MXiOSAudioOutputRoute]
    let currentRoute: MXiOSAudioOutputRoute?
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(frame: bounds.inset(by: Constants.stackViewInsets))
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fillEqually
        view.layer.masksToBounds = true
        view.layer.cornerRadius = Constants.stackViewCornerRadius
        return view
    }()
    
    private var theme: Theme = DefaultTheme()
    
    weak var delegate: CallAudioRouteMenuViewDelegate?
    
    init(withRoutes routes: [MXiOSAudioOutputRoute],
         currentRoute: MXiOSAudioOutputRoute?) {
        self.routes = routes
        self.currentRoute = currentRoute
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: CGFloat(routes.count) * Constants.routeHeight)))
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(stackView)
        
        for (index, route) in routes.enumerated() {
            let routeView = CallAudioRouteView(withRoute: route,
                                               isSelected: route == currentRoute,
                                               isBottomLineHidden: index == routes.count - 1)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(routeTapped(_:)))
            routeView.addGestureRecognizer(tapGesture)
            
            stackView.addArrangedSubview(routeView)
        }
        
        update(theme: theme)
    }
    
    @objc
    private func routeTapped(_ sender: UITapGestureRecognizer) {
        if let routeView = sender.view as? CallAudioRouteView {
            delegate?.callAudioRouteMenuView(self, didSelectRoute: routeView.route)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        stackView.frame = bounds.inset(by: Constants.stackViewInsets)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //  TODO: specific to SlidingModalPresenter, remove bg handling logic from there
        superview?.backgroundColor = .clear
    }
    
}

extension CallAudioRouteMenuView: Themable {
    
    func update(theme: Theme) {
        self.theme = DefaultTheme()
        
        backgroundColor = .clear
        stackView.backgroundColor = self.theme.colors.navigation
        
        for view in stackView.arrangedSubviews {
            if let view = view as? Themable {
                view.update(theme: self.theme)
            }
        }
    }
    
}

extension CallAudioRouteMenuView: SlidingModalPresentable {
    
    func allowsDismissOnBackgroundTap() -> Bool {
        return true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        return CGFloat(routes.count) * Constants.routeHeight
    }
    
}
