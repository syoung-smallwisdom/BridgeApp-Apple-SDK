//
//  RoundedToggleButton.swift
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

@IBDesignable
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
