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

import Foundation
import UIKit

/// Used to present activity indicator on a view
final class ActivityIndicatorPresenter: ActivityIndicatorPresenterType {
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.3
        static let backgroundOverlayColor = UIColor.clear
        static let backgroundOverlayAlpha: CGFloat = 1.0
    }
    
    // MARK: - Properties
    
    private weak var backgroundOverlayView: UIView?
    private weak var activityIndicatorView: ActivityIndicatorView?
    private weak var presentingView: UIView?
    
    var isPresenting: Bool {
        activityIndicatorView != nil
    }
    
    // MARK: - Public
    
    func presentActivityIndicator(on view: UIView, animated: Bool, completion: (() -> Void)? = nil) {
        if presentingView != nil {
            if let completion = completion {
                completion()
            }
            return
        }

        presentingView = view
        
        view.isUserInteractionEnabled = false
        
        let backgroundOverlayView = createBackgroundOverlayView(with: view.frame)
        
        let activityIndicatorView = ActivityIndicatorView()
        
        // Add activityIndicatorView on backgroundOverlayView centered
        backgroundOverlayView.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.centerXAnchor.constraint(equalTo: backgroundOverlayView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: backgroundOverlayView.centerYAnchor).isActive = true
        
        activityIndicatorView.startAnimating()
        
        backgroundOverlayView.alpha = 0
        backgroundOverlayView.isHidden = false
        
        view.vc_addSubViewMatchingParent(backgroundOverlayView)
        
        self.backgroundOverlayView = backgroundOverlayView
        self.activityIndicatorView = activityIndicatorView
        
        let animationInstructions = {
            backgroundOverlayView.alpha = Constants.backgroundOverlayAlpha
        }
        
        if animated {
            UIView.animate(withDuration: Constants.animationDuration, animations: {
                animationInstructions()
            }, completion: { _ in
                completion?()
            })
        } else {
            animationInstructions()
            completion?()
        }
    }
    
    func removeCurrentActivityIndicator(animated: Bool, completion: (() -> Void)? = nil) {
        guard let presentingView = presentingView,
              let backgroundOverlayView = backgroundOverlayView,
              let activityIndicatorView = activityIndicatorView else {
            return
        }
        
        presentingView.isUserInteractionEnabled = true
        self.presentingView = nil
        
        let animationInstructions = {
            activityIndicatorView.alpha = 0
        }
        
        let animationCompletionInstructions = {
            activityIndicatorView.stopAnimating()
            backgroundOverlayView.isHidden = true
            backgroundOverlayView.removeFromSuperview()
        }
        
        if animated {
            UIView.animate(withDuration: Constants.animationDuration, animations: {
                animationInstructions()
            }, completion: { _ in
                animationCompletionInstructions()
            })
        } else {
            animationInstructions()
            animationCompletionInstructions()
        }
    }
    
    // MARK: - Private
    
    private func createBackgroundOverlayView(with frame: CGRect = CGRect.zero) -> UIView {
        let backgroundOverlayView = UIView(frame: frame)
        backgroundOverlayView.backgroundColor = Constants.backgroundOverlayColor
        backgroundOverlayView.alpha = Constants.backgroundOverlayAlpha
        return backgroundOverlayView
    }
}
