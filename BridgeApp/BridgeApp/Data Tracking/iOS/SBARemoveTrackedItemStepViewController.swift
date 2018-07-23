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

/// `SBARemoveTrackedItemStepObject` is a simple instruction step that includes a title
/// and the option to underline a text segment of the title.
open class SBARemoveTrackedItemStepObject: RSDUIStepObject, RSDStepViewControllerVendor {
    
    public func instantiateViewController(with taskPath: RSDTaskPath) -> (UIViewController & RSDStepController)? {
        let vc = SBARemoveTrackedItemStepViewController(nibName: SBARemoveTrackedItemStepViewController.nibName, bundle: SBARemoveTrackedItemStepViewController.bundle)
        vc.step = self
        return vc
    }
    
    private enum CodingKeys: String, CodingKey {
        case bodyText, underlinedTitleSegment, items
    }
    
    /// The phrase or text segment that will be underlined in the title
    public var underlinedTitleSegment: String?
    
    /// The list of items to be removed
    public var items: [RSDIdentifier]
    
    override open func instantiateStepResult() -> RSDResult {
        return SBARemoveTrackedItemsResultObject(identifier: self.identifier, items: self.items)
    }
    
    public init(identifier: String, title: String, underlinedTitleSegment: String, items: [RSDIdentifier]) {
        self.items = items
        super.init(identifier: identifier, type: .removeTrackedItem)
        self.underlinedTitleSegment = underlinedTitleSegment
        self.title = title
    }
    
    /// Initializer required for `copy(with:)` implementation.
    public required init(identifier: String, type: RSDStepType?) {
        self.items = [RSDIdentifier(rawValue: identifier)]
        super.init(identifier: identifier, type: type ?? .removeTrackedItem)
    }
    
    /// Override to set the properties of the subclass.
    override open func copyInto(_ copy: RSDUIStepObject) {
        super.copyInto(copy)
        guard let subclassCopy = copy as? SBARemoveTrackedItemStepObject else {
            assertionFailure("Superclass implementation of the `copy(with:)` protocol should return an instance of this class.")
            return
        }
        subclassCopy.underlinedTitleSegment = self.underlinedTitleSegment
        subclassCopy.items = self.items
    }
    
    /// Initialize from a `Decoder`.
    ///
    /// - example:
    /// ```
    ///    let json = """
    ///        {
    ///            "identifier": "foo",
    ///            "type": "selection",
    ///            "title": "Please select the items you wish to remove",
    ///            "underlinedTitleSegment": "the items",
    ///            "items": ["itemA", "itemB"]
    ///        }
    ///        """.data(using: .utf8)! // our data in native (JSON) format
    /// ```
    ///
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - throws: `DecodingError`
    public required init(from decoder: Decoder) throws {
        // Decode the body text and underlined body text segment.
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.underlinedTitleSegment = try container.decodeIfPresent(String.self, forKey: .underlinedTitleSegment)
        self.items = try container.decode([RSDIdentifier].self, forKey: .items)
        try super.init(from: decoder)
    }
}
