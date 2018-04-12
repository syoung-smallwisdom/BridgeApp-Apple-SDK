//
//  SBAMedicationTrackingStepNavigator.swift
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

open class SBAMedicationTrackingStepNavigator : SBATrackedItemsStepNavigator {
    
    override open class func decodeItems(from decoder: Decoder) throws -> (items: [SBATrackedItem], sections: [SBATrackedSection]?) {
        let container = try decoder.container(keyedBy: ItemsCodingKeys.self)
        let items = try container.decode([SBAMedicationItem].self, forKey: .items)
        let sections = try container.decodeIfPresent([RSDTrackedSectionObject].self, forKey: .sections)
        return (items, sections)
    }
    
    override open class func buildSelectionStep(items: [SBATrackedItem], sections: [SBATrackedSection]?) -> SBATrackedItemsStep {
        let stepId = StepIdentifiers.selection.stringValue
        let step = SBATrackedSelectionStepObject(identifier: stepId, items: items, sections: sections)
        step.title = Localization.localizedString("MEDICATION_SELECTION_TITLE")
        step.detail = Localization.localizedString("MEDICATION_SELECTION_DETAIL")
        return step
    }
    
    override open class func buildReviewStep(items: [SBATrackedItem], sections: [SBATrackedSection]?) -> SBATrackedItemsStep? {
        let stepId = StepIdentifiers.review.stringValue
        let step = SBATrackedItemsReviewStepObject(identifier: stepId, items: items, sections: sections, type: .review)
        
        // Set the default values for the title and subtitle to display depending upon state.
        step.addDetailsTitle = Localization.localizedString("MEDICATION_ADD_DETAILS_TITLE")
        step.addDetailsSubtitle = Localization.localizedString("MEDICATION_ADD_DETAILS_DETAIL")
        step.reviewTitle = Localization.localizedString("MEDICATION_REVIEW_TITLE")
        
        // Add the customization of the add more and go forward buttons.
        let addMoreAction = RSDUIActionObject(buttonTitle: Localization.localizedString("MEDICATION_ADD_MORE_BUTTON"))
        let goForwardAction = RSDUIActionObject(buttonTitle: Localization.localizedString("BUTTON_SUBMIT"))
        step.actions = [.navigation(.goForward) : goForwardAction,
                        .navigation(.addMore) : addMoreAction]
        
        return step
    }
    
    override open class func buildDetailSteps(items: [SBATrackedItem], sections: [SBATrackedSection]?) -> [SBATrackedItemDetailsStep]? {
        return [SBAMedicationDetailsStepObject(identifier: StepIdentifiers.addDetails.stringValue)]
    }
    
    override open class func buildLoggingStep(items: [SBATrackedItem], sections: [SBATrackedSection]?) -> SBATrackedItemsStep? {
        return SBAMedicationLoggingStepObject(identifier: StepIdentifiers.logging.stringValue, items: items, sections: sections)
    }
    
    override open func instantiateReviewResult() -> SBATrackedItemsResult {
        return SBAMedicationTrackingResult(identifier: self.reviewStep!.identifier)
    }
}

/// A medication item includes details for displaying a given medication.
public protocol SBAMedication : SBATrackedItem {
    
    /// Is the medication delivered via continuous injection? If this is the case, then questions about
    /// schedule timing and dosage should be skipped. Assumed `false` if `nil`.
    var isContinuousInjection: Bool? { get }
}

extension SBAMedication {
    
    /// The step identifier for mapping the results of a `RSDMedicationDetailsStepObject`.
    public var addDetailsIdentifier: String? {
        return (self.isContinuousInjection ?? false) ? nil : SBATrackedItemsStepNavigator.StepIdentifiers.addDetails.stringValue
    }
}

/// The medication details form step overrides the base class implementation to add an input field
/// for the dosage.
open class SBAMedicationDetailsStepObject : SBATrackedItemDetailsStepObject {
    
    fileprivate enum FieldIdentifiers : String, CodingKey {
        case dosage
    }
    
    /// Add the dosage input field.
    override open class func buildInputFields() -> [RSDInputField] {
        let inputField = RSDInputFieldObject(identifier: FieldIdentifiers.dosage.stringValue, dataType: .base(.string), uiHint: .textfield, prompt: Localization.localizedString("MEDICATION_DOSAGE_PROMPT"))
        inputField.placeholder = Localization.localizedString("MEDICATION_DOSAGE_PLACEHOLDER")
        return [inputField]
    }
    
    /// Return the dosage field identifier.
    override open class func inputFieldIdentifiers() -> [String] {
        return [FieldIdentifiers.dosage.rawValue]
    }
    
    /// Override and return an `SBAMedicationAnswer`.
    override open func answer(from taskResult: RSDTaskResult) -> SBATrackedItemAnswer? {
        guard let answerMap = self.answerMap(from: taskResult) else { return nil }
        var medication = SBAMedicationAnswer(identifier: self.identifier)
        medication.dosage = answerMap.answers[FieldIdentifiers.dosage.stringValue] as? String
        medication.scheduleItems = Set(answerMap.schedules)
        return medication
    }
    
    // TODO: syoung 02/27/2018 customize the daysOfWeek input field title to include medication
    // and time of the day.
    // "MEDICATION_DAYS_OF_WEEK_TITLE_%1$@_at_%2$@" = "Which days do you take %1$@ at %2$@?";
}

/// The medication logging step is used to log information about each item that is being tracked.
open class SBAMedicationLoggingStepObject : SBATrackedItemsLoggingStepObject {
    
    // TODO: syoung 02/28/2018 Implement model for this step.
}

/// A medication item includes details for displaying a given medication.
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
///                "injection": true
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
/// ```
public struct SBAMedicationItem : Codable, SBAMedication, RSDEmbeddedIconVendor {
    
    private enum CodingKeys : String, CodingKey {
        case identifier
        case sectionIdentifier
        case title
        case shortText
        case detail
        case _isExclusive = "isExclusive"
        case icon
        case isContinuousInjection = "injection"
    }
    
    /// A unique identifier that can be used to track the item.
    public let identifier: String
    
    /// An optional identifier that can be used to group the medication into a section.
    public let sectionIdentifier: String?

    /// Localized text to display as the full descriptor for the medication.
    public let title: String?
    
    /// Localized shortened text to display when used in a sentence.
    public let shortText: String?
    
    /// Detail text to display with additional information about the medication.
    public let detail: String?
    
    /// Whether or not the medication is set up so that *only* this can be selected
    /// for a given section.
    public var isExclusive: Bool {
        return _isExclusive ?? false
    }
    private let _isExclusive: Bool?
    
    /// An optional icon to display for the medication.
    public let icon: RSDImageWrapper?
    
    /// Is the medication delivered via continuous injection? If this is the case, then questions about
    /// schedule timing and dosage should be skipped.
    public let isContinuousInjection: Bool?
    
    public init(identifier: String, sectionIdentifier: String?, title: String? = nil, shortText: String? = nil, detail: String? = nil, icon: RSDImageWrapper? = nil, isExclusive: Bool = false, isContinuousInjection: Bool? = nil) {
        self.identifier = identifier
        self.sectionIdentifier = sectionIdentifier
        self.title = title
        self.shortText = shortText
        self.detail = detail
        self.icon = icon
        self._isExclusive = isExclusive
        self.isContinuousInjection = isContinuousInjection
    }
}

/// A medication answer for a given participant.
///
/// - example:
/// ```
///    let json = """
///            {
///                "identifier": "ibuprofen",
///                "dosage": "10/100 mg",
///                "scheduleItems" : [ { "daysOfWeek": [1,3,5], "timeOfDay" : "8:00" }]
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
///```
public struct SBAMedicationAnswer : Codable, SBATrackedItemAnswer {
    
    private enum CodingKeys : String, CodingKey {
        case identifier, dosage, scheduleItems, isContinuousInjection = "injection"
    }
    
    /// A identifier that maps to the associated `RSDMedicationItem`.
    public let identifier: String
    
    /// A string answer value for the dosage.
    public var dosage: String?
    
    /// The scheduled items associated with this medication result.
    public var scheduleItems: Set<RSDWeeklyScheduleObject>?
    
    /// Is the medication delivered via continuous injection? If this is the case, then questions about
    /// schedule timing and dosage should be skipped.
    public var isContinuousInjection: Bool?
    
    /// Required items for a medication are dosage and schedule unless this is a continuous injection.
    public var hasRequiredValues: Bool {
        return (isContinuousInjection ?? false) || (dosage != nil && scheduleItems != nil)
    }
        
    /// Default initializer.
    /// - parameter identifier:
    public init(identifier: String) {
        self.identifier = identifier
    }
}

/// Extend the medication answer to allow for adding medication using an "Other" style field during
/// selection. All values defined in this section are `nil` or `false`.
extension SBAMedicationAnswer : SBAMedication {
    
    public var sectionIdentifier: String? {
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

/// A medication tracking result which can be used to track the selected medications and details for each
/// medication.
public struct SBAMedicationTrackingResult : Codable, SBATrackedItemsResult {

    private enum CodingKeys : String, CodingKey {
        case identifier, type, startDate, endDate, medications
    }
    
    /// The identifier associated with the task, step, or asynchronous action.
    public let identifier: String
    
    /// A String that indicates the type of the result. This is used to decode the result using a `RSDFactory`.
    public private(set) var type: RSDResultType = .medication
    
    /// The start date timestamp for the result.
    public var startDate: Date = Date()
    
    /// The end date timestamp for the result.
    public var endDate: Date = Date()
    
    /// The list of medications that are currently selected.
    public var medications: [SBAMedicationAnswer] = []
    
    /// A list of the selected answer items.
    public var selectedAnswers: [SBATrackedItemAnswer] {
        return medications
    }
    
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    public func copy(with identifier: String) -> SBAMedicationTrackingResult {
        var copy = SBAMedicationTrackingResult(identifier: identifier)
        copy.medications = self.medications
        return copy
    }
    
    mutating public func updateSelected(to selectedIdentifiers: [String]?, with items: [SBATrackedItem]) {
        guard let newIdentifiers = selectedIdentifiers, newIdentifiers.count > 0 else {
            self.medications = []
            return
        }
        
        func getMedication(with identifier: String) -> SBAMedicationAnswer {
            return medications.first(where: { $0.identifier == identifier }) ?? SBAMedicationAnswer(identifier: identifier)
        }

        // Filter and replace the meds.
        var allIdentifiers = newIdentifiers
        var meds = items.flatMap { (item) -> SBAMedicationAnswer? in
            guard allIdentifiers.contains(item.identifier) else { return nil }
            allIdentifiers.remove(where: { $0 == item.identifier })
            var medication = getMedication(with: item.identifier)
            medication.isContinuousInjection = (item as? SBAMedication)?.isContinuousInjection
            return medication
        }
        
        // For the medications that weren't in the items set, then just add using the identifier.
        meds.append(contentsOf: allIdentifiers.map { getMedication(with: $0) })
        
        // Set the new array
        self.medications = meds
    }
    
    mutating public func updateDetails(to newValue: SBATrackedItemAnswer) {
        guard let idx = medications.index(where: { $0.identifier == newValue.identifier }),
            let newMedication = newValue as? SBAMedicationAnswer else {
                return
        }
        self.medications.remove(at: idx)
        self.medications.insert(newMedication, at: idx)
    }
}
