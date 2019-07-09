//
//  SBAMedicationLoggingStepObject.swift
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

/// The medication logging step is used to log information about each item that is being tracked.
open class SBAMedicationLoggingStepObject : SBATrackedSelectionStepObject, RSDNavigationSkipRule {
    
    #if !os(watchOS)
    open func instantiateViewController(with parent: RSDPathComponent?) -> (UIViewController & RSDStepController)? {
        return SBATrackedMedicationLoggingStepViewController(step: self, parent: parent)
    }
    #endif
    
    /// Override to return a `SBAMedicationLoggingDataSource`.
    open override func instantiateDataSource(with parent: RSDPathComponent?, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBAMedicationLoggingDataSource(step: self, parent: parent)
    }
    
    /// Initializer required for `copy(with:)` implementation.
    public required init(identifier: String, type: RSDStepType?) {
        super.init(identifier: identifier, type: type)
        _commonInit()
    }
    
    override public init(identifier: String, items: [SBATrackedItem], sections: [SBATrackedSection]? = nil, type: RSDStepType? = nil) {
        super.init(identifier: identifier, items: items, sections: sections, type: type)
        _commonInit()
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        _commonInit()
    }
    
    private func _commonInit() {
        if self.actions?[.addMore] == nil {
            var actions = self.actions ?? [:]
            actions[.addMore] = RSDUIActionObject(buttonTitle: Localization.localizedString("MEDICATION_VIEW_LIST"))
            self.actions = actions
        }
    }
    
    /// Override to add the "submit" button for the action.
    override open func action(for actionType: RSDUIActionType, on step: RSDStep) -> RSDUIAction? {
        // If the dictionary includes an action then return that.
        if let action = self.actions?[actionType] { return action }
        // Only special-case for the goForward action.
        guard actionType == .navigation(.goForward) else { return nil }
        
        // If this is the goForward action then special-case to use the "Submit" button
        // if there isn't a button in the dictionary.
        let goForwardAction = RSDUIActionObject(buttonTitle: Localization.localizedString("BUTTON_SUBMIT"))
        var actions = self.actions ?? [:]
        actions[actionType] = goForwardAction
        self.actions = actions
        return goForwardAction
    }
    
    // MARK: RSDNavigationSkipRule
    
    public func shouldSkipStep(with result: RSDTaskResult?, isPeeking: Bool) -> Bool {
        // If this does not have a medication tracking result then it should be skipped.
        guard let medicationResult = self.result as? SBAMedicationTrackingResult
            else {
             return true
        }
        let timeOfDay = Date()
        let medTimings = medicationResult.medications.compactMap { $0.availableMedications(at: timeOfDay, includeLogged: false, includeAnytime: false) }
        return medTimings.count > 0
    }
}

open class SBAMedicationLoggingDataSource : SBATrackedLoggingDataSource {
    
    open override var isForwardEnabled: Bool {
        // Always allow the user to "Submit" their responses.
        // TODO: syoung 08/13/2018 UX redesign to allow users to submit "did *not* take" for logging meds.
        return true
    }
    
    /// Build the logging sections of the table. This is called by `buildSections(step:initialResult)` to get
    /// the logging sections of the table. That method will then append an `.addMore` section if appropriate.
    override open class func buildLoggingSections(step: SBATrackedItemsStep, result: SBATrackedItemsResult) -> (sections: [RSDTableSection], itemGroups: [RSDTableItemGroup]) {
        return buildLoggingSections(step: step, result: result, timeOfDay: Date())
    }
    
    /// Build the logging sections for a given time of day. The time of day is used to determine which
    /// schedules to include in the table. By default, these are grouped by time range for the time of day
    /// (morning, afternoon, evening) with the "missed" medications in a separate section.
    open class func buildLoggingSections(step: SBATrackedItemsStep, result: SBATrackedItemsResult, timeOfDay: Date) -> (sections: [RSDTableSection], itemGroups: [RSDTableItemGroup]) {
        guard let medicationResult = result as? SBAMedicationTrackingResult else {
            assertionFailure("The initial result is not of the expected type.")
            return ([], [])
        }
        
        let timeRange = timeOfDay.timeRange()
        let medTimings = medicationResult.medications.compactMap { $0.availableMedications(at: timeOfDay) }
        let currentItems = medTimings.flatMap { $0.currentItems }
        let missedItems = medTimings.flatMap { $0.missedItems }
        
        var itemGroups = [RSDTableItemGroup]()
        var sections = [RSDTableSection]()
        
        if currentItems.count > 0 {
            let section = RSDTableSection(identifier: "logging", sectionIndex: 0, tableItems: currentItems)
            switch timeRange {
            case .morning, .night:
                section.title = Localization.localizedString("MORNING_MEDICATION_SECTION_TITLE")
            case .afternoon:
                section.title = Localization.localizedString("AFTERNOON_MEDICATION_SECTION_TITLE")
            case .evening:
                section.title = Localization.localizedString("EVENING_MEDICATION_SECTION_TITLE")
            }
            sections.append(section)
            itemGroups.append(RSDTableItemGroup(beginningRowIndex: 0, items: currentItems))
        }
        
        if missedItems.count > 0 {
            let section = RSDTableSection(identifier: "missed", sectionIndex: sections.count, tableItems: missedItems)
            section.title = Localization.localizedString("MISSED_MEDICATION_SECTION_TITLE")
            sections.append(section)
            itemGroups.append(RSDTableItemGroup(beginningRowIndex: 0, items: missedItems))
        }

        return (sections, itemGroups)
    }
    
    /// Remove a medcation from the list.
    func removeMedication(at item: SBATrackedMedicationReviewItem) {
        
        // Update the step result.
        var stepResult = self.trackingResult() as! SBAMedicationTrackingResult
        var meds = stepResult.medications
        meds.remove(at: item.indexPath.item)
        stepResult.medications = meds
        self.taskResult.appendStepHistory(with: stepResult)
        
        self.reloadDataSource(with: stepResult)
    }
    
    /// Save changes to a medication back to the item.
    @discardableResult
    func saveMedication(_ medication: SBAMedicationAnswer)  -> (addedRows: [IndexPath], removedRows: [IndexPath]) {
        guard let result = self.trackingResult() as? SBAMedicationTrackingResult,
            let idx = result.medications.firstIndex(where: { $0.identifier == medication.identifier })
            else {
                assertionFailure("Result is not of expected type or medication is not in the current set.")
                return ([],[])
        }
        
        // Update the step result.
        var stepResult = self.trackingResult() as! SBAMedicationTrackingResult
        var meds = stepResult.medications
        meds.remove(at: idx)
        meds.insert(medication, at: idx)
        stepResult.medications = meds
        self.taskResult.appendStepHistory(with: stepResult)
        
        return self.reloadDataSource(with: stepResult)
    }
    
    /// Get the table item for a given medication.
    func tableItem(for medication: SBAMedicationAnswer) -> SBATrackedMedicationReviewItem? {
        for section in self.sections {
            for tableItem in section.tableItems {
                if let medItem = tableItem as? SBATrackedMedicationReviewItem,
                    medItem.medication.identifier == medication.identifier {
                    return medItem
                }
            }
        }
        return nil
    }
    
    
    /// Update and reload the logged details.
    @discardableResult
    open func reloadLoggingDetails(for loggingItem: SBATrackedMedicationLoggingTableItem, at indexPath: IndexPath) -> (addedRows: [IndexPath], removedRows: [IndexPath]) {
        // Update the result set for this source.
        let stepResult = updateStepResult(for: loggingItem, at: indexPath)
        
        let logging = type(of: self).buildLoggingSections(step: trackedStep, result: stepResult)
        guard
            loggingItem.dosage.isAnytime ?? true,
            let newSection0 = logging.sections.first
            else {
                return ([], [])
        }
        
        let newGroups = logging.itemGroups.filter { $0.sectionIndex == 0 }
        var sections = self.sections
        var groups = self.itemGroups.filter { $0.sectionIndex != 0 }
        sections.remove(at: 0)
        sections.insert(newSection0, at: 0)
        groups.insert(contentsOf: newGroups, at: 0)
        
        let changed = self.reload(withSections: sections, groups: groups)
        
        let added = Set(changed.addedRows).subtracting(changed.removedRows)
        let removed = Set(changed.removedRows).subtracting(changed.addedRows)
        
        // Inform delegate that answers have changed.
        delegate?.tableDataSource(self, didChangeAnswersIn: indexPath.section)
        
        return (added.sorted(), removed.sorted())
    }
}

extension RSDFormUIHint {
    
    /// Display a cell appropriate to logging a timestamp.
    public static let medicationLogging: RSDFormUIHint = "medicationLogging"
}

struct MedicationTiming {
    let medication : SBAMedicationAnswer
    let timeOfDay: Date
    let currentItems : [RSDTableItem]
    let missedItems : [SBATrackedLoggingTableItem]
}

extension SBAMedicationTrackingResult {
    
    func hasMedicationsToLog(at now: Date) -> Bool {
        for medication in self.medications {
            if let dosageItems = medication.dosageItems {
                for dose in dosageItems {
                    if let timestamps = dose.timestamps {
                        if timestamps.contains(where: { (timestamp) -> Bool in
                            guard let time = timestamp.timeOfDay(on: now) else { return false }
                            return time < now
                        }){
                            // Found a timestamp that is less than "now".
                            return true
                        }
                    }
                    else {
                        // Found an "anytime" medication. This can be logged.
                        return true
                    }
                }
            }
        }
        return false
    }
}

extension SBAMedicationAnswer {
    
    /// Filter the medications based on what medications have *not* been marked as taken *or* are within range
    /// for the the time of day (morning/afternoon/evening).
    func availableMedications(at timeOfDay: Date, includeLogged: Bool = true, includeAnytime: Bool = true) -> MedicationTiming? {
        guard let dosageItems = self.dosageItems, dosageItems.count > 0
            else {
                // If this is not for setting reminders, then include a medication review item.
                if includeAnytime {
                    return MedicationTiming(medication: self, timeOfDay: timeOfDay, currentItems: [SBATrackedMedicationReviewItem(medication: self, rowIndex: 0)], missedItems: [])
                } else {
                    return nil
                }
        }

        let timeRange = timeOfDay.timeRange()
        let dayOfWeek = RSDWeekday(date: timeOfDay)
        let upcomingTimeInterval: TimeInterval = 30 * 60  // 30 minutes
        let upcomingTimeOfDay = timeOfDay.addingTimeInterval(upcomingTimeInterval)

        var currentItems = [RSDTableItem]()
        var missedItems = [SBATrackedLoggingTableItem]()
        
        dosageItems.forEach { (dose) in
            guard dose.daysOfWeek?.contains(dayOfWeek) ?? true else { return }
            var timestamps = dose.timestamps ?? []
            
            // Build the current timestamp grouping for this dosage.
            var currentTimestamps = timestamps.remove(where: { (timestamp) -> Bool in
                guard let scheduleTime = timestamp.timeOfDay(on: timeOfDay)
                    else {
                        return includeAnytime && includeLogged
                }
                let isCurrent = (scheduleTime.timeRange() == timeRange) || (scheduleTime >= timeOfDay && scheduleTime <= upcomingTimeOfDay)
                return isCurrent && (includeLogged || (timestamp.loggedDate == nil))
            })
            if includeAnytime && (dose.isAnytime ?? false) {
                currentTimestamps.insert(SBATimestamp(), at: 0)
            }
            
            // Build the missed timestamps.
            let missedTimestamps = timestamps.filter { (timestamp) -> Bool in
                guard timestamp.loggedDate == nil,
                    let scheduleTime = timestamp.timeOfDay(on: timeOfDay)
                    else {
                        return false
                }
                return scheduleTime < timeOfDay
            }
            
            // For each grouping, build the table items.
            currentItems.append(contentsOf: currentTimestamps.enumerated().map {
                SBATrackedMedicationLoggingTableItem(rowIndex: $0.offset,
                                                     medication: self,
                                                     dosage: dose,
                                                     timestamp: $0.element,
                                                     groupCount: currentTimestamps.count)
            })
            
            missedItems.append(contentsOf: missedTimestamps.enumerated().map {
                SBATrackedMedicationLoggingTableItem(rowIndex: $0.offset,
                                                     medication: self,
                                                     dosage: dose,
                                                     timestamp: $0.element,
                                                     groupCount: missedTimestamps.count)
            })
        }

        // Only return available times if there are any in either the window or missed times.
        guard currentItems.count > 0 || missedItems.count > 0 else {
            return nil
        }

        return MedicationTiming(medication: self, timeOfDay: timeOfDay, currentItems: currentItems, missedItems: missedItems)
    }
}

let weekdayFormatter: RSDWeeklyScheduleFormatter = {
    let formatter = RSDWeeklyScheduleFormatter()
    formatter.style = .short
    return formatter
}()

open class SBATrackedMedicationLoggingTableItem: SBATrackedLoggingTableItem {
    
    /// The dosage associated with this table item.
    public var dosage: SBADosage
    
    /// The timestamp associated with this table item.
    public var timestamp: SBATimestamp
    
    /// The number of items in this item's subgrouping (for schedules that are grouped).
    public let groupCount: Int
    
    /// Used to keep track of the state of editing the display time
    public var isEditingDisplayTime = false
    
    open override var loggedDate: Date? {
        get { return timestamp.loggedDate }
        set { timestamp.loggedDate = newValue }
    }
    
    public init(rowIndex: Int, medication: SBAMedicationAnswer, dosage: SBADosage, timestamp: SBATimestamp, groupCount: Int, uiHint: RSDFormUIHint = .medicationLogging) {
        self.groupCount = groupCount
        self.dosage = dosage
        self.timestamp = timestamp
        super.init(rowIndex: rowIndex, itemIdentifier: medication.identifier, timingIdentifier: timestamp.uuid, timeOfDayString: timestamp.timeOfDayString, uiHint: uiHint)
        
        // Set the title and the weekdays.
        self.title = String.localizedStringWithFormat("%@ %@", medication.title ?? medication.identifier, dosage.dosage ?? "")
        if let days = dosage.daysOfWeek {
            self.detail = weekdayFormatter.string(from: days)
        }
    }
}

