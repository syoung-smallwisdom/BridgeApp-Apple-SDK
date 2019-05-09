//
//  TrackingNavigatorTests.swift
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


class TrackingNavigatorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSimpleNavigation_FirstRun() {
        NSLocale.setCurrentTest(Locale(identifier: "en_US"))
        
        guard let taskPath = buildSimpleItemTracker(),
            let tracker = taskPath.task?.stepNavigator as? SBATrackedItemsStepNavigator else {
            XCTFail("Failed to create navigator. Exiting.")
            return
        }

        let (firstStep, _) = tracker.step(after: nil, with: &taskPath.taskResult)
        XCTAssertNotNil(firstStep)
        XCTAssertEqual(firstStep?.identifier, "selection")

        guard let selectionStep = firstStep as? SBATrackedSelectionStepObject else {
            XCTFail("Failed to create the selection step. Exiting.")
            return
        }

        XCTAssertFalse(tracker.hasStep(before: selectionStep, with: taskPath.taskResult))
        XCTAssertTrue(tracker.hasStep(after: selectionStep, with: taskPath.taskResult))
        XCTAssertNil(tracker.step(before: selectionStep, with: &taskPath.taskResult))

        guard let firstResult = selectionStep.instantiateStepResult() as? SBATrackedItemsResult else {
            XCTFail("Failed to create the expected result. Exiting.")
            return
        }
        var selectionResult = firstResult
        selectionResult.updateSelected(to: ["itemA2", "itemB1", "itemC3"], with: selectionStep.items)
        taskPath.taskResult.appendStepHistory(with: selectionResult)

        let (secondStep, _) = tracker.step(after: selectionStep, with: &taskPath.taskResult)
        XCTAssertNotNil(secondStep)
        XCTAssertEqual(secondStep?.identifier, "logging")

        guard let loggingStep = secondStep as? SBATrackedItemsLoggingStepObject else {
            XCTFail("First step not of expected type. For a follow-up run should start with logging step.")
            return
        }

        XCTAssertEqual(loggingStep.result?.selectedAnswers.count, 3)
        XCTAssertFalse(tracker.hasStep(after: loggingStep, with: taskPath.taskResult))
        XCTAssertFalse(tracker.hasStep(before: loggingStep, with: taskPath.taskResult))
        XCTAssertNil(tracker.step(before: loggingStep, with: &taskPath.taskResult))
        XCTAssertNil(tracker.step(after: loggingStep, with: &taskPath.taskResult).step)
        
        // The logging should use the "Submit" title for forward navigation.
        if let action = loggingStep.action(for: .navigation(.goForward), on: loggingStep) {
            XCTAssertEqual(action.buttonTitle, "Submit")
        } else {
            XCTFail("Step action does not include `.goForward`")
        }
    }
    
    func testSimpleNavigation_FollowupRun() {
        NSLocale.setCurrentTest(Locale(identifier: "en_US"))
        
        guard let taskPath = buildSimpleItemTracker(),
            let tracker = taskPath.task?.stepNavigator as? SBATrackedItemsStepNavigator else {
                XCTFail("Failed to create navigator. Exiting.")
                return
        }
        
        var initialResult = SBATrackedLoggingCollectionResultObject(identifier: RSDIdentifier.trackedItemsResult.identifier)
        initialResult.updateSelected(to: ["itemA2", "itemB1", "itemC3"], with: tracker.items)
        let dataScore = try! initialResult.dataScore()
        tracker.previousClientData = dataScore?.toClientData()
        
        let (firstStep, _) = tracker.step(after: nil, with: &taskPath.taskResult)
        XCTAssertNotNil(firstStep)
        XCTAssertEqual(firstStep?.identifier, "logging")
        
        guard let loggingStep = firstStep as? SBATrackedItemsLoggingStepObject else {
            XCTFail("First step not of expected type. For a follow-up run should start with logging step.")
            return
        }
        
        XCTAssertEqual(loggingStep.result?.selectedAnswers.count, 3)
        XCTAssertFalse(tracker.hasStep(after: loggingStep, with: taskPath.taskResult))
        XCTAssertFalse(tracker.hasStep(before: loggingStep, with: taskPath.taskResult))
        XCTAssertNil(tracker.step(before: loggingStep, with: &taskPath.taskResult))
        XCTAssertNil(tracker.step(after: loggingStep, with: &taskPath.taskResult).step)
        
        // The logging should use the "Submit" title for forward navigation.
        if let action = loggingStep.action(for: .navigation(.goForward), on: loggingStep) {
            XCTAssertEqual(action.buttonTitle, "Submit")
        } else {
            XCTFail("Step action does not include `.goForward`")
        }
    }
    
    // Helper method
    
    func buildSimpleItemTracker() -> RSDTaskViewModel? {
        
        let json = """
            {
                "identifier": "logging",
                "type" : "tracking",
                "items": [
                            { "identifier": "itemA1", "sectionIdentifier" : "a" },
                            { "identifier": "itemA2", "sectionIdentifier" : "a" },
                            { "identifier": "itemA3", "sectionIdentifier" : "a" },
                            { "identifier": "itemB1", "sectionIdentifier" : "b" },
                            { "identifier": "itemB2", "sectionIdentifier" : "b" },
                            { "identifier": "itemC1", "sectionIdentifier" : "c" },
                            { "identifier": "itemC2", "sectionIdentifier" : "c" },
                            { "identifier": "itemC3", "sectionIdentifier" : "c" }
                        ],
                "selection": { "title": "What items would you like to track?",
                                "detail": "Select all that apply"},
                "logging": { "title": "Your logged items",
                             "actions": { "addMore": { "type": "default", "buttonTitle" : "Edit Logged Items" }}
                            }
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let task = try decoder.decode(RSDTaskObject.self, from: json)
            guard task.stepNavigator is SBATrackedItemsStepNavigator else {
                XCTFail("Failed to decode the step navigator. Exiting.")
                return nil
            }
            return RSDTaskViewModel(task: task)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return nil
        }
    }
}
