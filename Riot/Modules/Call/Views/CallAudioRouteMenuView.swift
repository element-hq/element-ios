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

@objc
protocol CallAudioRouteMenuViewDelegate: AnyObject {
    func callAudioRouteMenuView(_ view: CallAudioRouteMenuView, didSelectRoute route: MXAudioOutputRoute)
}

@objcMembers
class CallAudioRouteMenuView: UIStackView {
    
    private enum Constants {
        static let routeHeight: CGFloat = 62
    }
    
    let routes: [MXAudioOutputRoute]
    let currentRoute: MXAudioOutputRoute?
    
    private var theme: Theme = DefaultTheme()
    
    weak var delegate: CallAudioRouteMenuViewDelegate?
    
    init(withRoutes routes: [MXAudioOutputRoute],
         currentRoute: MXAudioOutputRoute?) {
        self.routes = routes
        self.currentRoute = currentRoute
        super.init(frame: .zero)
        setup()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        axis = .vertical
        alignment = .fill
        distribution = .fillEqually
        
        for (index, route) in routes.enumerated() {
            let routeView = CallAudioRouteView(withRoute: route,
                                               isSelected: route == currentRoute,
                                               isBottomLineHidden: index == routes.count - 1)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(routeTapped(_:)))
            routeView.addGestureRecognizer(tapGesture)
            
            addArrangedSubview(routeView)
        }
        
        update(theme: theme)
    }
    
    @objc
    private func routeTapped(_ sender: UITapGestureRecognizer) {
        if let routeView = sender.view as? CallAudioRouteView {
            delegate?.callAudioRouteMenuView(self, didSelectRoute: routeView.route)
        }
    }
    
}

extension CallAudioRouteMenuView: Themable {
    
    func update(theme: Theme) {
        self.theme = DefaultTheme()
        
        backgroundColor = self.theme.colors.navigation
        
        for view in arrangedSubviews {
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
