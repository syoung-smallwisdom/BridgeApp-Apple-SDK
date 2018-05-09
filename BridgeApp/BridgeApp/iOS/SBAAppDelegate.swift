//
//  SBAAppDelegate.swift
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

/// `SBAAppDelegate` is an optional class that can be used as the appDelegate for an application.
open class SBAAppDelegate : UIResponder, UIApplicationDelegate, RSDAlertPresenter, SBBBridgeErrorUIDelegate {
    
    open var window: UIWindow?
    
    // MARK: UIApplicationDelegate
    
    open func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization before application launch.
        
        // Set up bridge.
        BridgeSDK.setErrorUIDelegate(self)
        SBABridgeConfiguration.shared.setupBridge(with: SBAFactory())
        
        // Set the tint color.
        self.window?.tintColor = UIColor.primaryTintColor
        
        // Replace the launch root view controller with an SBARootViewController
        // This allows transitioning between root view controllers while a lock screen
        // or onboarding view controller is being presented modally.
        self.window?.rootViewController = SBARootViewController(rootViewController: self.window?.rootViewController)
        
        return true
    }
    
    open func applicationDidBecomeActive(_ application: UIApplication) {
        // Make sure that the content view controller is not hiding content.
        rootViewController?.contentHidden = false
    }
    

    // ------------------------------------------------
    // MARK: RootViewController management
    // ------------------------------------------------
    
    /// The root view controller for this app. By default, this is set up in `willFinishLaunchingWithOptions`
    /// as the root view controller for the key window. This container view controller allows presenting
    /// onboarding flow or a passcode modally while transitioning the underlying view controller for the
    /// appropriate app state.
    open var rootViewController: SBARootViewController? {
        return window?.rootViewController as? SBARootViewController
    }
    
    /// Convenience method for transitioning to the given view controller as the main window
    /// rootViewController.
    /// - parameters:
    ///     - viewController: View controller to transition to.
    ///     - state: State of the app.
    ///     - animated: Should the transition be animated?
    open func transition(to viewController: UIViewController, state: SBARootViewController.State, animated: Bool) {
        guard let window = self.window, rootViewController?.state != state else { return }
        if let root = self.rootViewController {
            root.set(viewController: viewController, state: state, animated: animated)
        }
        else {
            if (animated) {
                UIView.transition(with: window,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    window.rootViewController = viewController
                },
                                  completion: nil)
            }
            else {
                window.rootViewController = viewController
            }
        }
    }
    
    
    // ------------------------------------------------
    // MARK: RSDAlertPresenter
    // ------------------------------------------------
    
    /// Convenience method for presenting a modal view controller.
    open func presentModal(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        guard let rootVC = self.window?.rootViewController else { return }
        var topViewController: UIViewController = rootVC
        while let presentedVC = topViewController.presentedViewController {
            if presentedVC.modalPresentationStyle != .fullScreen {
                presentedVC.dismiss(animated: false, completion: nil)
                break
            }
            else {
                topViewController = presentedVC
            }
        }
        topViewController.present(viewController, animated: animated, completion: completion)
    }
    
    
    // ------------------------------------------------
    // MARK: Catastrophic startup errors
    // ------------------------------------------------
    
    private var catastrophicStartupError: Error?
    
    /// Catastrophic Errors are errors from which the system cannot recover. By default,
    /// this will display a screen that blocks all activity. The user is then asked to
    /// update their app.
    ///
    /// - parameter animated:  Should the transition be animated?
    open func showCatastrophicStartupErrorViewController(animated: Bool) {
        
        guard self.rootViewController?.state != .catastrophicError else { return }
        
        // If we cannot open the catastrophic error view controller (for some reason)
        // then this is a fatal error
        guard let vc = SBACatastrophicErrorViewController.instantiateWithMessage(catastrophicErrorMessage) else {
            fatalError(catastrophicErrorMessage)
        }
        
        // Present the view controller
        transition(to: vc, state: .catastrophicError, animated: animated)
    }
    
    /// Is there a catastrophic error?
    public final var hasCatastrophicError: Bool {
        return (catastrophicStartupError != nil)
    }
    
    /// Register a catastrophic error. Once launch is complete, this will trigger showing
    /// the error.
    public final func registerCatastrophicStartupError(_ error: Error) {
        self.catastrophicStartupError = error
    }
    
    /// The error message to display for a catastrophic error.
    open var catastrophicErrorMessage: String {
        return catastrophicStartupError?.localizedDescription ??
            Localization.localizedString("CATASTROPHIC_FAILURE_MESSAGE")
    }
    
    
    // ------------------------------------------------
    // MARK: SBBBridgeErrorUIDelegate
    // ------------------------------------------------
    
    /// Default implementation for handling a user who is not consented (because consent has been revoked
    /// by the server).
    open func handleUserNotConsentedError(_ error: Error, sessionInfo: Any, networkManager: SBBNetworkManagerProtocol?) -> Bool {
        // TODO: syoung 05/08/2018 Handle unconsented user.
        return true
    }
    
    /// Default implementation for handling an unsupported app version is to display a catastrophic error.
    open func handleUnsupportedAppVersionError(_ error: Error, networkManager: SBBNetworkManagerProtocol?) -> Bool {
        registerCatastrophicStartupError(error)
        DispatchQueue.main.async {
            if let _ = self.window?.rootViewController {
                self.showCatastrophicStartupErrorViewController(animated: true)
            }
        }
        return true
    }
    
    
    // ------------------------------------------------
    // MARK: Lock orientation to portrait by default
    // ------------------------------------------------
    
    /// The default orientation lock if not overridden by setting the `orientationLock` property.
    open var defaultOrientationLock: UIInterfaceOrientationMask {
        return .portrait
    }
    
    /// The `orientationLock` property is used to override the default allowed orientations.
    public var orientationLock: UIInterfaceOrientationMask?
    
    /// - returns: The `orientationLock` or the `defaultOrientationLock` if nil.
    open func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationLock ?? defaultOrientationLock
    }
}

