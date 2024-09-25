/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
        return self.activityIndicatorView != nil
    }
    
    // MARK: - Public
    
    func presentActivityIndicator(on view: UIView, animated: Bool, completion: (() -> Void)? = nil) {
        if self.presentingView != nil {
            if let completion = completion {
                completion()
            }
            return
        }

        self.presentingView = view
        
        view.isUserInteractionEnabled = false
        
        let backgroundOverlayView = self.createBackgroundOverlayView(with: view.frame)
        
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
        guard let presentingView = self.presentingView,
            let backgroundOverlayView = self.backgroundOverlayView,
            let activityIndicatorView = self.activityIndicatorView else {
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
