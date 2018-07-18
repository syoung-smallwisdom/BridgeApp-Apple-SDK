//
//  SBATrackedItem.swift
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

/// `SBATrackedItem` is a protocol for defining an item that can be mapped using its `identifier`
/// to a list of selected items.
public protocol SBATrackedItem : RSDChoice, RSDComparable {
    
    /// A unique identifier that can be used to track the item.
    var identifier: String { get }
    
    /// An optional identifier that can be used to group the tracked items by section.
    var sectionIdentifier: String? { get }
    
    /// An optional identifier that can be used to map a tracked item to a mutable step that can be used
    /// to input additional details about the tracked item.
    var addDetailsIdentifier: String? { get }
    
    /// Localized text to display as the full descriptor.
    var title: String? { get }
    
    /// Additional detail text.
    var detail: String? { get }
    
    /// Localized shortened text to display when used in a sentence.
    var shortText: String? { get }
}

extension SBATrackedItem {
    
    /// Always include a text string. Default = `self.title ?? self.identifier`.
    public var text: String? {
        return self.title ?? self.identifier
    }
    
    /// A tracked item uses its `identifier` as the answer value.
    public var answerValue : Codable? {
        return self.identifier
    }
    
    /// A tracked item uses its `identifier` as the matching answer for a comparable.
    public var matchingAnswer : Any? {
        return self.identifier
    }
}

/// `SBATrackedSection` is used to define a subgrouping of `SBATrackedItem` objects. Because the study
/// designer may change these grouping as the study progresses, this is a weak link to the `SBATrackedItem`
/// as it is only used for display.
public protocol SBATrackedSection {
    
    /// A unique identifier for this section.
    var identifier: String { get }
    
    /// Localized text for the section.
    var text: String? { get }
    
    /// Localized detail for the section.
    var detail: String? { get }
}

/// A tracked item answer includes the answer details (including selection) that are tracked for
/// this participant.
public protocol SBATrackedItemAnswer : Codable, RSDChoice {
    
    /// Identifier that maps to the associated `SBATrackedItem`.
    var identifier: String { get }
    
    /// Does the tracked answer have the required answers?
    var hasRequiredValues: Bool { get }
}

/// The tracked items result includes a list of all the answers for this tracked selection.
public protocol SBATrackedItemsResult : RSDResult, RSDCopyWithIdentifier {
    
    /// A list of the currently selected items including any tracked details.
    var selectedAnswers: [SBATrackedItemAnswer] { get }
    
    /// Update the result to the selected identifiers using the items mapping.
    mutating func updateSelected(to selectedIdentifiers: [String]?, with items: [SBATrackedItem])
    
    /// Update the result from the given task result and items.
    mutating func updateDetails(from result: RSDResult)
}

extension SBATrackedItemsResult {
    
    /// Map to the selected answers.
    public var selectedIdentifiers: [String] {
        return self.selectedAnswers.map { $0.identifier }
    }
    
    /// Do all the tracked items have their required values set?
    public var hasRequiredValues: Bool {
        return self.selectedAnswers.reduce(true, { $0 && $1.hasRequiredValues })
    }
    
    /// The answer type of the answer result. This includes coding information required to encode and
    /// decode the value. The value is expected to conform to one of the coding types supported by the answer type.
    public var answerType: RSDAnswerResultType {
        return RSDAnswerResultType(baseType: .codable, sequenceType: .array)
    }
    
    /// The answer for the result.
    public var value: Any? {
        return selectedAnswers
    }
}

public protocol SBATrackedItemsCollectionResult : SBATrackedItemsResult, SBAClientDataResult {
    
    /// Update the result from the given client data.
    mutating func updateSelected(from clientData: SBBJSONValue, with items: [SBATrackedItem]) throws
}

extension SBATrackedItemsCollectionResult {
    
    /// Build the archiveable or uploadable data for this result.
    public func buildArchiveData(at stepPath: String?) throws -> (manifest: RSDFileManifest, data: Data)? {
        guard let stepId = SBATrackedItemsStepNavigator.StepIdentifiers(rawValue: self.identifier),
            (stepId == .logging || stepId == .review) else {
                return nil
        }
        let data = try self.rsd_jsonEncodedData()
        let manifest = RSDFileManifest(filename: self.identifier,
                                       timestamp: self.endDate,
                                       contentType: "application/json",
                                       identifier: self.identifier,
                                       stepPath: stepPath)
        return (manifest, data)
    }
}

/// `SBATrackedItemsStep` is customized for selecting a long list of items that are sorted into sections
/// for display to the user.
///
/// - note: These steps are used as templates that are retained by the `SBATrackedItemsStepNavigator`
/// and thus need to be mutable classes.
public protocol SBATrackedItemsStep : class, RSDStep {
    
    /// The result with the list of selected items.
    var result: SBATrackedItemsResult? { get set }
    
    /// The list of the items to track.
    var items: [SBATrackedItem] { get set }
    
    /// The section items for mapping each medication.
    var sections: [SBATrackedSection]? { get set }
}

extension SBATrackedItemsStep {
    
    /// Do all the tracked items currently under review have their required values set?
    public var hasRequiredValues: Bool {
        return self.result?.hasRequiredValues ?? false
    }
}

/// The tracked item detail step is used to add additional details to the tracked item.
public protocol SBATrackedItemDetailsStep : RSDStep {
    
    /// Create a copy of the step using this step as a template for the given tracked item.
    func copy(from trackedItem: SBATrackedItem, with previousAnswer: SBATrackedItemAnswer?) -> RSDStep?
}
