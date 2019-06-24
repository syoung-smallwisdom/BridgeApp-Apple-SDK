//
//  SBAWarningViewController.swift
//  BridgeApp (iOS)
//
//  Created by Shannon Young on 6/21/19.
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
//

import Foundation

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
        self.titleLabel.font = designSystem.fontRules.font(for: .heading2, compatibleWith: self.traitCollection)
        self.titleLabel.textColor = designSystem.colorRules.textColor(on: background, for: .heading2)
        self.detailLabel.font = designSystem.fontRules.font(for: .small)
        self.detailLabel.textColor = designSystem.colorRules.textColor(on: background, for: .small)
        
        let headerBackground = designSystem.colorRules.palette.errorRed.normal
        self.headerView.tintColor = designSystem.colorRules.tintedButtonColor(on: headerBackground)
        self.headerView.backgroundColor = headerBackground.color
        self.statusBarView.backgroundColor = headerBackground.color
        self.statusBarView.overlayColor = UIColor.black.withAlphaComponent(0.1)
    }
}
