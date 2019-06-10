//
//  RoundedToggleButton.swift
//  BridgeApp (iOS)
//
//  Created by Shannon Young on 6/17/19.
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
//

import Foundation

class RoundedToggleButton : RSDRoundedButton {
    
    override var isSecondaryButton: Bool {
        get {
            return true
        }
        set {
            // Do nothing
        }
    }
    
    override var isSelected: Bool {
        didSet {
            updateColorsAndFonts()
        }
    }
    
    override func commonInit() {
        super.commonInit()
        
        // Update the color style.
        updateColorsAndFonts()
        
        let image = UIImage(named: "checkmark", in: Bundle(for: RSDRoundedButton.self), compatibleWith: self.traitCollection)
        setImage(image, for: .selected)
    }
    
    override func setDesignSystem(_ designSystem: RSDDesignSystem, with background: RSDColorTile) {
        super.setDesignSystem(designSystem, with: background)
        updateColorsAndFonts()
    }
    
    private func updateColorsAndFonts() {
        let designSystem = self.designSystem ?? RSDDesignSystem()
        let colorTile: RSDColorTile = self.backgroundTile() ?? designSystem.colorRules.backgroundLight

        // Set the color and font values based on whether or not selected
        titleLabel?.font = isSelected ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 16)
        if isSelected {
            self.backgroundColor = designSystem.colorRules.palette.primary.normal.color.withAlphaComponent(0.25)
        }
        else {
            self.backgroundColor = designSystem.colorRules.roundedButton(on: colorTile, with: .secondary, forState: .normal)
        }
    }
}
