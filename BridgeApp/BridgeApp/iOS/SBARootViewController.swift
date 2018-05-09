//
//  SBARootViewController.swift
//  BridgeApp (iOS)
//
//  Copyright © 2016-2018 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit

/// The "state" of the application. This can be used to track what view controller is currently being
/// displayed.
public enum SBAApplicationState : Equatable {
    
    /// Initial launch view.
    case launch
    
    /// Main view showing activities, etc. for the signed in user.
    case main
    
    /// Study overview (onboarding) for the user who is *not* signed in.
    case onboarding
    
    /// Unrecoverable error state. Displayed when the app must be updated or has reached end-of-life.
    case catastrophicError
    
    /// A custom state that is defined by a specific application.
    case custom(String)
    
    /// The string for the custom root view controller state.
    public var customState: String? {
        if case .custom(let str) = self {
            return str
        } else {
            return nil
        }
    }
}

extension SBAApplicationState : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .custom(value)
    }
}

/// `SBARootViewController` is a root view controller implementation that allows the current "root"
/// to be transitioned while there is a modal view controller displayed on top of the root. For
/// example, when displaying a passcode or during onboarding.
open class SBARootViewController: UIViewController {
    
    /// The current state of the app.
    public private(set) var state: SBAApplicationState = .launch
    
    /// Should the content of the app be hidden when in the background?
    public var contentHidden = false {
        didSet {
            guard contentHidden != oldValue && isViewLoaded else { return }
            self.childViewControllers.first?.view.isHidden = contentHidden
        }
    }
    
    /// The status bar style to use for the view controller currently being shown. This only works with
    /// projects set with view-controller-based status bar style.
    open var statusBarStyle: UIStatusBarStyle = .default {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    /// - returns: The `statusBarStyle` property value.
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    /// Initialize using an initial unloaded root view controller. This is used to track state during
    /// launch.
    public init(rootViewController: UIViewController?) {
        super.init(nibName: nil, bundle: nil)
        _unloadedRootViewController = rootViewController
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        // If there is no root view controller already loaded then do so now.
        if self.childViewControllers.first == nil {
            let isBlankVC = (_unloadedRootViewController == nil)
            let viewController = self.rootViewController
            self.addChildViewController(viewController)
            viewController.view.frame = self.view.bounds
            viewController.view.isHidden = contentHidden
            if isBlankVC {
                viewController.view.backgroundColor = UIColor.white
            }
            self.view.addSubview(viewController.view)
            viewController.didMove(toParentViewController: self)
        }
    }
    
    /// The root view controller for the application.
    public var rootViewController: UIViewController {
        return self.childViewControllers.first ?? {
            if _unloadedRootViewController == nil {
                _unloadedRootViewController = UIViewController()
            }
            return _unloadedRootViewController!
        }()
    }
    private var _unloadedRootViewController: UIViewController?
    
    /// The animation duration when transitioning between view controllers.
    public var animationDuration: TimeInterval = 0.3
    
    /// The animation options when transitioning between view controllers.
    public var animationOptions: UIViewAnimationOptions = [.transitionCrossDissolve]
    
    /// Set the new root view controller. This will use a crossfade animation to transition between the
    /// two root view controllers.
    public func set(viewController: UIViewController, state: SBAApplicationState, animated: Bool) {
        
        guard isViewLoaded else {
            _unloadedRootViewController = viewController
            self.state = state
            return
        }
        
        // Set up state for view controllers.
        self.rootViewController.willMove(toParentViewController: nil)
        self.addChildViewController(viewController)
        self.state = state
        
        // Set up new view initial alpha and frame.
        viewController.view.frame = self.view.bounds
        
        let duration = animated ? animationDuration : 0.0
        self.transition(from: self.rootViewController, to: viewController,
                        duration: duration, options: animationOptions,
                        animations: {}) { (finished) in
                            self.rootViewController.removeFromParentViewController()
                            viewController.didMove(toParentViewController: self)
        }
    }
}
