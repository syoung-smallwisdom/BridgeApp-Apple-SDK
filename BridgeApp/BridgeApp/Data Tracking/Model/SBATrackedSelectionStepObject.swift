//
//  SBATrackedSelectionStepObject.swift
//  BridgeApp
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

import Foundation

/// `SBATrackedSelectionStepObject` is intended for use in selecting items from a long, sectioned list.
/// In general, this would be the first step in setting up tracked data such as symptoms of a disease
/// or triggers associated with a medical condition.
///
/// - seealso: `SBATrackedItemsStepNavigator`
open class SBATrackedSelectionStepObject : RSDUIStepObject, SBATrackedItemsStep {
    
    private enum CodingKeys: String, CodingKey {
        case items, sections
    }
    
    /// The shared result for review, details, and selection.
    public var result: SBATrackedItemsResult?
    
    /// The list of the items to track.
    public var items: [SBATrackedItem]
    
    /// The section items for mapping each medication.
    public var sections: [SBATrackedSection]?
    
    /// Initializer required for `copy(with:)` implementation.
    public required init(identifier: String, type: RSDStepType?) {
        self.items = []
        super.init(identifier: identifier, type: type ?? .selection)
    }
    
    /// Override to set the properties of the subclass.
    override open func copyInto(_ copy: RSDUIStepObject) {
        super.copyInto(copy)
        guard let subclassCopy = copy as? SBATrackedSelectionStepObject else {
            assertionFailure("Superclass implementation of the `copy(with:)` protocol should return an instance of this class.")
            return
        }
        subclassCopy.items = self.items
        subclassCopy.sections = self.sections
    }
    
    /// Default initializer.
    /// - parameters:
    ///     - identifier: A short string that uniquely identifies the step.
    ///     - inputFields: The input fields used to create this step.
    public init(identifier: String, items: [SBATrackedItem], sections: [SBATrackedSection]? = nil, type: RSDStepType? = nil) {
        self.items = items
        self.sections = sections
        super.init(identifier: identifier, type: type ?? .selection)
    }

    /// Initialize from a `Decoder`.
    ///
    /// - example:
    /// ```
    ///    let json = """
    ///        {
    ///            "identifier": "foo",
    ///            "type": "selection",
    ///            "title": "Please select the items you wish to track",
    ///            "detail": "Select all that apply",
    ///            "actions": { "goForward": { "buttonTitle" : "Go, Dogs! Go!" },
    ///                         "cancel": { "iconName" : "closeX" },
    ///                        },
    ///            "shouldHideActions": ["goBackward", "skip"],
    ///            "items" : [ {"identifier" : "itemA1", "sectionIdentifier" : "a"},
    ///                        {"identifier" : "itemA2", "sectionIdentifier" : "a"},
    ///                        {"identifier" : "itemA3", "sectionIdentifier" : "a"},
    ///                        {"identifier" : "itemB1", "sectionIdentifier" : "b"},
    ///                        {"identifier" : "itemB2", "sectionIdentifier" : "b"},
    ///                        {"identifier" : "itemB3", "sectionIdentifier" : "b"}],
    ///            "sections" : [ {"identifier" : "a"}, {"identifier" : "b"}]
    ///        }
    ///        """.data(using: .utf8)! // our data in native (JSON) format
    /// ```
    ///
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - throws: `DecodingError`
    public required init(from decoder: Decoder) throws {
        // Decode the items and sections
        self.items = try type(of: self).decodeItems(from: decoder) ?? []
        self.sections = try type(of: self).decodeSections(from: decoder)
        try super.init(from: decoder)
    }
    
    /// Overridable class method for decoding tracking items.
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - returns: The decoded items.
    /// - throws: `DecodingError`
    open class func decodeItems(from decoder: Decoder) throws -> [SBATrackedItem]? {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let items = try container.decodeIfPresent([RSDTrackedItemObject].self, forKey: .items)
        return items
    }
    
    /// Overridable class method for decoding tracking sections.
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - returns: The decoded sections.
    /// - throws: `DecodingError`
    open class func decodeSections(from decoder: Decoder) throws -> [SBATrackedSection]? {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sections = try container.decodeIfPresent([RSDTrackedSectionObject].self, forKey: .sections)
        return sections
    }
    
    /// Instantiate a step result that is appropriate for this step. The default for this class is a
    /// `RSDTrackedItemsResultObject`. If the `result` property is set, then this will instantiate a
    /// copy of the result with this step's identifier.
    ///
    /// - returns: A result for this step.
    open override func instantiateStepResult() -> RSDResult {
        guard let result = self.result else {
            return RSDTrackedItemsResultObject(identifier: self.identifier)
        }
        return result.copy(with: self.identifier)
    }
    
    /// Validate the step to check for any configuration that should throw an error. This class will
    /// check that the input fields have unique identifiers and will call the `validate()` method on each
    /// input field.
    ///
    /// - throws: An error if validation fails.
    open override func validate() throws {
        try super.validate()
        
        // Check if the identifiers are unique
        let itemsIds = items.map({ $0.identifier })
        let uniqueIds = Set(itemsIds)
        if itemsIds.count != uniqueIds.count {
            throw RSDValidationError.notUniqueIdentifiers("Item identifiers: \(itemsIds.joined(separator: ","))")
        }
        
        // Check if the identifiers are unique
        if let sectionIds = sections?.map({ $0.identifier }) {
            let uniqueIds = Set(sectionIds)
            if sectionIds.count != uniqueIds.count {
                throw RSDValidationError.notUniqueIdentifiers("Item identifiers: \(sectionIds.joined(separator: ","))")
            }
        }
    }
    
    /// Override the default selector to return a tracked selection data source.
    open override func instantiateDataSource(with taskPath: RSDTaskPath, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        guard supportedHints.contains(.list) else { return nil }
        return SBATrackedSelectionDataSource(step: self, taskPath: taskPath)
    }
}

/// A section header for tracked data.
///
/// - example:
/// ```
///    let json = """
///            {
///                "identifier": "foo",
///                "text": "Text",
///                "detail" : "Detail"
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
/// ```
public struct RSDTrackedSectionObject : Codable, SBATrackedSection {
    
    private enum CodingKeys : String, CodingKey {
        case identifier, text, detail
    }
    
    /// A unique identifier for this section.
    public let identifier: String
    
    /// Localized text for the section.
    public let text: String?
    
    /// Localized detail for the section.
    public let detail: String?
    
    public init( identifier: String, text: String? = nil, detail: String? = nil) {
        self.identifier = identifier
        self.text = text
        self.detail = detail
    }
}

/// A generic instance of an item to include in a tracked selection step.
///
/// - example:
/// ```
///    let json = """
///            {
///                "identifier": "advil",
///                "sectionIdentifier": "pain",
///                "title": "Advil",
///                "shortText": "Ibu",
///                "detail": "(Ibuprofen)",
///                "isExclusive": true,
///                "icon": "pill",
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
/// ```
public struct RSDTrackedItemObject : Codable, SBATrackedItem, RSDEmbeddedIconVendor {
    
    private enum CodingKeys : String, CodingKey {
        case identifier
        case sectionIdentifier
        case addDetailsIdentifier
        case title
        case shortText
        case detail
        case _isExclusive = "isExclusive"
        case icon
    }
    
    /// A unique identifier that can be used to track the item.
    public let identifier : String
    
    /// An optional identifier that can be used to group the tracked items by section.
    public let sectionIdentifier : String?
    
    /// An optional identifier that can be used to map a tracked item to a mutable step that can be used
    /// to input additional details about the tracked item.
    public let addDetailsIdentifier: String?
    
    /// Localized text to display as the full descriptor.
    public let title : String?
    
    /// Additional detail text.
    public let detail: String?
    
    /// Localized shortened text to display when used in a sentence.
    public let shortText : String?
    
    /// Optional icon to display for the selection.
    public let icon: RSDImageWrapper?
    
    /// Whether or not the tracked item is set up so that *only* this item can be selected
    /// for a given section.
    public var isExclusive: Bool {
        return _isExclusive ?? false
    }
    private let _isExclusive: Bool?
    
    public init(identifier: String, sectionIdentifier: String?, title: String? = nil, shortText: String? = nil, detail: String? = nil, icon: RSDImageWrapper? = nil, isExclusive: Bool = false, addDetailsIdentifier: String? = nil) {
        self.identifier = identifier
        self.sectionIdentifier = sectionIdentifier
        self.title = title
        self.shortText = shortText
        self.detail = detail
        self.icon = icon
        self._isExclusive = isExclusive
        self.addDetailsIdentifier = addDetailsIdentifier
    }
}


/// Simple tracking object for the case where only the identifier is being tracked.
public struct RSDTrackedItemsResultObject : SBATrackedItemsResult, Codable {

    private enum CodingKeys : String, CodingKey {
        case identifier, type, startDate, endDate, items
    }
    
    /// The identifier associated with the task, step, or asynchronous action.
    public let identifier: String
    
    /// A String that indicates the type of the result. This is used to decode the result using a `RSDFactory`.
    public private(set) var type: RSDResultType = "trackedItemsReview"
    
    /// The start date timestamp for the result.
    public var startDate: Date = Date()
    
    /// The end date timestamp for the result.
    public var endDate: Date = Date()
    
    /// The list of items that are currently selected.
    public var items: [RSDIdentifier] = []
    
    /// Return the list of identifiers.
    public var selectedAnswers: [SBATrackedItemAnswer] {
        return self.items
    }
    
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    public func copy(with identifier: String) -> RSDTrackedItemsResultObject {
        var copy = RSDTrackedItemsResultObject(identifier: identifier)
        copy.items = self.items
        return copy
    }
    
    /// Convert the identifiers to `RSDIdentifier` objects sorted by the order of the identifiers in the items list.
    mutating public func updateSelected(to selectedIdentifiers: [String]?, with items: [SBATrackedItem]) {
        self.items = sort(selectedIdentifiers, with: items).map { RSDIdentifier(rawValue: $0) }
    }
    
    mutating public func updateDetails(to newValue: SBATrackedItemAnswer) {
        // Do nothing
    }
}

extension SBATrackedItemsResult {
    
    /// Sort the given list of identifiers in the order given by the items.
    public func sort(_ identifiers: [String]?, with items: [SBATrackedItem]) -> [String] {
        guard let identifiers = identifiers else {
            return []
        }
        func positionOf(_ identifier: String) -> Int {
            return items.index(where: { identifier == $0.identifier }) ?? items.count
        }
        return identifiers.sorted { positionOf($0) < positionOf($1) }
    }
}

extension RSDIdentifier : SBATrackedItemAnswer {
    
    public var identifier: String {
        return self.stringValue
    }
    
    public var hasRequiredValues: Bool {
        return true
    }
}

extension RSDIdentifier : SBATrackedItem {
    
    public var sectionIdentifier: String? {
        return nil
    }
    
    public var addDetailsIdentifier: String? {
        return nil
    }
    
    public var title: String? {
        return nil
    }
    
    public var detail: String? {
        return nil
    }
    
    public var shortText: String? {
        return nil
    }
    
    public var isExclusive: Bool {
        return false
    }
    
    public var imageVendor: RSDImageVendor? {
        return nil
    }
}
