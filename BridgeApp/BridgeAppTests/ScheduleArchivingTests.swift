//
//  ScheduleArchivingTests.swift
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

class ScheduleArchivingTests: SBAScheduleManagerTests {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testScheduledActivity_CompoundTask_InsertedTask() {
        let taskPath = runCompoundTask()
        guard let subtaskPath = taskPath.childPaths[insertTaskIdentifier] else {
            XCTFail("Failed to build the expected child paths.")
            return
        }
        
        // Create an associated schedule for the inserted task and the top level task
        let schedules = self.createSchedules(identifiers: [mainTaskIdentifier, insertTaskIdentifier],
                                             clientData: nil)
        guard let expectedSchedule = schedules[insertTaskIdentifier] else {
            XCTFail("Failed to build the expected schedules.")
            return
        }
        
        // The subtask will be run without a linked schedule identifier.
        let schedule = self.scheduleManager.scheduledActivity(for: subtaskPath.result, scheduleIdentifier: nil)
        
        XCTAssertNotNil(schedule)
        XCTAssertEqual(schedule, expectedSchedule)
    }
    
    func testDataArchiver_CompoundTask_WithSchedules() {
        let taskPath = runCompoundTask()
        
        // Create an associated schedule for the inserted task and the top level task
        let schedules = self.createSchedules(identifiers: [mainTaskIdentifier, insertTaskIdentifier],
                                             clientData: nil)

        let topResult = taskPath.result
        guard let archive = self.scheduleManager.dataArchiver(for: topResult,
                                                        scheduleIdentifier: schedules[mainTaskIdentifier]?.guid,
                                                        currentArchive: nil) as? SBAScheduledActivityArchive
            else {
                XCTFail("Failed to instantiate a top-level archive.")
                return
        }
        XCTAssertEqual(archive.schemaInfo.schemaIdentifier, mainTaskSchemaIdentifier)
        XCTAssertEqual(archive.schedule, schedules[mainTaskIdentifier])
        
        if let sectionPath = taskPath.childPaths["step2"] {
            let childArchive = self.scheduleManager.dataArchiver(for: sectionPath.result,
                                                                 scheduleIdentifier: nil,
                                                                 currentArchive: archive)
            XCTAssertTrue(archive === childArchive, "Child archive did not return non-unique parent archive.")
        }
        else {
            XCTFail("Fails assumption. Could not retrieve child task path.")
        }
        
        if let subtaskPath = taskPath.childPaths[insertTaskIdentifier] {
            let childArchive = self.scheduleManager.dataArchiver(for: subtaskPath.result,
                                                                 scheduleIdentifier: nil,
                                                                 currentArchive: archive)
            XCTAssertFalse(archive === childArchive, "Child archive for a subtask did not return new archive.")
            if let insertArchive = childArchive as? SBAScheduledActivityArchive {
                XCTAssertEqual(insertArchive.schemaInfo.schemaIdentifier, insertTaskSchemaIdentifier)
                XCTAssertEqual(insertArchive.schedule, schedules[insertTaskIdentifier])
            }
            else {
                XCTFail("Child archive not of expected type.")
            }
        }
        else {
            XCTFail("Fails assumption. Could not retrieve child task path.")
        }
    }
    
    func testDataArchiver_CompoundTask_NoSchedules() {
        let taskPath = runCompoundTask()
        
        let topResult = taskPath.result
        guard let archive = self.scheduleManager.dataArchiver(for: topResult,
                                                              scheduleIdentifier: nil,
                                                              currentArchive: nil) as? SBAScheduledActivityArchive
            else {
                XCTFail("Failed to instantiate a top-level archive.")
                return
        }
        XCTAssertEqual(archive.schemaInfo.schemaIdentifier, mainTaskSchemaIdentifier)
        
        if let sectionPath = taskPath.childPaths["step2"] {
            let childArchive = self.scheduleManager.dataArchiver(for: sectionPath.result,
                                                                 scheduleIdentifier: nil,
                                                                 currentArchive: archive)
            XCTAssertTrue(archive === childArchive, "Child archive did not return non-unique parent archive.")
        }
        else {
            XCTFail("Fails assumption. Could not retrieve child task path.")
        }
        
        if let subtaskPath = taskPath.childPaths[insertTaskIdentifier] {
            let childArchive = self.scheduleManager.dataArchiver(for: subtaskPath.result,
                                                                 scheduleIdentifier: nil,
                                                                 currentArchive: archive)
            XCTAssertFalse(archive === childArchive, "Child archive for a subtask did not return new archive.")
            if let insertArchive = childArchive as? SBAScheduledActivityArchive {
                XCTAssertEqual(insertArchive.schemaInfo.schemaIdentifier, insertTaskSchemaIdentifier)
            }
            else {
                XCTFail("Child archive not of expected type.")
            }
        }
        else {
            XCTFail("Fails assumption. Could not retrieve child task path.")
        }
    }
    
    func testGetClientData_CompoundTask() {
        shouldReplacePrevious = false

        let taskPath = runCompoundTask()
        guard let subtaskPath = taskPath.childPaths[insertTaskIdentifier] else {
            XCTFail("Fails assumption. Could not retrieve child task path.")
            return
        }
        
        // Create an associated schedule for the inserted task and the top level task
        let schedules = self.createSchedules(identifiers: [mainTaskIdentifier, insertTaskIdentifier],
                                             clientData: nil)
        guard let topSchedule = schedules[mainTaskIdentifier],
            let subtaskSchedule = schedules[insertTaskIdentifier] else {
                XCTFail("Fails assumption. Did not create expected schedules.")
                return
        }
        
        let topClientData = self.scheduleManager.buildClientData(from: taskPath.result, for: topSchedule)?.clientData
        XCTAssertNotNil(topClientData)
        if let dictionary = topClientData as? NSDictionary {
            let expectedDictionary : NSDictionary = [
                "introduction" : "introduction",
                "step1": "step1",
                "step2": [ "stepX" : "stepX",
                           "stepY" : "stepY"],
                "step3": [ "stepX" : "stepX",
                           "stepY" : "stepY"]
            ]
            XCTAssertEqual(dictionary as NSDictionary, expectedDictionary)
        }
        else {
            XCTFail("\(String(describing: topClientData)) is not a Dictionary.")
        }
        
        let insertedClientData = self.scheduleManager.buildClientData(from: subtaskPath.result, for: subtaskSchedule)?.clientData
        XCTAssertNotNil(insertedClientData)
        if let stringValue = insertedClientData as? String {
            XCTAssertEqual(stringValue, "insertStep")
        }
        else {
            XCTFail("\(String(describing: insertedClientData)) is not a String.")
        }
    }
    
    func testAppendClientData_ShouldReplaceIsFalse() {
        shouldReplacePrevious = false
        
        let taskPath = runCompoundTask()
        guard let subtaskPath = taskPath.childPaths[insertTaskIdentifier] else {
            XCTFail("Fails assumption. Could not retrieve child task path.")
            return
        }
        
        // Create an associated schedule for the inserted task and the top level task
        let schedules = self.createSchedules(identifiers: [mainTaskIdentifier, insertTaskIdentifier],
                                             clientData: nil)
        guard let schedule = schedules[insertTaskIdentifier] else {
                XCTFail("Fails assumption. Did not create expected schedules.")
                return
        }
        
        self.scheduleManager.appendClientData(from: subtaskPath.result, to: schedule)
        XCTAssertEqual(schedule.clientData as? [String], ["insertStep"])
        
        self.scheduleManager.appendClientData(from: subtaskPath.result, to: schedule)
        XCTAssertEqual(schedule.clientData as? [String], ["insertStep", "insertStep"])
    }
    
    func testAppendClientData_ShouldReplaceIsTrue() {
        shouldReplacePrevious = true
        
        let taskPath = runCompoundTask()
        guard let subtaskPath = taskPath.childPaths[insertTaskIdentifier] else {
            XCTFail("Fails assumption. Could not retrieve child task path.")
            return
        }
        
        // Create an associated schedule for the inserted task and the top level task
        let schedules = self.createSchedules(identifiers: [mainTaskIdentifier, insertTaskIdentifier],
                                             clientData: nil)
        guard let schedule = schedules[insertTaskIdentifier] else {
            XCTFail("Fails assumption. Did not create expected schedules.")
            return
        }
        
        self.scheduleManager.appendClientData(from: subtaskPath.result, to: schedule)
        XCTAssertEqual(schedule.clientData as? [String], ["insertStep"])
        
        self.scheduleManager.appendClientData(from: subtaskPath.result, to: schedule)
        XCTAssertEqual(schedule.clientData as? [String], ["insertStep"])
    }
    
    func testUpdateSchedules() {
        // Before calling the readyToSave method of the task controller, the task path is copied. The copy
        // does not include pointers to objects that are used to run the task and **only** includes properties
        // used to archive the task result.
        let taskPath = runCompoundTask().copy() as! RSDTaskPath
        let schedules = self.createSchedules(identifiers: [mainTaskIdentifier, insertTaskIdentifier],
                                             clientData: nil)
        guard let topSchedule = schedules[mainTaskIdentifier],
            let subtaskSchedule = schedules[insertTaskIdentifier] else {
                XCTFail("Fails assumption. Did not create expected schedules.")
                return
        }
        
        self.scheduleManager.updateSchedules(for: taskPath)
        
        XCTAssertNotNil(self.scheduleManager.sendUpdated_schedules)
        if let updatedSchedules = self.scheduleManager.sendUpdated_schedules {
            let resultSet = Set(updatedSchedules)
            let expectedSchedules = Set([topSchedule, subtaskSchedule])
            XCTAssertEqual(resultSet, expectedSchedules)
        }
        
        XCTAssertEqual(taskPath, self.scheduleManager.sendUpdated_taskPath)
        
        XCTAssertNotNil(topSchedule.finishedOn)
        XCTAssertNotNil(topSchedule.startedOn)
        XCTAssertNotNil(topSchedule.clientData)
        
        XCTAssertNotNil(subtaskSchedule.finishedOn)
        XCTAssertNotNil(subtaskSchedule.startedOn)
        XCTAssertNotNil(subtaskSchedule.clientData)
    }
    
    
    // MARK: Helper methods
    
    let insertTaskIdentifier = "insertTask"
    let insertTaskSchemaIdentifier = "schemaA"
    let insertTaskSchemaRevision = 3
    
    let mainTaskIdentifier = "test"
    let mainTaskSchemaIdentifier = "test"
    let mainTaskSchemaRevision = 2
    
    let tempTaskIdentifier = "tempTask"
    
    func runCompoundTask() -> RSDTaskPath {
        
        // Create a task to be inserted into the parent task.
        let insertStep = TestStep(identifier: "insertStep")
        var insertTask = TestTask(identifier: insertTaskIdentifier, stepNavigator: TestConditionalNavigator(steps: [insertStep]))
        insertTask.schemaInfo = RSDSchemaInfoObject(identifier: insertTaskSchemaIdentifier, revision: insertTaskSchemaRevision)

        var steps: [RSDStep] = []
        steps.append(TestSubtaskStep(task: insertTask))
        steps.append(contentsOf: TestStep.steps(from: ["introduction", "step1"]))
        steps.append(RSDSectionStepObject(identifier: "step2", steps: TestStep.steps(from: ["stepX", "stepY"])))
        steps.append(RSDSectionStepObject(identifier: "step3", steps: TestStep.steps(from: ["stepX", "stepY"])))
        steps.append(RSDUIStepObject(identifier: "completion"))
        
        var task = TestTask(identifier: mainTaskIdentifier, stepNavigator: TestConditionalNavigator(steps: steps))
        task.schemaInfo = RSDSchemaInfoObject(identifier: mainTaskSchemaIdentifier, revision: mainTaskSchemaRevision)
        
        let taskController = TestTaskController()
        taskController.topLevelTask = task
        let _ = taskController.test_stepTo("completion")
        
        return taskController.taskPath!
    }
}

var shouldReplacePrevious = false

extension RSDAnswerResultObject : SBAClientDataResult {
    
    public func clientData() throws -> SBBJSONValue? {
        guard self.answerType == .string else { return nil }
        return self.value as? NSString
    }
    
    public func shouldReplacePreviousClientData() -> Bool {
        return shouldReplacePrevious
    }
    
    public func buildArchiveData(at stepPath: String?) throws -> (manifest: RSDFileManifest, data: Data)? {
        // archive isn't tested using this method.
        return nil
    }
}


