//
//  SBARemoveTrackedItemStepViewController.swift
//  BridgeApp (iOS)
//
//  Copyright © 2018 Sage Bionetworks. All rights reserved.
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

/// `SBARemoveTrackedItemStepViewController` is a simple instruction view controller that
/// will ask the user if they are sure they want to remove the tracked items.
/// The user can cancel, or if they continue, a `SBARemoveTrackedItemsResultObject` will be
/// appended to the step history
///
/// - seealso: `RSDStepViewController`, `SBARemoveTrackedItemsResultObject`
open class SBARemoveTrackedItemStepViewController: RSDStepViewController {
    
    open class var nibName: String {
        return String(describing: SBARemoveTrackedItemStepViewController.self)
    }
    
    open class var bundle: Bundle {
        return Bundle(for: SBARemoveTrackedItemStepViewController.self)
    }
    
    var removeTrackedItemStep: SBARemoveTrackedItemStepObject? {
        return self.step as? SBARemoveTrackedItemStepObject
    }
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var textLabel: UILabel?
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        if let removeStep = self.removeTrackedItemStep,
            let title = removeStep.title {
            if let underlinedSegment = removeStep.underlinedTitleSegment {
                // TODO: syoung 06/23/2018 Refactor to use HTML for underlining and to use a placeholder such as "%1$@" for range replacement.
                if let underlinedRange = title.range(of: underlinedSegment) {
                    let underlinedIndex = title.distance(from: title.startIndex, to: underlinedRange.lowerBound)
                    let attributedText = NSMutableAttributedString(string: title)
                    attributedText.addAttribute(NSAttributedStringKey.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: NSMakeRange(underlinedIndex, underlinedSegment.count))
                    self.titleLabel?.attributedText = attributedText
                }
            } else {
                self.titleLabel?.attributedText = nil
                self.titleLabel?.text = title
            }
        }
        
        self.textLabel?.text = self.removeTrackedItemStep?.text
    }
}

