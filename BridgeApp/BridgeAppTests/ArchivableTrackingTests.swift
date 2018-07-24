//
//  ArchivableTrackingTests.swift
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

class ArchivableTrackingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLoggingCollectionResultArchive_ClientData() {
        
        let identifier = RSDIdentifier.trackedItemsResult.identifier
        var result = SBATrackedLoggingCollectionResultObject(identifier: identifier)
        var loggedResultA = SBATrackedLoggingResultObject(identifier: "itemA", text: "Item A", detail: "a detail")
        loggedResultA.loggedDate = Date().addingTimeInterval(-60)
        var answerResult = RSDAnswerResultObject(identifier: "foo", answerType: .string)
        answerResult.value = "goo"
        loggedResultA.inputResults = [answerResult]
        let loggedResultB = SBATrackedLoggingResultObject(identifier: "itemB", text: "Item B", detail: "b detail")
        result.loggingItems = [loggedResultA, loggedResultB]
        
        do {
            let clientData = try result.clientData()
            XCTAssertNotNil(clientData)
            if let clientData = clientData as? [String : Any] {
                XCTAssertEqual(clientData["identifier"] as? String, identifier)
                if let items = clientData["items"] as? [[String : Any]] {
                    XCTAssertEqual(items.count, 2)
                    if let item = items.first {
                        XCTAssertEqual(item["identifier"] as? String, "itemA")
                        XCTAssertEqual(item["text"] as? String, "Item A")
                        XCTAssertEqual(item["detail"] as? String, "a detail")
                        XCTAssertEqual(item["foo"] as? String, "goo")
                        XCTAssertNotNil(item["loggedDate"])
                    }
                    if let item = items.last {
                        XCTAssertEqual(item["identifier"] as? String, "itemB")
                        XCTAssertEqual(item["text"] as? String, "Item B")
                        XCTAssertEqual(item["detail"] as? String, "b detail")
                        XCTAssertNil(item["loggedDate"])
                    }
                } else {
                    XCTFail("Client data 'items' missing or unexpected type. \(clientData)")
                }
            } else {
                XCTFail("Result returned nil client data or unexpected type.")
            }
        }
        catch let err {
            XCTFail("Failed to encode the result: \(err)")
        }
    }
    
    func testLoggingCollectionResultArchive_UpdateFromClientData_NoItems() {
    
        let clientData: NSDictionary =
        [
            "items" : [
            [
            "foo" : "goo",
            "detail" : "a detail",
            "identifier" : "itemA",
            "loggedDate" : "2018-06-04T13:24:39.772-07:00",
            "text" : "Item A"
            ],
            [
            "detail" : "b detail",
            "text" : "Item B",
            "identifier" : "itemB"
            ]
            ],
            "endDate" : "2018-06-04T13:25:39.772-07:00",
            "startDate" : "2018-06-04T13:25:39.772-07:00",
            "type" : "loggingCollection",
            "identifier" : "logging"
        ]
        
        do {
        
            var result = SBATrackedLoggingCollectionResultObject(identifier: "logging")
            try result.updateSelected(from: clientData, with: [])
            
            let selectedAnswers = result.selectedAnswers
            XCTAssertEqual(selectedAnswers.count, 2)
            
            guard let firstItem = selectedAnswers.first as? SBATrackedLoggingResultObject,
               let lastItem = selectedAnswers.last as? SBATrackedLoggingResultObject
                else {
                    XCTFail("Items nil or not of expected type. \(selectedAnswers)")
                    return
            }
            
            XCTAssertEqual(firstItem.identifier, "itemA")
            XCTAssertEqual(firstItem.text, "Item A")
            XCTAssertEqual(firstItem.detail, "a detail")
            XCTAssertNil(firstItem.loggedDate)
            
            XCTAssertEqual(lastItem.identifier, "itemB")
            XCTAssertEqual(lastItem.text, "Item B")
            XCTAssertEqual(lastItem.detail, "b detail")
            XCTAssertNil(lastItem.loggedDate)
        }
        catch let err {
            XCTFail("Failed to encode the result: \(err)")
        }
    }
    
    func testLoggingCollectionResultArchive_UpdateFromClientDataList() {
        
        let clientDataList: NSArray =
            [[
                "items" : [
                    [
                        "foo" : "goo",
                        "detail" : "a detail",
                        "identifier" : "itemA",
                        "loggedDate" : "2018-06-04T13:24:39.772-07:00",
                        "text" : "Item A"
                    ],
                    [
                        "detail" : "b detail",
                        "text" : "Item B",
                        "identifier" : "itemB"
                    ]
                ],
                "endDate" : "2018-06-04T13:25:39.772-07:00",
                "startDate" : "2018-06-04T13:25:39.772-07:00",
                "type" : "loggingCollection",
                "identifier" : "logging"
        ],
             [
                "items" : [
                    [
                        "foo" : "goo",
                        "detail" : "a detail",
                        "identifier" : "itemA",
                        "loggedDate" : "2018-06-04T13:24:39.772-07:00",
                        "text" : "Item A"
                    ]
                ],
                "endDate" : "2018-06-04T13:25:39.772-07:00",
                "startDate" : "2018-06-04T13:25:39.772-07:00",
                "type" : "loggingCollection",
                "identifier" : "logging"
        ]]
        
        do {
            
            var result = SBATrackedLoggingCollectionResultObject(identifier: "logging")
            try result.updateSelected(from: clientDataList, with: [])
            
            let selectedAnswers = result.selectedAnswers
            XCTAssertEqual(selectedAnswers.count, 1)
            
            guard let firstItem = selectedAnswers.first as? SBATrackedLoggingResultObject
                else {
                    XCTFail("Items nil or not of expected type. \(selectedAnswers)")
                    return
            }
            
            XCTAssertEqual(firstItem.identifier, "itemA")
            XCTAssertEqual(firstItem.text, "Item A")
            XCTAssertEqual(firstItem.detail, "a detail")
            XCTAssertNil(firstItem.loggedDate)
        }
        catch let err {
            XCTFail("Failed to encode the result: \(err)")
        }
    }
    
    func testMedicationResultArchive_ClientData() {
        
        let identifier = RSDIdentifier.trackedItemsResult.identifier
        var result = SBAMedicationTrackingResult(identifier: identifier)
        var medA3 = SBAMedicationAnswer(identifier: "medA3")
        medA3.dosage = "1 ml"
        medA3.scheduleItems = [RSDWeeklyScheduleObject(timeOfDayString: "08:00", daysOfWeek: [.monday, .wednesday, .friday])]
        var medC3 = SBAMedicationAnswer(identifier: "medC3")
        medC3.dosage = "3 mg"
        medC3.scheduleItems = [RSDWeeklyScheduleObject(timeOfDayString: "20:00", daysOfWeek: [.sunday, .thursday])]
        result.reminders = [45, 60]
        result.medications = [medA3, medC3]
        
        do {
            let clientData = try result.clientData() as? [String : Any]
            XCTAssertNotNil(clientData)
            if let items = clientData?["items"] as? [[String : Any]] {
                XCTAssertEqual(items.count, 2)
                if let item = items.first {
                    XCTAssertEqual(item["identifier"] as? String, "medA3")
                    XCTAssertEqual(item["dosage"] as? String, "1 ml")
                    if let schedules = item["scheduleItems"] as? [[String : Any]],
                        let schedule = schedules.first {
                        XCTAssertEqual(schedules.count, 1)
                        XCTAssertEqual(schedule["timeOfDay"] as? String, "08:00")
                        XCTAssertEqual(schedule["daysOfWeek"] as? [Int], [6,4,2])
                    }
                    else {
                        XCTFail("Client data 'schedules' missing or unexpected type. \(items)")
                    }
                }
                if let item = items.last {
                    XCTAssertEqual(item["identifier"] as? String, "medC3")
                    XCTAssertEqual(item["dosage"] as? String, "3 mg")
                }
            } else {
                XCTFail("Client data 'items' missing or unexpected type. \(String(describing: clientData))")
            }
            if let reminders = clientData?["reminders"] as? [Int] {
                XCTAssertEqual(reminders.count, 2)
                XCTAssertEqual(reminders.first, 45)
                XCTAssertEqual(reminders.last, 60)
            } else {
                XCTFail("Client data 'reminders' missing or unexpected type. \(String(describing: clientData))")
            }
        }
        catch let err {
            XCTFail("Failed to encode the result: \(err)")
        }
    }
    
    func testMedicationResult_UpdateFromClientData_NoItems() {
        let clientData: [String : Any] = [
            "items": [
            [
                "dosage" : "1 ml",
                "identifier" : "medA3",
                "scheduleItems" : [
                    [
                        "daysOfWeek" : [ 6, 4, 2 ],
                        "timeOfDay" : "08:00"
                    ]
                ]
            ],
            [
                "dosage" : "3 mg",
                "identifier" : "medC3",
                "scheduleItems" : [
                        [
                            "daysOfWeek" : [ 1, 5 ],
                            "timeOfDay" : "20:00"
                        ]
                    ]
            ]],
            "reminders": [45]
    ]
        
        do {

            var result = SBAMedicationTrackingResult(identifier: "logging")
            try result.updateSelected(from: clientData as SBBJSONValue, with: [])

            let selectedAnswers = result.selectedAnswers
            XCTAssertEqual(selectedAnswers.count, 2)

            guard let firstItem = selectedAnswers.first as? SBAMedicationAnswer,
                let lastItem = selectedAnswers.last as? SBAMedicationAnswer
                else {
                    XCTFail("Items nil or not of expected type. \(selectedAnswers)")
                    return
            }

            XCTAssertEqual(firstItem.identifier, "medA3")
            XCTAssertEqual(firstItem.dosage, "1 ml")

            XCTAssertEqual(lastItem.identifier, "medC3")
            XCTAssertEqual(lastItem.dosage, "3 mg")

            XCTAssertEqual(result.reminders?.count, 1)
            XCTAssertEqual(result.reminders?.first, 45)
        }
        catch let err {
            XCTFail("Failed to encode the result: \(err)")
        }
    }
}
