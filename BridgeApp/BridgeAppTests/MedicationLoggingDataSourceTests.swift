//
//  MedicationLoggingDataSourceTests.swift
//  BridgeAppTests
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

import XCTest
@testable import BridgeApp

class MedicationLoggingDataSourceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        NSLocale.setCurrentTest(Locale(identifier: "en_US"))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBuildSections_Morning_NoMedsTaken_Before1030() {
        
        let timeOfDay = buildDate(weekday: .monday, hour: 10, minute: 0)
        let result = buildMedicationResult(identifier: "review")
        let meds = buildMedicationItems()
        let step = SBAMedicationLoggingStepObject(identifier: "logging", items: meds.items, sections: meds.sections, type: .logging)
        step.result = result
        
        let (sections, groups) = SBAMedicationLoggingDataSource.buildLoggingSections(step: step, result: result, timeOfDay: timeOfDay)
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(sections.count, 1)
        
        guard let firstSection = sections.first else {
            XCTFail("Sections weren't build.")
            return
        }
        
        XCTAssertEqual(firstSection.title, "Morning medications")
        XCTAssertEqual(firstSection.tableItems.count, 2)
        
        guard let medA3Item1 = firstSection.tableItems.first as? SBATrackedLoggingTableItem,
            let medA4Item1 = firstSection.tableItems.last as? SBATrackedLoggingTableItem else {
                XCTFail("Table items weren't build. \(firstSection)")
                return
        }
        
        XCTAssertEqual(medA3Item1.title, "medA3 10 mg")
        XCTAssertEqual(medA3Item1.groupIndex, 0)
        XCTAssertEqual(medA3Item1.rowIndex, 0)
        XCTAssertEqual(medA3Item1.itemIdentifier, "medA3")
        XCTAssertEqual(medA3Item1.timingIdentifier, "08:00")
        XCTAssertEqual(medA3Item1.timeText, "8:00 AM")
        XCTAssertEqual(medA3Item1.detail, "Every day")
        XCTAssertNil(medA3Item1.loggedDate)
        
        XCTAssertEqual(medA4Item1.title, "medA4 40 mg")
        XCTAssertEqual(medA4Item1.groupIndex, 0)
        XCTAssertEqual(medA4Item1.rowIndex, 1)
        XCTAssertEqual(medA4Item1.itemIdentifier, "medA4")
        XCTAssertEqual(medA4Item1.timingIdentifier, "07:30")
        XCTAssertEqual(medA4Item1.timeText, "7:30 AM")
        XCTAssertEqual(medA4Item1.detail, "Mon, Wed, Fri")
        XCTAssertNil(medA4Item1.loggedDate)
    }
    
    func testBuildSections_Morning_NoMedsTaken_After1030() {
        
        let timeOfDay = buildDate(weekday: .monday, hour: 10, minute: 0)
        let result = buildMedicationResult(identifier: "review")
        let meds = buildMedicationItems()
        let step = SBAMedicationLoggingStepObject(identifier: "logging", items: meds.items, sections: meds.sections, type: .logging)
        step.result = result
        
        let (sections, groups) = SBAMedicationLoggingDataSource.buildLoggingSections(step: step, result: result, timeOfDay: timeOfDay)
        
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(sections.count, 1)
        
        guard let firstSection = sections.first else {
            XCTFail("Sections weren't build.")
            return
        }
        
        XCTAssertEqual(firstSection.title, "Morning medications")
        XCTAssertEqual(firstSection.tableItems.count, 3)
        
        guard firstSection.tableItems.count == 3,
            let medA3Item1 = firstSection.tableItems[0] as? SBATrackedLoggingTableItem,
            let medA4Item1 = firstSection.tableItems[1] as? SBATrackedLoggingTableItem,
            let medA4Item2 = firstSection.tableItems[2] as? SBATrackedLoggingTableItem
            else {
                XCTFail("Table items weren't build. \(firstSection)")
                return
        }
        
        XCTAssertEqual(medA3Item1.title, "medA3 10 mg")
        XCTAssertEqual(medA3Item1.groupIndex, 0)
        XCTAssertEqual(medA3Item1.rowIndex, 0)
        XCTAssertEqual(medA3Item1.itemIdentifier, "medA3")
        XCTAssertEqual(medA3Item1.timingIdentifier, "08:00")
        XCTAssertEqual(medA3Item1.timeText, "8:00 AM")
        XCTAssertEqual(medA3Item1.detail, "Every day")
        XCTAssertNil(medA3Item1.loggedDate)
        
        XCTAssertEqual(medA4Item1.title, "medA4 40 mg")
        XCTAssertEqual(medA4Item1.groupIndex, 0)
        XCTAssertEqual(medA4Item1.rowIndex, 1)
        XCTAssertEqual(medA4Item1.itemIdentifier, "medA4")
        XCTAssertEqual(medA4Item1.timingIdentifier, "07:30")
        XCTAssertEqual(medA4Item1.timeText, "7:30 AM")
        XCTAssertEqual(medA4Item1.detail, "Mon, Wed, Fri")
        XCTAssertNil(medA4Item1.loggedDate)
        
        XCTAssertEqual(medA4Item2.title, "medA4 40 mg")
        XCTAssertEqual(medA4Item2.groupIndex, 1)
        XCTAssertEqual(medA4Item2.rowIndex, 2)
        XCTAssertEqual(medA4Item2.itemIdentifier, "medA4")
        XCTAssertEqual(medA4Item2.timingIdentifier, "10:30")
        XCTAssertEqual(medA4Item2.timeText, "10:30 AM")
        XCTAssertEqual(medA4Item2.detail, "Mon, Wed, Fri")
        XCTAssertNil(medA4Item2.loggedDate)
    }
    
    func testBuildSections_Afternoon_NoMedsTaken() {
        
        let timeOfDay = buildDate(weekday: .monday, hour: 12, minute: 40)
        let result = buildMedicationResult(identifier: "review")
        let meds = buildMedicationItems()
        let step = SBAMedicationLoggingStepObject(identifier: "logging", items: meds.items, sections: meds.sections, type: .logging)
        step.result = result
        
        let (sections, groups) = SBAMedicationLoggingDataSource.buildLoggingSections(step: step, result: result, timeOfDay: timeOfDay)
        
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(sections.count, 2)
        
        guard let firstSection = sections.first,
            let missedSection = sections.last else {
            XCTFail("Sections weren't build.")
            return
        }
        
        XCTAssertEqual(firstSection.title, "Afternoon medications")
        XCTAssertEqual(firstSection.tableItems.count, 1)
        
        guard let medA3Item0 = firstSection.tableItems.first as? SBATrackedLoggingTableItem
            else {
                XCTFail("Table items weren't build. \(firstSection)")
                return
        }
        
        XCTAssertEqual(medA3Item0.title, "medA3 10 mg")
        XCTAssertEqual(medA3Item0.groupIndex, 0)
        XCTAssertEqual(medA3Item0.rowIndex, 0)
        XCTAssertEqual(medA3Item0.itemIdentifier, "medA3")
        XCTAssertEqual(medA3Item0.timingIdentifier, "12:00")
        XCTAssertEqual(medA3Item0.timeText, "12:00 PM")
        XCTAssertEqual(medA3Item0.detail, "Every day")
        XCTAssertNil(medA3Item0.loggedDate)
        
        guard missedSection.tableItems.count == 3,
            let medA3Item1 = missedSection.tableItems[0] as? SBATrackedLoggingTableItem,
            let medA4Item1 = missedSection.tableItems[1] as? SBATrackedLoggingTableItem,
            let medA4Item2 = missedSection.tableItems[2] as? SBATrackedLoggingTableItem
            else {
                XCTFail("Table items weren't build. \(missedSection)")
                return
        }
        
        XCTAssertEqual(medA3Item1.title, "medA3 10 mg")
        XCTAssertEqual(medA3Item1.groupIndex, 0)
        XCTAssertEqual(medA3Item1.rowIndex, 0)
        XCTAssertEqual(medA3Item1.itemIdentifier, "medA3")
        XCTAssertEqual(medA3Item1.timingIdentifier, "08:00")
        XCTAssertEqual(medA3Item1.timeText, "8:00 AM")
        XCTAssertEqual(medA3Item1.detail, "Every day")
        XCTAssertNil(medA3Item1.loggedDate)
        
        XCTAssertEqual(medA4Item1.title, "medA4 40 mg")
        XCTAssertEqual(medA4Item1.groupIndex, 0)
        XCTAssertEqual(medA4Item1.rowIndex, 1)
        XCTAssertEqual(medA4Item1.itemIdentifier, "medA4")
        XCTAssertEqual(medA4Item1.timingIdentifier, "07:30")
        XCTAssertEqual(medA4Item1.timeText, "7:30 AM")
        XCTAssertEqual(medA4Item1.detail, "Mon, Wed, Fri")
        XCTAssertNil(medA4Item1.loggedDate)
        
        XCTAssertEqual(medA4Item2.title, "medA4 40 mg")
        XCTAssertEqual(medA4Item2.groupIndex, 1)
        XCTAssertEqual(medA4Item2.rowIndex, 2)
        XCTAssertEqual(medA4Item2.itemIdentifier, "medA4")
        XCTAssertEqual(medA4Item2.timingIdentifier, "10:30")
        XCTAssertEqual(medA4Item2.timeText, "10:30 AM")
        XCTAssertEqual(medA4Item2.detail, "Mon, Wed, Fri")
        XCTAssertNil(medA4Item2.loggedDate)
    }
    
    func testBuildSections_Evening_NoMedsTaken() {
        
        let timeOfDay = buildDate(weekday: .monday, hour: 20, minute: 40)
        let result = buildMedicationResult(identifier: "review")
        let meds = buildMedicationItems()
        let step = SBAMedicationLoggingStepObject(identifier: "logging", items: meds.items, sections: meds.sections, type: .logging)
        step.result = result
        
        let (sections, groups) = SBAMedicationLoggingDataSource.buildLoggingSections(step: step, result: result, timeOfDay: timeOfDay)
        
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(sections.count, 2)
        
        guard let firstSection = sections.first,
            let missedSection = sections.last else {
                XCTFail("Sections weren't build.")
                return
        }
        
        XCTAssertEqual(firstSection.title, "Evening medications")
        XCTAssertEqual(firstSection.tableItems.count, 1)
        
        guard let medA3Item0 = firstSection.tableItems.first as? SBATrackedLoggingTableItem
            else {
                XCTFail("Table items weren't build. \(firstSection)")
                return
        }
        
        XCTAssertEqual(medA3Item0.title, "medA3 10 mg")
        XCTAssertEqual(medA3Item0.groupIndex, 0)
        XCTAssertEqual(medA3Item0.rowIndex, 0)
        XCTAssertEqual(medA3Item0.itemIdentifier, "medA3")
        XCTAssertEqual(medA3Item0.timingIdentifier, "20:00")
        XCTAssertEqual(medA3Item0.timeText, "8:00 PM")
        XCTAssertEqual(medA3Item0.detail, "Every day")
        XCTAssertNil(medA3Item0.loggedDate)
        
        guard missedSection.tableItems.count == 4,
            let medA3Item1 = missedSection.tableItems[0] as? SBATrackedLoggingTableItem,
            let medA3Item2 = missedSection.tableItems[1] as? SBATrackedLoggingTableItem,
            let medA4Item1 = missedSection.tableItems[2] as? SBATrackedLoggingTableItem,
            let medA4Item2 = missedSection.tableItems[3] as? SBATrackedLoggingTableItem
            else {
                XCTFail("Table items weren't build. \(missedSection)")
                return
        }
        
        XCTAssertEqual(medA3Item1.title, "medA3 10 mg")
        XCTAssertEqual(medA3Item1.groupIndex, 0)
        XCTAssertEqual(medA3Item1.rowIndex, 0)
        XCTAssertEqual(medA3Item1.itemIdentifier, "medA3")
        XCTAssertEqual(medA3Item1.timingIdentifier, "08:00")
        XCTAssertEqual(medA3Item1.timeText, "8:00 AM")
        XCTAssertEqual(medA3Item1.detail, "Every day")
        XCTAssertNil(medA3Item1.loggedDate)
        
        XCTAssertEqual(medA3Item2.title, "medA3 10 mg")
        XCTAssertEqual(medA3Item2.groupIndex, 1)
        XCTAssertEqual(medA3Item2.rowIndex, 1)
        XCTAssertEqual(medA3Item2.itemIdentifier, "medA3")
        XCTAssertEqual(medA3Item2.timingIdentifier, "12:00")
        XCTAssertEqual(medA3Item2.timeText, "12:00 PM")
        XCTAssertEqual(medA3Item2.detail, "Every day")
        XCTAssertNil(medA3Item2.loggedDate)
        
        XCTAssertEqual(medA4Item1.title, "medA4 40 mg")
        XCTAssertEqual(medA4Item1.groupIndex, 0)
        XCTAssertEqual(medA4Item1.rowIndex, 2)
        XCTAssertEqual(medA4Item1.itemIdentifier, "medA4")
        XCTAssertEqual(medA4Item1.timingIdentifier, "07:30")
        XCTAssertEqual(medA4Item1.timeText, "7:30 AM")
        XCTAssertEqual(medA4Item1.detail, "Mon, Wed, Fri")
        XCTAssertNil(medA4Item1.loggedDate)
        
        XCTAssertEqual(medA4Item2.title, "medA4 40 mg")
        XCTAssertEqual(medA4Item2.groupIndex, 1)
        XCTAssertEqual(medA4Item2.rowIndex, 3)
        XCTAssertEqual(medA4Item2.itemIdentifier, "medA4")
        XCTAssertEqual(medA4Item2.timingIdentifier, "10:30")
        XCTAssertEqual(medA4Item2.timeText, "10:30 AM")
        XCTAssertEqual(medA4Item2.detail, "Mon, Wed, Fri")
        XCTAssertNil(medA4Item2.loggedDate)
    }
    
    // Helper methods
    
    func buildDate(weekday: RSDWeekday, hour: Int, minute: Int) -> Date {
        
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar(identifier: .gregorian)
        dateComponents.year = 2018
        dateComponents.month = 2
        dateComponents.weekdayOrdinal = 1
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.weekday = weekday.rawValue
        
        return dateComponents.date!
    }
    
    func buildMedicationResult(identifier: String) -> SBAMedicationTrackingResult {
        
        var medA3 = SBAMedicationAnswer(identifier: "medA3")
        medA3.dosage = "10 mg"
        medA3.scheduleItems = [RSDWeeklyScheduleObject(timeOfDayString: "08:00", daysOfWeek: RSDWeekday.all),
                               RSDWeeklyScheduleObject(timeOfDayString: "12:00", daysOfWeek: RSDWeekday.all),
                               RSDWeeklyScheduleObject(timeOfDayString: "20:00", daysOfWeek: RSDWeekday.all)]
        
        var medA4 = SBAMedicationAnswer(identifier: "medA4")
        medA4.dosage = "40 mg"
        medA4.scheduleItems = [RSDWeeklyScheduleObject(timeOfDayString: "07:30", daysOfWeek: [.monday, .wednesday, .friday]),
                               RSDWeeklyScheduleObject(timeOfDayString: "10:30", daysOfWeek: [.monday, .wednesday, .friday])]
        
        var medC3 = SBAMedicationAnswer(identifier: "medC3")
        medC3.dosage = "2 ml"
        medC3.scheduleItems = [RSDWeeklyScheduleObject(timeOfDayString: "08:00", daysOfWeek: [.sunday, .thursday]),
                               RSDWeeklyScheduleObject(timeOfDayString: "20:00", daysOfWeek: [.sunday, .thursday])]
        
        var result = SBAMedicationTrackingResult(identifier: identifier)
        result.medications = [medA3, medC3]
        
        return result
    }
}
