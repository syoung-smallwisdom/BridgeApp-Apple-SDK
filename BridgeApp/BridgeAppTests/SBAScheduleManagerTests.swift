//
//  SBAScheduleManagerTests.swift
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

class TestBridgeInfo: NSObject, SBBBridgeInfoProtocol {
    var studyIdentifier: String = "bridgeApp-test"
    var certificateName: String? = "bridgeApp-test"
    var cacheDaysAhead: Int = 365
    var cacheDaysBehind: Int = 365
    var environment: SBBEnvironment = .dev
    var usesStandardUserDefaults: Bool = true
    var userDefaultsSuiteName: String? = nil
    var appGroupIdentifier: String? = nil
    var keychainAccessGroup: String? = nil
}

class SBAScheduleManagerTests: XCTestCase {
    
    var scheduleManager: TestScheduleManager!
    var mockActivityManager: MockActivityManager!
    
    override func setUp() {
        super.setUp()
        
        BridgeSDK.setup(withBridgeInfo: TestBridgeInfo())
        SBABridgeConfiguration.shared = SBABridgeConfiguration()
        scheduleManager = TestScheduleManager()
        mockActivityManager = MockActivityManager()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        // flush the bridge config
        SBABridgeConfiguration.shared = SBABridgeConfiguration()
    }

    // Helper methods
    
    func createTaskGroup(_ identifier: String, _ activityIdentifiers: [String], _ schedulePlanGuid: String? = nil,_ activityGuidMap: [String : String]? = nil) -> SBAActivityGroupObject {
        let group = SBAActivityGroupObject(identifier: identifier,
                                            title: nil,
                                            journeyTitle: nil,
                                            image: nil,
                                            activityIdentifiers: activityIdentifiers.map { RSDIdentifier(rawValue: $0) },
                                            notificationIdentifier: nil,
                                            schedulePlanGuid: schedulePlanGuid,
                                            activityGuidMap: activityGuidMap)
        SBABridgeConfiguration.shared.addMapping(with: group)
        return group
    }
    
    func createSchedules(for taskGroup: SBAActivityGroupObject, scheduledOn: Date, expiresOn: Date?, finishedOn: Date?, clientData: SBBJSONValue?) -> [SBBScheduledActivity] {
        
        let schedules = taskGroup.activityIdentifiers.map {
            self.mockActivityManager.createTaskSchedule(with: $0,
                                                        scheduledOn: scheduledOn,
                                                        expiresOn: expiresOn,
                                                        finishedOn: finishedOn,
                                                        clientData: clientData,
                                                        schedulePlanGuid: taskGroup.schedulePlanGuid,
                                                        activityGuid: taskGroup.activityGuidMap?[$0.stringValue])
        }
        
        scheduleManager.scheduledActivities.append(contentsOf: schedules)
        
        return schedules
    }
    
    func createSchedules(identifiers: [String], clientData: [String : SBBJSONValue]? = nil) -> ([String : SBBScheduledActivity]) {
        let schedules = identifiers.reduce(into: [String : SBBScheduledActivity] ()) { (hashtable, identifier) in
            let schedule = self.createSchedule(with: RSDIdentifier(rawValue: identifier),
                                               scheduledOn: Date().startOfDay(),
                                               expiresOn: nil,
                                               finishedOn: nil,
                                               clientData: clientData?[identifier],
                                               schedulePlanGuid: UUID().uuidString,
                                               activityGuid: UUID().uuidString)
            self.scheduleManager.scheduledActivities.append(schedule)
            hashtable[identifier] = schedule
        }
        return schedules
    }
    
    func createSchedule(with identifier: RSDIdentifier, scheduledOn: Date, expiresOn: Date?, finishedOn: Date?, clientData: SBBJSONValue?, schedulePlanGuid: String?, activityGuid: String?) -> SBBScheduledActivity {
        return self.mockActivityManager.createTaskSchedule(with: identifier,
                                                           scheduledOn: scheduledOn,
                                                           expiresOn: expiresOn,
                                                           finishedOn: finishedOn,
                                                           clientData: clientData,
                                                           schedulePlanGuid: schedulePlanGuid,
                                                           activityGuid: activityGuid)
    }
    
    func setupSchedules(for taskGroups: [SBAActivityGroupObject], scheduledOn: Date, expiresOn: Date?, finishedOn: Date?, clientData: SBBJSONValue?) -> [SBBScheduledActivity] {
        return taskGroups.flatMap {
            createSchedules(for: $0, scheduledOn: scheduledOn, expiresOn: expiresOn, finishedOn: finishedOn, clientData: clientData)
        }
    }

}

class TestScheduleManager : SBAScheduleManager {
    
    var updateFinishedBlock: (() -> Void)?
    var updateFailed_error: Error?
    var update_fetchedActivities:[SBBScheduledActivity]?
    var sendUpdated_schedules: [SBBScheduledActivity]?
    var sendUpdated_taskPath: RSDTaskViewModel?
    
    override func updateFailed(_ error: Error) {
        updateFailed_error = error
        super.updateFailed(error)
        updateFinishedBlock?()
        updateFinishedBlock = nil
    }
    
    override func update(fetchedActivities: [SBBScheduledActivity]) {
        update_fetchedActivities = fetchedActivities
        super.update(fetchedActivities: fetchedActivities)
        updateFinishedBlock?()
        updateFinishedBlock = nil
    }
    
    var cachedSchedules: [SBBScheduledActivity]?
    var getCachedSchedules_results: [SBAScheduleManager.FetchRequest : [SBBScheduledActivity]] = [:]
    
    override func getCachedSchedules(using fetchRequest: SBAScheduleManager.FetchRequest) throws -> [SBBScheduledActivity] {
        guard let schedules = cachedSchedules else {
            return try super.getCachedSchedules(using: fetchRequest)
        }
        
        var results = schedules.filter { fetchRequest.predicate.evaluate(with: $0) }
        if let sortDescriptors = fetchRequest.sortDescriptors {
            results = (results as NSArray).sortedArray(using: sortDescriptors) as! [SBBScheduledActivity]
        }
        
        let ret: [SBBScheduledActivity] = {
            if let limit = fetchRequest.fetchLimit {
                return Array(results[..<Int(limit)])
            }
            else {
                return results
            }
        }()
        getCachedSchedules_results[fetchRequest] = ret
        return ret
    }
    
    override func sendUpdated(for schedules: [SBBScheduledActivity], taskViewModel: RSDTaskViewModel?) {
        self.sendUpdated_schedules = schedules
        self.sendUpdated_taskPath = taskViewModel
    }
}

extension SBAScheduleManager.FetchRequest : Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.predicate)
    }
    
    public static func == (lhs: SBAScheduleManager.FetchRequest, rhs: SBAScheduleManager.FetchRequest) -> Bool {
        return lhs.predicate == rhs.predicate
    }
}
