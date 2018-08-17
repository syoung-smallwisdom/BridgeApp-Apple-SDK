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
    
    #if !os(watchOS)
    override open func instantiateViewController(with taskPath: RSDTaskPath) -> (UIViewController & RSDStepController)? {
        return SBATrackedMedicationLoggingStepViewController(step: self)
    }
    #endif
    
    /// Override to return a `SBAMedicationLoggingDataSource`.
    open override func instantiateDataSource(with taskPath: RSDTaskPath, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBAMedicationLoggingDataSource(step: self, taskPath: taskPath)
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
    
    // MARK: RSDNavigationSkipRule
    
    public func shouldSkipStep(with result: RSDTaskResult?, isPeeking: Bool) -> Bool {
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
        let upcomingItems = medTimings.flatMap { $0.upcomingItems }
        
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
        
        if upcomingItems.count > 0 {
            let section = RSDTableSection(identifier: "upcoming", sectionIndex: sections.count, tableItems: upcomingItems)
            section.title = Localization.localizedString("UPCOMING_MEDICATION_SECTION_TITLE")
            sections.append(section)
            itemGroups.append(RSDTableItemGroup(beginningRowIndex: 0, items: upcomingItems))
        }

        return (sections, itemGroups)
    }
}

extension RSDFormUIHint {
    
    /// Display a cell appropriate to logging a timestamp.
    public static let medicationLogging: RSDFormUIHint = "medicationLogging"
}

struct MedicationTiming {
    let medication : SBAMedicationAnswer
    let timeOfDay: Date
    let currentItems : [SBATrackedLoggingTableItem]
    let missedItems : [SBATrackedLoggingTableItem]
    let upcomingItems : [SBATrackedLoggingTableItem]
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
        guard let scheduleItems = self.scheduleItems?.sorted(), scheduleItems.count > 0
            else {
                return nil
        }
        
        let timeRange = timeOfDay.timeRange()
        let dayOfWeek = RSDWeekday(date: timeOfDay)
        let upcomingTimeInterval: TimeInterval = 30 * 60  // 30 minutes
        let upcomingTimeOfDay = timeOfDay.addingTimeInterval(upcomingTimeInterval)
        
        let formatter = RSDWeeklyScheduleFormatter()
        formatter.style = .short
        
        var currentItems = [SBATrackedLoggingTableItem]()
        var missedItems = [SBATrackedLoggingTableItem]()
        var upcomingItems = [SBATrackedLoggingTableItem]()
        
        scheduleItems.forEach { (schedule) in
            // Only include if the day of the week is valid.
            guard schedule.daysOfWeek.contains(dayOfWeek)
                else {
                    return
            }
            
            // Only include if the schedule time is either "anytime" or before now.
            let scheduleTime = schedule.timeOfDay(on: timeOfDay)
            let isCurrent = (scheduleTime == nil || scheduleTime!.timeRange() == timeRange)
            guard isCurrent || scheduleTime! <= upcomingTimeOfDay
                else {
                    return
            }
            
            let timingIdentifier = schedule.timeOfDayString ?? timeRange.rawValue
            let loggedDate = self.timestamps?.first(where: { $0.timingIdentifier == timingIdentifier })?.loggedDate
            let isUpcoming = (scheduleTime != nil && scheduleTime! > timeOfDay)
            
            // Only include the schedule if either it has not been marked *or* the marked timestamp is within
            // the time range.
            guard loggedDate == nil || (includeLogged && (isCurrent || isUpcoming))
                else {
                    return
            }
            
            func appendItem(to items: inout [SBATrackedLoggingTableItem]) {
                let tableItem = SBATrackedMedicationLoggingTableItem(rowIndex: items.count, itemIdentifier: self.identifier, timingIdentifier: timingIdentifier, timeOfDayString: schedule.timeOfDayString, groupCount: scheduleItems.count)
                tableItem.title = self.longTitle
                tableItem.detail = (scheduleTime == nil) ?
                    Localization.localizedString("MEDICATION_ANYTIME") :  formatter.string(from: schedule.daysOfWeek)
                tableItem.loggedDate = loggedDate
                items.append(tableItem)
            }
            
            if isCurrent || isUpcoming {
                appendItem(to: &currentItems)
            }
            else {
                appendItem(to: &missedItems)
            }
        }
        
        // Only return available times if there are any in either the window or missed times.
        guard currentItems.count > 0 || missedItems.count > 0 || upcomingItems.count > 0 else {
            return nil
        }
    
        return MedicationTiming(medication: self, timeOfDay: timeOfDay, currentItems: currentItems, missedItems: missedItems, upcomingItems: upcomingItems)
    }
}

open class SBATrackedMedicationLoggingTableItem: SBATrackedLoggingTableItem {
    
    /// The number of items in this item's subgrouping (for schedules that are grouped).
    public private(set) var groupCount: Int
    
    /// Used to keep track of the state of editing the display time
    public var isEditingDisplayTime = false
    
    public init(rowIndex: Int, itemIdentifier: String, timingIdentifier: String? = nil, timeOfDayString: String? = nil, groupCount: Int, uiHint: RSDFormUIHint = .medicationLogging) {
        self.groupCount = groupCount
        super.init(rowIndex: rowIndex, itemIdentifier: itemIdentifier, timingIdentifier: timingIdentifier, timeOfDayString: timeOfDayString, uiHint: uiHint)
    }
}

