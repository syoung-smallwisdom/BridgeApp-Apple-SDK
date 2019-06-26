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
    
    var medicationResult: SBAMedicationTrackingResult? {
        return self._inMemoryResult as? SBAMedicationTrackingResult
    }

    override open class func decodeItems(from decoder: Decoder) throws -> (items: [SBATrackedItem], sections: [SBATrackedSection]?) {
        let container = try decoder.container(keyedBy: ItemsCodingKeys.self)
        let items = try container.decode([SBAMedicationItem].self, forKey: .items)
        let sections = try container.decodeIfPresent([SBATrackedSectionObject].self, forKey: .sections)
        return (items, sections)
    }
    
    override open class func buildSelectionStep(items: [SBATrackedItem], sections: [SBATrackedSection]?) -> SBATrackedItemsStep {
        let stepId = StepIdentifiers.selection.stringValue
        let step = SBATrackedSelectionStepObject(identifier: stepId, items: items, sections: sections)
        step.title = Localization.localizedString("MEDICATION_SELECTION_TITLE")
        step.detail = Localization.localizedString("MEDICATION_SELECTION_DETAIL")
        step.includePreviouslySelected = false
        return step
    }
    
    override open class func buildReviewStep(items: [SBATrackedItem], sections: [SBATrackedSection]?) -> SBATrackedItemsStep? {
        return SBATrackedMedicationReviewStepObject(identifier: StepIdentifiers.review.stringValue, items: items, sections: sections, type: .review)
    }
    
    override open class func buildLoggingStep(items: [SBATrackedItem], sections: [SBATrackedSection]?) -> SBATrackedItemsStep {
        return SBAMedicationLoggingStepObject(identifier: StepIdentifiers.logging.stringValue, items: items, sections: sections)
    }
    
    override open func instantiateLoggingResult() -> SBATrackedItemsCollectionResult {
        return SBAMedicationTrackingResult(identifier: self.reviewStep!.identifier)
    }
    
    /// Override to check that at least one item has been filled in.
    override open func doesRequireReview() -> Bool {
        return medicationResult?.medications.first(where: { $0.hasRequiredValues }) == nil
    }
    
    /// Override to set reminder if the current reminders are nil.
    override open func doesRequireSetReminder() -> Bool {
        return medicationResult?.reminders == nil
    }
}

extension RSDIdentifier {
    
    public static let medicationReminders: RSDIdentifier = "medicationReminders"
}

/// A medication item includes details for displaying a given medication.
public protocol SBAMedication : SBATrackedItem {
    
    /// Is the medication delivered via continuous injection? If this is the case, then questions about
    /// schedule timing and dosage should be skipped. Assumed `false` if `nil`.
    var isContinuousInjection: Bool? { get }
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
public struct SBAMedicationAnswer : Codable, SBATrackedItemAnswer {
    private enum CodingKeys : String, CodingKey {
        case identifier, dosageItems, isContinuousInjection = "injection"
    }
    
    /// An identifier that maps to the associated `RSDMedicationItem`.
    public let identifier: String
    
    /// The scheduled items associated with this medication result.
    public var dosageItems: [SBADosage]?
    
    /// Is the medication delivered via continuous injection? If this is the case, then questions about
    /// schedule timing and dosage should be skipped.
    public var isContinuousInjection: Bool?
    
    /// Required items for a medication are dosage and schedule unless this is a continuous injection.
    public var hasRequiredValues: Bool {
        // exit early if this is a continuous injection
        if (isContinuousInjection ?? false) { return true }
        guard let items = self.dosageItems, items.count > 0 else { return false }
        return items.reduce(true, { $0 && $1.hasRequiredValues })
    }
        
    /// Default initializer.
    /// - parameter identifier:
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    /// When the participant taps the "save" button, finalize editing of this dosage by stripping out the
    /// information that should not be stored.
    mutating public func finalizeEditing() {
        guard let dosageItems = self.dosageItems else { return }
        var items = [String : SBADosage]()
        dosageItems.forEach {
            guard let dosage = $0.dosage, !dosage.isEmpty else { return }
            var newItem = $0
            if newItem.isAnytime == nil {
                // If the `isAnytime` property is not set, then figure out what it should be.
                let hasTimeOfDay = (newItem.timestamps?.first(where: { $0.timeOfDay != nil }) != nil)
                newItem.isAnytime = !hasTimeOfDay
            }
            if newItem.isAnytime! {
                // If this is an `isAnytime` dosage, then nil out the days of the week and time of day.
                newItem.daysOfWeek = nil
                newItem.timestamps = newItem.timestamps?.compactMap { SBATimestamp (timeOfDay: nil, loggedDate: $0.loggedDate) }
            }
            if let existingItem = items[dosage], existingItem.daysOfWeek == $0.daysOfWeek, let existingTimestamps = existingItem.timestamps {
                // If there is already an existing item, add this one to that one.
                var timestamps = newItem.timestamps ?? []
                timestamps.append(contentsOf: existingTimestamps)
                newItem.timestamps = timestamps
            }
            // Filter and sort the timestamps.
            newItem.timestamps = newItem.timestamps?
                .filter { $0.timeOfDay != nil || $0.loggedDate != nil }
                .sorted(by: { (lhs, rhs) -> Bool in
                    if let lhsTime = lhs.timeOfDay, let rhsTime = rhs.timeOfDay {
                        return lhsTime < rhsTime
                    }
                    else if let lhsTime = lhs.loggedDate, let rhsTime = rhs.loggedDate {
                        return lhsTime < rhsTime
                    }
                    else {
                        return false
                    }
                })
            items[dosage] = newItem
        }
        self.dosageItems = items.map { $0.value }
    }
}

/// A dosage includes the dosage label and timestamps/timeOfDay for a given medication.
public struct SBADosage : Codable {    
    private enum CodingKeys : String, CodingKey {
        case dosage, daysOfWeek, timestamps
    }
    
    /// A string answer value for the dosage.
    public var dosage: String?
    
    /// The days of the week to include in the schedule. By default, this will be set to daily.
    public var daysOfWeek: Set<RSDWeekday>?
    
    /// Logged date and time of day mapping (if any).
    public var timestamps: [SBATimestamp]?
    
    /// Is this an "anytime" dosage?
    public var isAnytime: Bool?
    
    public init(dosage: String? = nil, daysOfWeek: Set<RSDWeekday>? = nil, timestamps: [SBATimestamp]? = nil, isAnytime: Bool? = nil) {
        self.dosage = dosage
        self.daysOfWeek = daysOfWeek
        self.timestamps = timestamps
        self.isAnytime = isAnytime
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dosage = try container.decode(String.self, forKey: .dosage)
        let daysOfWeek = try container.decodeIfPresent(Set<RSDWeekday>.self, forKey: .daysOfWeek)
        let timestamps = try container.decodeIfPresent([SBATimestamp].self, forKey: .timestamps)
        let hasTimeOfDay = (daysOfWeek != nil) && (timestamps?.first(where: { $0.timeOfDay != nil }) != nil)
        self.daysOfWeek = hasTimeOfDay ? daysOfWeek : nil
        self.timestamps = timestamps
        self.isAnytime = !hasTimeOfDay
    }
    
    /// Required items for a medication are dosage and schedule unless this is a continuous injection.
    public var hasRequiredValues: Bool {
        guard let dosage = self.dosage, !dosage.isEmpty,
            let isAnytime = self.isAnytime
            else {
                return false
        }
        return isAnytime ? true : ((daysOfWeek?.count ?? 0) > 0 && self.selectedTimes.count > 0)
    }
    
    /// Map each dosage to a set of schedule items.
    public var scheduleItems: Set<RSDWeeklyScheduleObject>? {
        guard let timestamps = self.timestamps,
            let daysOfWeek = self.daysOfWeek
            else {
                return nil
        }
        return Set(timestamps.compactMap {
            guard let timeOfDay = $0.timeOfDay else { return nil }
            return RSDWeeklyScheduleObject(timeOfDayString: timeOfDay, daysOfWeek: daysOfWeek)
        })
    }
    
    /// Mapping of the selected times associated with this dosage. The `String` should be the timeOfDay
    /// string in the format used to track time of day.
    public var selectedTimes: Set<String> {
        return Set(self.timestamps?.compactMap { $0.timeOfDay } ?? [])
    }
    
    /// Localize and join the time of day strings.
    public func timesText() -> String? {
        guard let timestamps = self.timestamps?.filter({ $0.timeOfDay != nil }), timestamps.count > 0 else {
            return nil
        }
        let times = timestamps.sorted(by: { $0.timeOfDay! < $1.timeOfDay! }).compactMap { $0.localizedTime() }
        let delimiter = Localization.localizedString("LIST_FORMAT_DELIMITER")
        return times.joined(separator: delimiter)
    }
    
    /// Localize and join the days of the week string.
    public func daysText() -> String? {
        guard let days = self.daysOfWeek, days.count > 0 else { return nil }
        if days == RSDWeekday.all {
            return Localization.localizedString("SCHEDULE_EVERY_DAY")
        }
        else if days.count == 1, let text = days.first!.text {
            return text
        }
        else {
            let delimiter = Localization.localizedString("LIST_FORMAT_DELIMITER")
            return days.sorted().compactMap({ $0.shortText }).joined(separator: delimiter)
        }
    }
    
    /// When the participant taps the "save" button, finalize editing of this dosage by stripping out the
    /// information that should not be stored.
    mutating public func finalizeEditing() {
        if self.isAnytime ?? true {
            self.isAnytime = true
            self.daysOfWeek = nil
            let timestamps = self.timestamps?.compactMap {
                $0.loggedDate != nil ? SBATimestamp(timeOfDay: nil, loggedDate: $0.loggedDate) : nil
            }
            self.timestamps = (timestamps?.count ?? 0 > 0) ? timestamps : nil
        }
        else {
            self.daysOfWeek = self.daysOfWeek ?? RSDWeekday.all
            self.timestamps = self.timestamps?.filter { $0.timeOfDay != nil }
        }
    }
    
    /// Prepare this model object for logging by adding/removing the timestamps that are not applicable
    /// for the given date.
    mutating public func prepareForLogging(on date: Date = Date()) {
        // Filter/nil out the timestamps where the loggedDate is *not* on the same day as the display date.
        self.timestamps = self.timestamps?.compactMap {
            guard let loggedDate = $0.loggedDate, Calendar.iso8601.isDate(loggedDate, inSameDayAs: date)
                else {
                    return $0.timeOfDay != nil ? SBATimestamp(timeOfDay: $0.timeOfDay, loggedDate: nil) : nil
            }
            return $0
        }
    }
}


/// V1 coding for a Medication Answer.
public struct SBAMedicationAnswerV1 : Codable {
    private enum CodingKeys : String, CodingKey {
        case identifier, dosage, scheduleItems, isContinuousInjection = "injection", timestamps
    }
    public let identifier: String
    public let dosage: String?
    public let scheduleItems: Set<RSDWeeklyScheduleObject>?
    public let isContinuousInjection: Bool?
    public let timestamps: [SBATimestamp]?
    
    func convert() -> SBAMedicationAnswer {
        var dosageItems = [SBADosage]()
        scheduleItems?.forEach { (schedule) in
            let timeOfDay = schedule.timeOfDayString
            let isAnytime = (self.dosage == nil) ? nil : (timeOfDay == nil)
            let timestamps: [SBATimestamp]? = {
                guard let anytime = isAnytime else { return nil }
                if anytime {
                    return self.timestamps?.filter { $0.timeOfDay == nil }
                }
                else if let timestamp = self.timestamps?.first(where: { $0.timeOfDay == timeOfDay }) {
                    return [timestamp]
                }
                else {
                    return nil
                }
            }()
            let daysOfWeek = (timeOfDay != nil) ? schedule.daysOfWeek : nil
            dosageItems.append(SBADosage(dosage: self.dosage, daysOfWeek: daysOfWeek, timestamps: timestamps, isAnytime: isAnytime))
        }
        var med = SBAMedicationAnswer(identifier: self.identifier)
        med.dosageItems = dosageItems
        med.finalizeEditing()
        return med
    }
}

/// Extend the medication answer to allow for adding medication using an "Other" style field during
/// selection. All values defined in this section are `nil` or `false`.
extension SBAMedicationAnswer : SBAMedication {
    
    public var sectionIdentifier: String? {
        return nil
    }
    
    public var title: String? {
        return self.identifier
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
public struct SBAMedicationTrackingResult : Codable, SBATrackedItemsCollectionResult, RSDNavigationResult {

    private enum CodingKeys : String, CodingKey {
        case identifier, type, startDate, endDate, medications = "items", reminders, revision
    }
    
    /// The identifier associated with the task, step, or asynchronous action.
    public let identifier: String
    
    /// The revision number is used to set the coding to V1 medication answers or V2 medication answers.
    public private(set) var revision: Int?
    
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
    
    /// A list of minutes before the medication scheduled times that a user should be reminded about each medication
    public var reminders: [Int]?
    
    /// The step identifier of the next step to skip to after this one.
    public var skipToIdentifier: String? = nil
    
    public init(identifier: String) {
        self.identifier = identifier
        self.revision = 2
    }
    
    public func copy(with identifier: String) -> SBAMedicationTrackingResult {
        var copy = SBAMedicationTrackingResult(identifier: identifier)
        copy.startDate = self.startDate
        copy.endDate = self.endDate
        copy.type = self.type
        copy.medications = self.medications
        copy.reminders = self.reminders
        copy.revision = self.revision
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
        var meds = items.compactMap { (item) -> SBAMedicationAnswer? in
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
    
    mutating public func updateDetails(from result: RSDResult) {
        if let loggingResult = result as? SBATrackedLoggingCollectionResultObject {
            updateLogging(from: loggingResult)
        }
        else if result.identifier == RSDIdentifier.medicationReminders.stringValue {
            updateReminders(from: result)
        }
    }
    
    // TODO: FIXME!! syoung 06/24/2019
//    mutating func updateMedicationDetails(from detailsResult: SBAMedicationDetailsResultObject) {
//        guard let idx = medications.firstIndex(where: { $0.identifier == detailsResult.identifier }) else {
//            return
//        }
//
//
////        // Build a new answer from the detail.
////        var medication = SBAMedicationAnswer(identifier: detailsResult.identifier)
////
////        medication.dosage = detailsResult.dosage
////        if let schedulesUnwrapped = detailsResult.schedules {
////            medication.scheduleItems = Set(schedulesUnwrapped)
////        }
////
////        // Copy the timestamps from the previous answer.
////        medication.timestamps = self.medications[idx].timestamps
////        self.medications.remove(at: idx)
////        self.medications.insert(medication, at: idx)
//    }
    
    mutating func updateLogging(from loggingResult: SBATrackedLoggingCollectionResultObject) {
        loggingResult.loggingItems.forEach {
            let loggingResult = $0
            guard let itemIdentifier = loggingResult.itemIdentifier,
                let timingIdentifier = loggingResult.timingIdentifier
                else {
                    return
            }
            self.updateLogging(itemIdentifier: itemIdentifier, timingIdentifier: timingIdentifier, loggedDate: loggingResult.loggedDate)
        }
    }
    
    mutating func updateLogging(itemIdentifier: String, timingIdentifier: String, loggedDate: Date?) {
        guard let idx = medications.firstIndex(where: { $0.identifier == itemIdentifier })
            else {
                return
        }
        // TODO: FIXME!!! syoung 06/24/2019
        
//        // If this is a timestamp logging then add/remove timestamp.
//        var medication = self.medications[idx]
//        var timestamps: [SBATimestamp] = medication.timestamps ?? []
//        timestamps.remove(where: { $0.timingIdentifier == timingIdentifier })
//        if let loggedDate = loggedDate {
//
//            let newTimestamp = SBATimestamp(timingIdentifier: timingIdentifier, loggedDate: loggedDate)
//            timestamps.append(newTimestamp)
//        }
//        medication.timestamps = timestamps
//        self.medications.remove(at: idx)
//        self.medications.insert(medication, at: idx)
    }
    
    mutating func updateReminders(from result: RSDResult) {
        let aResult = (result as? RSDCollectionResult)?.inputResults.first ?? result
        self.reminders = (aResult as? RSDAnswerResult)?.value as? [Int]
    }
    
    public func dataScore() throws -> RSDJSONSerializable? {
        guard identifier == RSDIdentifier.trackedItemsResult.stringValue
            else {
                return nil
        }
        let dictionary = try self.rsd_jsonEncodedDictionary()
        return
            [CodingKeys.revision.stringValue : dictionary[CodingKeys.revision.stringValue],
             CodingKeys.medications.stringValue : dictionary[CodingKeys.medications.stringValue],
             CodingKeys.reminders.stringValue : dictionary[CodingKeys.reminders.stringValue]].jsonObject()
    }
    
    mutating public func updateSelected(from clientData: SBBJSONValue, with items: [SBATrackedItem]) throws {
        var clientDataMap = clientData as? [String : Any]
        if clientDataMap == nil {
            // Also support a collection of tracking results, but grab the last one.
            clientDataMap = (clientData as? [[String : Any]])?.last
        }
        if let clientDataMapUnwrapped = clientDataMap {
            self.reminders = clientDataMapUnwrapped[CodingKeys.reminders.stringValue] as? [Int]
            if let medJson = clientDataMapUnwrapped[CodingKeys.medications.stringValue] as? SBBJSONValue {
                let decoder = SBAFactory.shared.createJSONDecoder()
                if let revision = clientDataMapUnwrapped[CodingKeys.revision.stringValue] as? Int {
                    self.revision = revision
                    let meds = try decoder.decode([SBAMedicationAnswer].self, from: medJson)
                    self.medications = meds
                }
                else {
                    let meds = try decoder.decode([SBAMedicationAnswerV1].self, from: medJson)
                    self.medications = meds.map { $0.convert() }
                }
            }
        }
    }
}

/// A timestamp object is a light-weight Codable that can be used to record the timestamp for a logging event.
/// This object includes a `timingIdentifier` that maps to either an `SBATimeRange` or an
/// `RSDSchedule.timeOfDayString`.
public struct SBATimestamp : Codable, RSDScheduleTime {
    let uuid = UUID().uuidString
    
    private enum CodingKeys : String, CodingKey {
        case timeOfDay, loggedDate, quantity
    }
    
    public init?(timeOfDay: String? = nil, loggedDate: Date? = nil) {
        guard timeOfDay != nil || loggedDate != nil else {
            return nil
        }
        self.timeOfDay = timeOfDay
        self.loggedDate = loggedDate
        self.quantity = 1
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timeOfDay = try container.decodeIfPresent(String.self, forKey: .timeOfDay)
        var validTimeOfDay = false
        if timeOfDay != nil {
            let regEx = try! NSRegularExpression(pattern: "(?:[01]\\d|2[0123]):(?:[012345]\\d)")
            let matches = regEx.numberOfMatches(in: timeOfDay!, options: [], range: NSRange(timeOfDay!.startIndex..., in: timeOfDay!))
            validTimeOfDay = (matches == 1)
        }
        let loggedDate = try container.decodeIfPresent(Date.self, forKey: .loggedDate)
        if loggedDate == nil && !validTimeOfDay {
            let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: "loggedDate and timeOfDay cannot both be nil")
            throw DecodingError.keyNotFound(CodingKeys.loggedDate, context)
        }
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        self.loggedDate = loggedDate
        self.timeOfDay = validTimeOfDay ? timeOfDay : nil
    }
    
    /// When the logged event is scheduled to occur.
    public var timeOfDay: String?
    
    /// The time/date for when the event was logged as *actually* occuring.
    public var loggedDate: Date?
    
    /// The number of times the event was logged at a given time.
    public var quantity: Int
    
    /// The time of day from the `RSDSchedule` that can be used to identify this schedule.
    public var timeOfDayString : String? {
        return timeOfDay
    }
    
    /// The time range for this timestamp.
    public func timeRange(on date: Date) -> SBATimeRange {
        return self.timeOfDay(on: date)?.timeRange() ?? loggedDate?.timeRange() ?? date.timeRange()
    }
}

