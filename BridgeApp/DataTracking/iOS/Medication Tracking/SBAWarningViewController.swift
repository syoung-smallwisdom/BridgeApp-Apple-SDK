//
//  SBAWarningViewController.swift
//  BridgeApp (iOS)
//
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
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

import Foundation
import Research
import ResearchUI
import UIKit

protocol SBAWarningViewControllerDelegate : class {
    func cancel(_ viewController: SBAWarningViewController)
    func removeItem(_ viewController: SBAWarningViewController)
}

class SBAWarningViewController : UIViewController {
    
    weak var delegate: SBAWarningViewControllerDelegate?
    var item: Any!
    
    var text: String? {
        didSet {
            titleLabel?.text = self.text
        }
    }
    
    var detailText: String? {
        didSet {
            detailLabel?.text = self.detailText
        }
    }
    
    var buttonTitle: String? {
        didSet {
            footerView?.nextButton?.setTitle(self.buttonTitle ?? Localization.buttonOK(), for: .normal)
        }
    }
    
    @IBOutlet weak var statusBarView: RSDStatusBarBackgroundView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerView: RSDGenericNavigationFooterView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    @IBAction func cancelTapped(_ sender: Any) {
        delegate?.cancel(self)
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        delegate?.removeItem(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel?.text = self.text
        detailLabel?.text = self.detailText
        footerView!.nextButton!.setTitle(self.buttonTitle ?? Localization.buttonOK(), for: .normal)
        footerView!.nextButton!.addTarget(self, action: #selector(nextTapped(_:)), for: .touchUpInside)

        updateColorsAndFonts()
    }
    
    var designSystem: RSDDesignSystem? {
        didSet {
            self.updateColorsAndFonts()
        }
    }
    
    func updateColorsAndFonts() {
        guard let designSystem = self.designSystem, isViewLoaded else { return }
        
        let background = designSystem.colorRules.backgroundLight
        self.view.backgroundColor = background.color
        self.footerView.setDesignSystem(designSystem, with: background)
        self.titleLabel.font = designSystem.fontRules.font(for: .largeHeader, compatibleWith: self.traitCollection)
        self.titleLabel.textColor = designSystem.colorRules.textColor(on: background, for: .largeHeader)
        self.detailLabel.font = designSystem.fontRules.font(for: .small)
        self.detailLabel.textColor = designSystem.colorRules.textColor(on: background, for: .small)
        
        let headerBackground = designSystem.colorRules.palette.errorRed.normal
        self.headerView.tintColor = designSystem.colorRules.tintedButtonColor(on: headerBackground)
        self.headerView.backgroundColor = headerBackground.color
        self.statusBarView.backgroundColor = headerBackground.color
        self.statusBarView.overlayColor = UIColor.black.withAlphaComponent(0.1)
    }
}
