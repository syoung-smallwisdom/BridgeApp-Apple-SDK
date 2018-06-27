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
open class SBAMedicationLoggingStepObject : SBATrackedItemsLoggingStepObject, RSDNavigationSkipRule {
    
    /// Override to return a `SBAMedicationLoggingDataSource`.
    open override func instantiateDataSource(with taskPath: RSDTaskPath, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBAMedicationLoggingDataSource(step: self, taskPath: taskPath)
    }
    
    // MARK: RSDNavigationSkipRule
    
    public func shouldSkipStep(with result: RSDTaskResult?, conditionalRule: RSDConditionalRule?, isPeeking: Bool) -> Bool {
        // If this does not have a medication tracking result then it should be skipped.
        guard let medicationResult = self.result as? SBAMedicationTrackingResult
            else {
             return true
        }
        let timeOfDay = Date()
        let medTimings = medicationResult.medications.compactMap { $0.availableMedications(at: timeOfDay, includeLogged: false) }
        return medTimings.count > 0
    }
}

open class SBAMedicationLoggingDataSource : SBATrackedLoggingDataSource {
    
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
}

struct MedicationTiming {
    let medication : SBAMedicationAnswer
    let timeOfDay: Date
    let currentItems : [SBATrackedLoggingTableItem]
    let missedItems : [SBATrackedLoggingTableItem]
}

extension SBAMedicationAnswer {
    
    /// The long title is the title and the dosage.
    public var longTitle : String? {
        guard let title = self.text, let dosage = self.dosage
            else {
                return nil
        }
        return String.localizedStringWithFormat("%@ %@", title, dosage)
    }
    
    /// Filter the medications based on what medications have *not* been marked as taken *or* are within range
    /// for the the time of day (morning/afternoon/evening).
    func availableMedications(at timeOfDay: Date, includeLogged: Bool = true) -> MedicationTiming? {
        guard let scheduleItems = self.scheduleItems?.sorted(by: { (result1, result2) -> Bool in
            return result1.identifier > result2.identifier
        }),
            scheduleItems.count > 0
            else {
                return nil
        }
        
        let timeRange = timeOfDay.timeRange()
        let dayOfWeek = RSDWeekday(date: timeOfDay)
        
        let formatter = RSDWeeklyScheduleFormatter()
        formatter.style = .short
        
        var currentItems = [SBATrackedLoggingTableItem]()
        var missedItems = [SBATrackedLoggingTableItem]()
        
        scheduleItems.forEach { (schedule) in
            // Only include if the day of the week is valid.
            guard schedule.weeklyScheduleObject.daysOfWeek.contains(dayOfWeek)
                else {
                    return
            }
            
            // Only include if the schedule time is either "anytime" or before now.
            let scheduleTime = schedule.weeklyScheduleObject.timeOfDay(on: timeOfDay)
            guard scheduleTime == nil || scheduleTime! <= timeOfDay
                else {
                    return
            }
            
            let timingIdentifier = schedule.weeklyScheduleObject.timeOfDayString
            let loggedDate = self.timestamps?.first(where: { $0.timingIdentifier == timingIdentifier })?.loggedDate
            let isCurrent = (scheduleTime == nil || scheduleTime!.timeRange() == timeRange)
            
            // Only include the schedule if either it has not been marked *or* the marked timestamp is within
            // the time range.
            guard loggedDate == nil || (includeLogged && isCurrent)
                else {
                    return
            }
            
            let rowIndex = isCurrent ? currentItems.count : missedItems.count
            let tableItem = SBATrackedLoggingTableItem(rowIndex: rowIndex, itemIdentifier: self.identifier, timingIdentifier: timingIdentifier, timeOfDayString: schedule.weeklyScheduleObject.timeOfDayString)
            tableItem.title = self.longTitle
            tableItem.detail = (scheduleTime == nil) ?
                Localization.localizedString("MEDICATION_ANYTIME") :  formatter.string(from: schedule.weeklyScheduleObject.daysOfWeek)
            tableItem.loggedDate = loggedDate
            
            if isCurrent {
                currentItems.append(tableItem)
            }
            else {
                missedItems.append(tableItem)
            }
        }
        
        // Only return available times if there are any in either the window or missed times.
        guard currentItems.count > 0 || missedItems.count > 0 else {
            return nil
        }
    
        return MedicationTiming(medication: self, timeOfDay: timeOfDay, currentItems: currentItems, missedItems: missedItems)
    }
}

