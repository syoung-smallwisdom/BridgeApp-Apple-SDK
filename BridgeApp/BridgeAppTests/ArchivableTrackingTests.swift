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
        
        var result = SBATrackedLoggingCollectionResultObject(identifier: "logging")
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
                XCTAssertEqual(clientData["identifier"] as? String, "logging")
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
    
}
