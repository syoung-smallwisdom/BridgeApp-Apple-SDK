//
//  MedicationTrackingTests.swift
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

class MedicationTrackingNavigationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMedicationTrackingNavigation_FirstRun_AddDetailsLater() {
        NSLocale.setCurrentTest(Locale(identifier: "en_US"))
        
        let (items, sections) = buildMedicationItems()
        let medTracker = SBAMedicationTrackingStepNavigatorWithReminders(identifier: "Test", items: items, sections: sections)
    
        var taskResult: RSDTaskResult = RSDTaskResultObject(identifier: "medication")
        
        let (introStep, _) = medTracker.step(after: nil, with: &taskResult)
        XCTAssertNotNil(introStep)
        XCTAssertEqual(introStep?.identifier, SBATrackedItemsStepNavigator.StepIdentifiers.introduction.stringValue)
        
        guard let _ = introStep else {
            XCTFail("Failed to create the selection step. Exiting.")
            return
        }
        taskResult.appendStepHistory(with: introStep!.instantiateStepResult())
        
        let (selectStep, _) = medTracker.step(after: introStep, with: &taskResult)
        XCTAssertNotNil(selectStep)
        
        guard let selectionStep = selectStep as? SBATrackedSelectionStepObject else {
            XCTFail("Failed to create the selection step. Exiting.")
            return
        }
        
        XCTAssertNil(medTracker.step(before: selectionStep, with: &taskResult))
        XCTAssertEqual(medTracker.step(with: selectionStep.identifier)?.identifier, selectionStep.identifier)
        XCTAssertFalse(medTracker.hasStep(before: selectionStep, with: taskResult))
        XCTAssertTrue(medTracker.hasStep(after: selectionStep, with: taskResult))

        guard let firstResult = selectionStep.instantiateStepResult() as? SBATrackedItemsResult else {
            XCTFail("Failed to create the expected result. Exiting.")
            return
        }
        var selectionResult = firstResult
        selectionResult.updateSelected(to: ["medA2", "medB4"], with: selectionStep.items)
        taskResult.appendStepHistory(with: selectionResult)
        
        // Next step after selection is review.
        let (rStep, _) = medTracker.step(after: selectionStep, with: &taskResult)
        XCTAssertNotNil(rStep)
        
        guard let reviewStep = rStep as? SBATrackedMedicationReviewStepObject else {
            XCTFail("Failed to create the initial review step. Exiting. step: \(String(describing: rStep))")
            return
        }
        
        let forwardAction = reviewStep.action(for: .navigation(.goForward), on: reviewStep)
        XCTAssertNotNil(forwardAction)
        XCTAssertEqual(forwardAction?.buttonTitle, "Save")
    
        // Check navigation state
        XCTAssertNil(medTracker.step(before: reviewStep, with: &taskResult))
        XCTAssertEqual(medTracker.step(with: reviewStep.identifier)?.identifier, reviewStep.identifier)
        XCTAssertFalse(medTracker.hasStep(before: reviewStep, with: taskResult))
        XCTAssertTrue(medTracker.hasStep(after: reviewStep, with: taskResult))

        guard let secondResult = reviewStep.instantiateStepResult() as? SBAMedicationTrackingResult else {
            XCTFail("Failed to create the expected result. Exiting.")
            return
        }
        XCTAssertEqual(secondResult.selectedAnswers.count, 2)
        XCTAssertFalse(secondResult.hasRequiredValues)

        taskResult.appendStepHistory(with: secondResult)

        // If all details aren't filled in then exit.
        let (finalStep, _) = medTracker.step(after: reviewStep, with: &taskResult)
        XCTAssertNil(finalStep)
    }
    
    func testMedicationTrackingNavigation_FirstRun_SomeDetailsAdded() {
        NSLocale.setCurrentTest(Locale(identifier: "en_US"))
        
        let (items, sections) = buildMedicationItems()
        let medTracker = SBAMedicationTrackingStepNavigatorWithReminders(identifier: "Test", items: items, sections: sections)
        
        var taskResult: RSDTaskResult = RSDTaskResultObject(identifier: "medication")
        
        let (introStep, _) = medTracker.step(after: nil, with: &taskResult)
        XCTAssertNotNil(introStep)
        XCTAssertEqual(introStep?.identifier, SBATrackedItemsStepNavigator.StepIdentifiers.introduction.stringValue)
        
        guard let _ = introStep else {
            XCTFail("Failed to create the selection step. Exiting.")
            return
        }
        taskResult.appendStepHistory(with: introStep!.instantiateStepResult())
        
        let (selectStep, _) = medTracker.step(after: introStep, with: &taskResult)
        XCTAssertNotNil(selectStep)
        
        guard let selectionStep = selectStep as? SBATrackedSelectionStepObject else {
            XCTFail("Failed to create the selection step. Exiting.")
            return
        }
        
        guard let firstResult = selectionStep.instantiateStepResult() as? SBATrackedItemsResult else {
            XCTFail("Failed to create the expected result. Exiting.")
            return
        }
        var selectionResult = firstResult
        selectionResult.updateSelected(to: ["medA2", "medB4"], with: selectionStep.items)
        taskResult.appendStepHistory(with: selectionResult)
        
        // Next step after selection is review.
        let (rStep, _) = medTracker.step(after: selectionStep, with: &taskResult)
        XCTAssertNotNil(rStep)
        
        guard let reviewStep = rStep as? SBATrackedMedicationReviewStepObject else {
            XCTFail("Failed to create the initial review step. Exiting. step: \(String(describing: rStep))")
            return
        }
        
        guard let rResult = reviewStep.instantiateStepResult() as? SBAMedicationTrackingResult else {
            XCTFail("Failed to create the expected result. Exiting.")
            return
        }
        var reviewResult = rResult
        reviewResult.medications = reviewResult.medications.map {
            var med = $0
            if med.identifier == "medA2" {
                med.dosageItems =  [ SBADosage(dosage: "1",
                                               daysOfWeek: [.monday, .wednesday, .friday],
                                               timestamps: [SBATimestamp(timeOfDay: "08:00", loggedDate: nil)],
                                               isAnytime: false) ]
            }
            return med
        }
        taskResult.appendStepHistory(with: reviewResult)
        
        // Then logging
        let (logStep, _) = medTracker.step(after: reviewStep, with: &taskResult)
        XCTAssertNotNil(logStep)
        
        guard let loggingStep = logStep as? SBAMedicationLoggingStepObject else {
            XCTFail("Failed to create the expected step. Exiting. \(String(describing: logStep))")
            return
        }
        
        taskResult.appendStepHistory(with: loggingStep.instantiateStepResult())
        
        // Then reminder
        let (remStep, _) = medTracker.step(after: logStep, with: &taskResult)
        XCTAssertNotNil(remStep)
        
        guard let reminderStep = remStep as? SBATrackedItemRemindersStepObject else {
            XCTFail("Failed to return the reminderStep. Exiting. \(String(describing: remStep))")
            return
        }
        XCTAssertTrue(medTracker.hasStep(after: reminderStep, with: taskResult))
        
        taskResult.appendStepHistory(with: reminderStep.instantiateStepResult())
        
        
        let (exitStep, _) = medTracker.step(after: reminderStep, with: &taskResult)
        XCTAssertNil(exitStep)
    }
    
    func testMedicationTrackingNavigation_FollowupRun() {
        NSLocale.setCurrentTest(Locale(identifier: "en_US"))
        
        let (items, sections) = buildMedicationItems()
        let medTracker = SBAMedicationTrackingStepNavigatorWithReminders(identifier: "Test", items: items, sections: sections)
        
        var initialResult = SBAMedicationTrackingResult(identifier: RSDIdentifier.trackedItemsResult.identifier)
        var medA3 = SBAMedicationAnswer(identifier: "medA3")
        medA3.dosageItems = [ SBADosage(dosage: "1",
                                        daysOfWeek: [.monday, .wednesday, .friday],
                                        timestamps: [SBATimestamp(timeOfDay: "08:00", loggedDate: nil)],
                                        isAnytime: false) ]
        var medC3 = SBAMedicationAnswer(identifier: "medC3")
        medC3.dosageItems = [ SBADosage(dosage: "1",
                                        daysOfWeek: [.sunday, .thursday],
                                        timestamps: [SBATimestamp(timeOfDay: "20:00", loggedDate: nil)],
                                        isAnytime: false) ]
        initialResult.medications = [medA3, medC3]
        // This is how the previous answer of "no reminders please" looks.
        initialResult.reminders = []
        
        let dataScore = try! initialResult.dataScore()
        medTracker.previousClientData = dataScore?.toClientData()
        
        // Check initial state
        let selectionStep = medTracker.getSelectionStep() as? SBATrackedSelectionStepObject
        XCTAssertNotNil(selectionStep)
        XCTAssertEqual(selectionStep?.result?.selectedAnswers.count, 2)
        
        let reviewStep = medTracker.getReviewStep() as? SBATrackedMedicationReviewStepObject
        XCTAssertNotNil(reviewStep)

        var taskResult: RSDTaskResult = RSDTaskResultObject(identifier: "medication")
        let (firstStep, _) = medTracker.step(after: nil, with: &taskResult)
        guard let loggingStep = firstStep as? SBAMedicationLoggingStepObject else {
            XCTFail("Failed to create the expected step. Exiting.")
            return
        }
        XCTAssertNotNil(loggingStep)
        XCTAssertEqual(loggingStep.result?.selectedAnswers.count, 2)
        
        taskResult.appendStepHistory(with: loggingStep.instantiateStepResult())
        
        let (exitStep, _) = medTracker.step(after: firstStep, with: &taskResult)
        XCTAssertNil(exitStep)
    }
    
    func testMedicationTrackingNavigation_FollowupRun_AddDetailsLater() {
        NSLocale.setCurrentTest(Locale(identifier: "en_US"))
        
        let (items, sections) = buildMedicationItems()
        let medTracker = SBAMedicationTrackingStepNavigatorWithReminders(identifier: "Test", items: items, sections: sections)
        
        var initialResult = SBAMedicationTrackingResult(identifier: RSDIdentifier.trackedItemsResult.identifier)
        let medA3 = SBAMedicationAnswer(identifier: "medA3")
        let medC3 = SBAMedicationAnswer(identifier: "medC3")
        initialResult.medications = [medA3, medC3]
        
        let dataScore = try! initialResult.dataScore()
        medTracker.previousClientData = dataScore?.toClientData()
        
        var taskResult: RSDTaskResult = RSDTaskResultObject(identifier: "medication")
        let (firstStep, _) = medTracker.step(after: nil, with: &taskResult)
        guard let reviewStep = firstStep as? SBATrackedMedicationReviewStepObject else {
            XCTFail("Failed to create the expected step. Exiting.")
            return
        }
        
        // Add medication details to all the meds.
        guard let rResult = reviewStep.instantiateStepResult() as? SBAMedicationTrackingResult else {
            XCTFail("Failed to create the expected result. Exiting.")
            return
        }
        var reviewResult = rResult
        reviewResult.medications = reviewResult.medications.map {
            var med = $0
            med.dosageItems =  [ SBADosage(dosage: "1",
                                           daysOfWeek: [.monday, .wednesday, .friday],
                                           timestamps: [SBATimestamp(timeOfDay: "08:00", loggedDate: nil)],
                                           isAnytime: false) ]
            return med
        }
        taskResult.appendStepHistory(with: reviewResult)
        
        // Then logging
        let (logStep, _) = medTracker.step(after: reviewStep, with: &taskResult)
        XCTAssertNotNil(logStep)
        
        guard let loggingStep = logStep as? SBAMedicationLoggingStepObject else {
            XCTFail("Failed to create the expected step. Exiting. \(String(describing: logStep))")
            return
        }
        
        taskResult.appendStepHistory(with: loggingStep.instantiateStepResult())
        
        // Then reminder
        let (remStep, _) = medTracker.step(after: logStep, with: &taskResult)
        XCTAssertNotNil(remStep)
        
        guard let reminderStep = remStep as? SBATrackedItemRemindersStepObject else {
            XCTFail("Failed to return the reminderStep. Exiting. \(String(describing: remStep))")
            return
        }
        XCTAssertTrue(medTracker.hasStep(after: reminderStep, with: taskResult))
        
        taskResult.appendStepHistory(with: reminderStep.instantiateStepResult())
        
        
        let (exitStep, _) = medTracker.step(after: reminderStep, with: &taskResult)
        XCTAssertNil(exitStep)
    }
}

// Helper methods

func remindersResult(reminderStep: SBATrackedItemRemindersStepObject) -> RSDCollectionResultObject {
    var result = RSDCollectionResultObject(identifier: reminderStep.identifier)
    var answerResult = RSDAnswerResultObject(identifier: reminderStep.identifier,
                                             answerType: RSDAnswerResultType(baseType: .integer,
                                                                             sequenceType: .array,
                                                                             formDataType: .collection(.multipleChoice, .integer),
                                                                             dateFormat: nil,
                                                                             unit: nil,
                                                                             sequenceSeparator: nil))
    answerResult.value = [45, 60]
    result.inputResults = [answerResult]
    return result
}

func buildMedicationItems() -> (items: [SBAMedicationItem], sections: [SBATrackedSection]) {
    let items = [   SBAMedicationItem(identifier: "medA1", sectionIdentifier: "section1"),
                    SBAMedicationItem(identifier: "medA2", sectionIdentifier: "section2"),
                    SBAMedicationItem(identifier: "medA3", sectionIdentifier: "section3"),
                    SBAMedicationItem(identifier: "medA4", sectionIdentifier: "section4"),
                    SBAMedicationItem(identifier: "medB1", sectionIdentifier: "section1"),
                    SBAMedicationItem(identifier: "medB2", sectionIdentifier: "section2"),
                    SBAMedicationItem(identifier: "medB3", sectionIdentifier: "section3"),
                    SBAMedicationItem(identifier: "medB4", sectionIdentifier: "section4"),
                    SBAMedicationItem(identifier: "medC1", sectionIdentifier: "section1"),
                    SBAMedicationItem(identifier: "medC2", sectionIdentifier: "section2"),
                    SBAMedicationItem(identifier: "medC3", sectionIdentifier: "section3"),
                    SBAMedicationItem(identifier: "medC4", sectionIdentifier: "section4"),
                    SBAMedicationItem(identifier: "medNoSection1", sectionIdentifier: nil),
                    SBAMedicationItem(identifier: "medFooSection1", sectionIdentifier: "Foo"),
                    SBAMedicationItem(identifier: "medFooSection2", sectionIdentifier: "Foo"),
                    ]
    
    let sections = [    SBATrackedSectionObject(identifier: "section1"),
                        SBATrackedSectionObject(identifier: "section2"),
                        SBATrackedSectionObject(identifier: "section3"),
                        SBATrackedSectionObject(identifier: "section4"),
                        ]
    
    return (items, sections)
}

class SBAMedicationTrackingStepNavigatorWithReminders: SBAMedicationTrackingStepNavigator {
    
    /// return a step for the introduction.
    override class func buildIntroductionStep()-> RSDStep? {
        return RSDUIStepObject(identifier: "introduction")
    }
    
    /// return a step that will be used to set medication reminders.
    override class func buildReminderStep() -> SBATrackedItemRemindersStepObject? {
        guard let inputFields = try? [RSDChoiceInputFieldObject(identifier: "choices", choices: [RSDChoiceObject(value: 15), RSDChoiceObject(value: 30)], dataType: .collection(.multipleChoice, .integer))] else {
            return nil
        }
        let step = SBATrackedItemRemindersStepObject(identifier: "reminder", inputFields: inputFields, type: .medicationReminders)
        step.title = "reminder title"
        step.detail = "reminder detail"
        return step
    }
}
