//
//  ScheduleFilteringTests.swift
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

class ScheduleFilteringTests: SBAScheduleManagerTests {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHelperMethods_CreateSchedule() {
        
        // Test creating the schedule - BridgeSDK has changed so that now these objects have to be created
        // using a combo of dictionaries and objects. My tests are failing so I am trying to debug how to create
        // the schedule. syoung 05/10/2018
        let finishedOn = Date()
        let scheduledOn = finishedOn.startOfDay()
        let expiresOn = scheduledOn.addingNumberOfDays(1)
        let clientData : [String : Any] = ["foo" : "bar"]
        let scheduleGuid = UUID().uuidString
        let activityGuid = UUID().uuidString
        
        let schedule = createSchedule(with: "foo", scheduledOn: scheduledOn, expiresOn: expiresOn, finishedOn: finishedOn, clientData: clientData as NSDictionary, schedulePlanGuid: scheduleGuid, activityGuid: activityGuid)
        
        XCTAssertNotNil(schedule.guid)
        XCTAssertNotNil(schedule.schedulePlanGuid)
        XCTAssertEqual(schedule.scheduledOn, scheduledOn)
        XCTAssertEqual(schedule.expiresOn, expiresOn)
        XCTAssertEqual(schedule.finishedOn, finishedOn)
        XCTAssertEqual(schedule.clientData as? NSDictionary, clientData as NSDictionary)
        
        guard let activity = (schedule.activity as Any) as? SBBActivity else {
            XCTFail("Failed to create the expected object type: \(schedule.activity)")
            return
        }
        
        XCTAssertNotNil(activity.guid)
        XCTAssertEqual(activity.label, "foo")
        
        guard let taskRef = (activity.task as Any) as? SBBTaskReference else {
            XCTFail("Failed to create the expected object type: \(String(describing: activity.task))")
            return
        }
        
        XCTAssertEqual(taskRef.identifier, "foo")
        XCTAssertEqual(schedule.activityIdentifier, "foo")
    }
    
    func testScheduledActivitiesForActivityGroup_Today_WithUniqueSchedulePlanGUID() {
        
        let taskGroupAlpha = ["taskA", "taskB", "taskC"]
        let taskGroupBeta = ["taskD", "taskE"]
        
        let group1 = createTaskGroup("group1", taskGroupAlpha, UUID().uuidString,
                                     [ "taskA" : UUID().uuidString, "taskB" : UUID().uuidString, "taskC" : UUID().uuidString])
        let group2 = createTaskGroup("group2", taskGroupAlpha, UUID().uuidString)
        let group3 = createTaskGroup("group3", taskGroupBeta, UUID().uuidString)
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let _ = setupSchedules(for: [group2, group1, group3], scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: lastWeek.addingNumberOfDays(1), clientData: nil)
        
        let expectedSchedules = createSchedules(for: group1, scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = createSchedules(for: group2, scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = createSchedules(for: group3, scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        
        let _ = setupSchedules(for: [group1, group2, group3], scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn: nil, clientData: nil)
        
        // check assumptions
        XCTAssertEqual(scheduleManager.scheduledActivities.count, 24)
        
        let schedules = scheduleManager.scheduledActivities(for: group1, availableOn: now)
        
        XCTAssertEqual(schedules, expectedSchedules)
    }
    
    func testScheduledActivitiesForActivityGroup_Today_WithSchedulePlanGUID() {
        
        let taskGroupAlpha = ["taskA", "taskB", "taskC"]
        let taskGroupBeta = ["taskD", "taskE"]
        
        let group1 = createTaskGroup("group1", taskGroupAlpha, UUID().uuidString)
        let group2 = createTaskGroup("group2", taskGroupAlpha, UUID().uuidString)
        let group3 = createTaskGroup("group3", taskGroupBeta, UUID().uuidString)
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let _ = setupSchedules(for: [group1, group2, group3], scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: lastWeek.addingNumberOfDays(1), clientData: nil)
        
        let expectedSchedules = createSchedules(for: group1, scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = createSchedules(for: group2, scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = createSchedules(for: group3, scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        
        let _ = setupSchedules(for: [group1, group2, group3], scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn: nil, clientData: nil)
        
        // check assumptions
        XCTAssertEqual(scheduleManager.scheduledActivities.count, 24)
        
        let schedules = scheduleManager.scheduledActivities(for: group1, availableOn: now)
        
        XCTAssertEqual(schedules, expectedSchedules)
    }
    
    func testScheduledActivitiesForActivityGroup_Today_NoSchedulePlanGUID() {
        
        let taskGroupAlpha = ["taskA", "taskB", "taskC"]
        let taskGroupBeta = ["taskD", "taskE"]
        
        let group1 = createTaskGroup("group1", taskGroupAlpha, nil)
        let group3 = createTaskGroup("group3", taskGroupBeta, nil)
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let _ = setupSchedules(for: [group1, group3], scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: lastWeek.addingNumberOfDays(1), clientData: nil)
        
        let expectedSchedules = createSchedules(for: group1, scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = createSchedules(for: group3, scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        
        let _ = setupSchedules(for: [group1, group3], scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn: nil, clientData: nil)
        
        let schedules = scheduleManager.scheduledActivities(for: group1, availableOn: now)
        
        XCTAssertEqual(schedules, expectedSchedules)
    }
    
    func testScheduledActivitiesForActivityGroup_NextWeek_WithSchedulePlanGUID() {
        
        let taskGroupAlpha = ["taskA", "taskB", "taskC"]
        let taskGroupBeta = ["taskD", "taskE"]
        
        let group1 = createTaskGroup("group1", taskGroupAlpha, UUID().uuidString)
        let group2 = createTaskGroup("group2", taskGroupAlpha, UUID().uuidString)
        let group3 = createTaskGroup("group3", taskGroupBeta, UUID().uuidString)
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let _ = setupSchedules(for: [group1, group2, group3], scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: lastWeek.addingNumberOfDays(1), clientData: nil)
        let _ = setupSchedules(for: [group1, group2, group3], scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        
        let expectedSchedules = createSchedules(for: group1, scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn: nil, clientData: nil)
        let _ = createSchedules(for: group2, scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn: nil, clientData: nil)
        let _ = createSchedules(for: group3, scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn: nil, clientData: nil)
        
        let schedules = scheduleManager.scheduledActivities(for: group1, availableOn: now.addingNumberOfDays(7))
        
        XCTAssertEqual(schedules, expectedSchedules)
    }
    
    func testScheduledActivitiesForActivityGroup_NextWeek_NoSchedulePlanGUID() {
        
        let taskGroupAlpha = ["taskA", "taskB", "taskC"]
        let taskGroupBeta = ["taskD", "taskE"]
        
        let group1 = createTaskGroup("group1", taskGroupAlpha, nil)
        let group3 = createTaskGroup("group3", taskGroupBeta, nil)
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let _ = setupSchedules(for: [group1, group3], scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: lastWeek.addingNumberOfDays(1), clientData: nil)
        let _ = setupSchedules(for: [group1, group3], scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        
        let expectedSchedules = createSchedules(for: group1, scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn: nil, clientData: nil)
        let _ = createSchedules(for: group3, scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn: nil, clientData: nil)
        
        let schedules = scheduleManager.scheduledActivities(for: group1, availableOn: now.addingNumberOfDays(7))
        
        XCTAssertEqual(schedules, expectedSchedules)
    }
    
    func testScheduledActivitiesForActivityGroup_Yesterday_WithSchedulePlanGUID() {
        
        let taskGroupAlpha = ["taskA", "taskB", "taskC"]
        let taskGroupBeta = ["taskD", "taskE"]
        
        let group1 = createTaskGroup("group1", taskGroupAlpha, UUID().uuidString)
        let group2 = createTaskGroup("group2", taskGroupAlpha, UUID().uuidString)
        let group3 = createTaskGroup("group3", taskGroupBeta, UUID().uuidString)
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let _ = setupSchedules(for: [group1, group2, group3], scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = setupSchedules(for: [group1, group2, group3], scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn:nil, clientData: nil)
        
        let expectedSchedules = createSchedules(for: group1, scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: now.addingNumberOfDays(-1), clientData: nil)
        let _ = createSchedules(for: group2, scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: now.addingNumberOfDays(-1), clientData: nil)
        let _ = createSchedules(for: group3, scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: now.addingNumberOfDays(-1), clientData: nil)
        
        let schedules = scheduleManager.scheduledActivities(for: group1, availableOn: todayStart.addingNumberOfDays(-1))
        
        XCTAssertEqual(schedules, expectedSchedules)
    }
    
    func testScheduledActivitiesForActivityGroup_Yesterday_NoSchedulePlanGUID() {
        
        let group1 = createTaskGroup("group1", ["taskA", "taskB", "taskC"], nil)
        let group3 = createTaskGroup("group3", ["taskD", "taskE"], nil)
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let _ = setupSchedules(for: [group1, group3], scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = setupSchedules(for: [group1,group3], scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn:nil, clientData: nil)
        
        let expectedSchedules = createSchedules(for: group1, scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: now.addingNumberOfDays(-1), clientData: nil)
        let _ = createSchedules(for: group3, scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: now.addingNumberOfDays(-1), clientData: nil)
        
        let schedules = scheduleManager.scheduledActivities(for: group1, availableOn: todayStart.addingNumberOfDays(-1))
        
        XCTAssertEqual(schedules, expectedSchedules)
    }
    
    func testInstantiateTaskPath_ClientDataOnPreviousRun_NoGroup() {
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let group1 = createTaskGroup("group1", ["taskA", "taskB", "taskC"], UUID().uuidString)
        let group3 = createTaskGroup("group3", ["taskD", "taskE"], UUID().uuidString)
        let _ = setupSchedules(for: [group1, group3], scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: lastWeek.addingNumberOfDays(1), clientData: nil)
        let _ = setupSchedules(for: [group1, group3], scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = setupSchedules(for: [group1, group3], scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn:nil, clientData: nil)
        
        let expectedClientData : [String : Any] = ["foo" : "bar"]
        
        let activityGuid = UUID().uuidString
        let previousSchedule = createSchedule(with: "test", scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: now.addingNumberOfDays(-1), clientData: expectedClientData as NSDictionary, schedulePlanGuid: nil, activityGuid: activityGuid)
        let expectedSchedule = createSchedule(with: "test", scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil, schedulePlanGuid: previousSchedule.schedulePlanGuid, activityGuid: activityGuid)
        let nextSchedule = createSchedule(with: "test", scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn: nil, clientData: nil, schedulePlanGuid: previousSchedule.schedulePlanGuid, activityGuid: activityGuid)
        
        scheduleManager.scheduledActivities.append(contentsOf: [previousSchedule, expectedSchedule, nextSchedule])
        
        let taskInfo = RSDTaskInfoObject(with: "test")
        let step = RSDUIStepObject(identifier: "introduction")
        let task = RSDTaskObject(identifier: "test", stepNavigator: RSDConditionalStepNavigatorObject(with: [step]))
        let schema = SBBSchemaReference(dictionaryRepresentation: ["id" : "test",
                                                                   "revision" : NSNumber(value: 3)])!
        SBABridgeConfiguration.shared.addMapping(with: schema)
        SBABridgeConfiguration.shared.addMapping(with: task)
        
        let (taskPath, schedule) = scheduleManager.instantiateTaskPath(for: taskInfo)
        let clientData = scheduleManager.clientData(with: taskInfo.identifier)

        XCTAssertEqual(schedule, expectedSchedule)
        XCTAssertNotNil(clientData)
        XCTAssertEqual(clientData as? NSDictionary, expectedClientData as NSDictionary)
        XCTAssertEqual(taskPath.taskInfo as? SBBTaskReference, expectedSchedule.activity.task)
        XCTAssertEqual(taskPath.scheduleIdentifier, expectedSchedule.guid)
    }
    
    func testInstantiateTaskPath_ClientDataOnCurrentRun_NoGroup() {
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let group1 = createTaskGroup("group1", ["taskA", "taskB", "taskC"], UUID().uuidString)
        let group3 = createTaskGroup("group3", ["taskD", "taskE"], UUID().uuidString)
        let _ = setupSchedules(for: [group1, group3], scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: lastWeek.addingNumberOfDays(1), clientData: nil)
        let _ = setupSchedules(for: [group1, group3], scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = setupSchedules(for: [group1, group3], scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn:nil, clientData: nil)
        
        let previousClientData : [String : Any] = ["blue" : "goo"]
        let expectedClientData : [String : Any] = ["foo" : "bar"]
        
        let activityGuid = UUID().uuidString
        
        let previousSchedule = createSchedule(with: "test", scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: now.addingNumberOfDays(-1), clientData: previousClientData as NSDictionary, schedulePlanGuid: nil, activityGuid: activityGuid)
        let expectedSchedule = createSchedule(with: "test", scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: now.addingTimeInterval(-10 * 60), clientData: expectedClientData as NSDictionary, schedulePlanGuid: previousSchedule.schedulePlanGuid, activityGuid: activityGuid)
        let nextSchedule = createSchedule(with: "test", scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn: nil, clientData: nil, schedulePlanGuid: previousSchedule.schedulePlanGuid, activityGuid: activityGuid)
        
        scheduleManager.scheduledActivities.append(contentsOf: [previousSchedule, expectedSchedule, nextSchedule])
        
        let taskInfo = RSDTaskInfoObject(with: "test")
        let step = RSDUIStepObject(identifier: "introduction")
        let task = RSDTaskObject(identifier: "test", stepNavigator: RSDConditionalStepNavigatorObject(with: [step]))
        let schema = SBBSchemaReference(dictionaryRepresentation: ["id" : "test",
                                                                   "revision" : NSNumber(value: 3)])!
        SBABridgeConfiguration.shared.addMapping(with: schema)
        SBABridgeConfiguration.shared.addMapping(with: task)
        
        let (taskPath, schedule) = scheduleManager.instantiateTaskPath(for: taskInfo)
        let clientData = scheduleManager.clientData(with: taskInfo.identifier)

        XCTAssertEqual(schedule, expectedSchedule)
        XCTAssertNotNil(clientData)
        XCTAssertEqual(clientData as? NSDictionary, expectedClientData as NSDictionary)
        XCTAssertEqual(taskPath.taskInfo as? SBBTaskReference, expectedSchedule.activity.task)
        XCTAssertEqual(taskPath.scheduleIdentifier, expectedSchedule.guid)
    }
    
    func testInstantiateTaskPath_ClientDataOnPreviousRun_DifferentGroup() {
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let group1 = createTaskGroup("group1", ["taskA", "taskB", "taskC"], UUID().uuidString)
        let group2 = createTaskGroup("group2", ["taskA", "taskB", "taskC"], UUID().uuidString)
        let group3 = createTaskGroup("group3", ["taskD", "taskE"], UUID().uuidString)
        let previousSchedules = setupSchedules(for: [group1, group2, group3], scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: lastWeek.addingNumberOfDays(1), clientData: nil)
        let todaySchedules = setupSchedules(for: [group1, group2, group3], scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = setupSchedules(for: [group1, group2, group3], scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn:nil, clientData: nil)
        
        let expectedClientData : [String : Any] = ["foo" : "bar"]
        
        guard let previousSchedule = previousSchedules.first(where: {
            $0.activityIdentifier == "taskC" && $0.schedulePlanGuid == group2.schedulePlanGuid!
        }) else {
            XCTFail("Failed to create expected schedule with schedulePlanGuid=\(group2.schedulePlanGuid!): \(previousSchedules)")
            return
        }
        previousSchedule.clientData = expectedClientData as NSDictionary
        XCTAssertNotNil(previousSchedule.finishedOn)
        
        guard let expectedSchedule = todaySchedules.first(where: {
            $0.activityIdentifier == "taskC" && $0.schedulePlanGuid == group1.schedulePlanGuid!
        }) else {
            XCTFail("Failed to create expected schedule with schedulePlanGuid=\(group2.schedulePlanGuid!): \(previousSchedules)")
            return
        }
        
        let taskInfo = RSDTaskInfoObject(with: "taskC")
        let step = RSDUIStepObject(identifier: "introduction")
        let task = RSDTaskObject(identifier: "taskC", stepNavigator: RSDConditionalStepNavigatorObject(with: [step]))
        let schema = SBBSchemaReference(dictionaryRepresentation: ["id" : "taskC",
                                                                   "revision" : NSNumber(value: 3)])!
        SBABridgeConfiguration.shared.addMapping(with: schema)
        SBABridgeConfiguration.shared.addMapping(with: task)
        
        let (taskPath, schedule) = scheduleManager.instantiateTaskPath(for: taskInfo, in: group1)
        let clientData = scheduleManager.clientData(with: taskInfo.identifier)

        XCTAssertEqual(schedule, expectedSchedule)
        XCTAssertNotNil(clientData)
        XCTAssertEqual(clientData as? NSDictionary, expectedClientData as NSDictionary)
        XCTAssertEqual(taskPath.taskInfo as? SBBTaskReference, expectedSchedule.activity.task)
        XCTAssertEqual(taskPath.scheduleIdentifier, expectedSchedule.guid)
        
    }
    
    func testInstantiateTaskPath_NoSchedule() {
        
        let taskInfo = RSDTaskInfoObject(with: "test")
        let step = RSDUIStepObject(identifier: "introduction")
        let task = RSDTaskObject(identifier: "test", stepNavigator: RSDConditionalStepNavigatorObject(with: [step]))
        let schema = SBBSchemaReference(dictionaryRepresentation: ["id" : "test",
                                                                   "revision" : NSNumber(value: 3)])!
        SBABridgeConfiguration.shared.addMapping(with: schema)
        SBABridgeConfiguration.shared.addMapping(with: task)
        
        let (taskPath, schedule) = scheduleManager.instantiateTaskPath(for: taskInfo)
        let clientData = scheduleManager.clientData(with: taskInfo.identifier)

        XCTAssertNil(schedule)
        XCTAssertNil(clientData)
        XCTAssertEqual(taskPath.task?.identifier, task.identifier)
        if let navigator = taskPath.task?.stepNavigator as? RSDConditionalStepNavigator, let step = navigator.steps.first {
            XCTAssertEqual(step.identifier, "introduction")
        } else {
            XCTFail("Failed to return expected task.")
        }
        XCTAssertNil(taskPath.scheduleIdentifier)
        XCTAssertEqual(taskPath.task?.schemaInfo?.schemaIdentifier, "test")
        XCTAssertEqual(taskPath.task?.schemaInfo?.schemaVersion, 3)
    }
    
    func testFetchRequestsSQL_NoGroup() {
        
        let expect = expectation(description: "Update finished called.")
        scheduleManager.updateFinishedBlock = {
            expect.fulfill()
        }
        scheduleManager.loadScheduledActivities()
        waitForExpectations(timeout: 2) { (err) in
            print(String(describing: err))
        }
        
        XCTAssertNil(scheduleManager.updateFailed_error)
        XCTAssertNotNil(scheduleManager.update_fetchedActivities)
    }
    
    func testFetchRequestsSQL_WithScheduledPlanGuid() {
        
        scheduleManager.activityGroup = createTaskGroup("group1", ["taskA", "taskB", "taskC"], UUID().uuidString)
        
        let expect = expectation(description: "Update finished called.")
        scheduleManager.updateFinishedBlock = {
            expect.fulfill()
        }
        scheduleManager.loadScheduledActivities()
        waitForExpectations(timeout: 2) { (err) in
            print(String(describing: err))
        }
        
        XCTAssertNil(scheduleManager.updateFailed_error)
        XCTAssertNotNil(scheduleManager.update_fetchedActivities)
    }
    
    func testFetchRequestsSQL_NoScheduledPlanGuid() {
        
        scheduleManager.activityGroup = createTaskGroup("group1", ["taskA", "taskB", "taskC"], nil)
        
        let expect = expectation(description: "Update finished called.")
        scheduleManager.updateFinishedBlock = {
            expect.fulfill()
        }
        scheduleManager.loadScheduledActivities()
        waitForExpectations(timeout: 2) { (err) in
            print(String(describing: err))
        }
        
        XCTAssertNil(scheduleManager.updateFailed_error)
        XCTAssertNotNil(scheduleManager.update_fetchedActivities)
    }
    
    func testLoadActivities_FinishedOnPreviousRun_DifferentGroup() {
        
        let now = Date()
        let todayStart = now.startOfDay()
        let lastWeek = todayStart.addingNumberOfDays(-7)
        let nextWeek = todayStart.addingNumberOfDays(7)
        let twoWeeks = nextWeek.addingNumberOfDays(7)
        
        let expectedTaskIdentifiers = ["taskA", "taskB", "taskC"]
        let group1 = createTaskGroup("group1", expectedTaskIdentifiers, UUID().uuidString)
        let group2 = createTaskGroup("group2", expectedTaskIdentifiers, UUID().uuidString)
        let group3 = createTaskGroup("group3", ["taskD", "taskE"], UUID().uuidString)
        let _ = setupSchedules(for: [group1], scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: nil, clientData: nil)
        let _ = setupSchedules(for: [group2, group3], scheduledOn: lastWeek, expiresOn: todayStart, finishedOn: lastWeek.addingNumberOfDays(1), clientData: nil)
        let _ = setupSchedules(for: [group1, group2, group3], scheduledOn: todayStart, expiresOn: nextWeek, finishedOn: nil, clientData: nil)
        let _ = setupSchedules(for: [group1, group2, group3], scheduledOn: nextWeek, expiresOn: twoWeeks, finishedOn:nil, clientData: nil)
        
        // take all the created schedules and remove them.
        scheduleManager.activityGroup = group1
        scheduleManager.cachedSchedules = scheduleManager.scheduledActivities
        scheduleManager.scheduledActivities = []
        
        let expect = expectation(description: "Update finished called.")
        scheduleManager.updateFinishedBlock = {
            expect.fulfill()
        }
        scheduleManager.loadScheduledActivities()
        waitForExpectations(timeout: 2) { (err) in
            print(String(describing: err))
        }
        
        XCTAssertNil(scheduleManager.updateFailed_error)
        XCTAssertNotNil(scheduleManager.update_fetchedActivities)
        
        guard let filteredActivities = scheduleManager.update_fetchedActivities else {
            XCTFail("Failed to filter out any activities.")
            return
        }
        
        XCTAssertEqual(filteredActivities.count, 6, "\(filteredActivities)")
        let finishedActivities = filteredActivities.filter { $0.isCompleted }
        XCTAssertEqual(finishedActivities.count, 3)
        finishedActivities.forEach {
            XCTAssertEqual($0.schedulePlanGuid, group2.schedulePlanGuid)
        }
        
        let todayActivities = filteredActivities.filter { !$0.isCompleted }
        XCTAssertEqual(todayActivities.count, 3)
        todayActivities.forEach {
            XCTAssertEqual($0.schedulePlanGuid, group1.schedulePlanGuid, "\($0)")
            XCTAssertTrue($0.isAvailableNow, "\($0)")
        }
    }
}
