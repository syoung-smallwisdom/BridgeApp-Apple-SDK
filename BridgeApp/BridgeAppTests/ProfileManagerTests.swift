//
//  ProfileManagerTests.swift
//  BridgeAppTests
//
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
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

class ProfileManagerTests: XCTestCase {

    static let testReportProfileKey: String = "testFlag"
    let appConfigJSON: [String: Any] = [
        "clientData": [
            "profile": [
                "manager": [
                    "items": [
                        [
                            "profileKey": ProfileManagerTests.testReportProfileKey,
                            "sourceKey": "sourceTestFlag",
                            "itemType": "bool",
                            "readonly": false,
                            "type": "report"
                        ]
                    ]
                ],
                "dataSource": [
                    "sections": []
                ]
            ]
        ]
    ]
    
    override func setUp() {
        super.setUp()
        
        BridgeSDK.setup(withBridgeInfo: TestBridgeInfo())
        BridgeSDK.participantManager = MockParticipantManager()
        SBABridgeConfiguration.shared = SBABridgeConfiguration()
        let appConfig = SBBAppConfig(dictionaryRepresentation: self.appConfigJSON)!
        SBABridgeConfiguration.shared.setup(with: appConfig)
    }

    override func tearDown() {
        super.tearDown()
        SBABridgeConfiguration.shared = SBABridgeConfiguration()
    }

    func testProfileItems() {
        let pm = SBABridgeConfiguration.shared.profileManager
        let items = pm.profileItems()
        let keys = pm.profileKeys()
        XCTAssert(keys.contains(ProfileManagerTests.testReportProfileKey), "Expected profile keys to include \(ProfileManagerTests.testReportProfileKey) but it doesn't")
        guard let reportItem = items[ProfileManagerTests.testReportProfileKey]
            else {
                XCTAssert(false, "Expected profile items to include one with the profile key \(ProfileManagerTests.testReportProfileKey) but it doesn't")
                return
        }
        XCTAssert(type(of: reportItem) == SBAReportProfileItem.self, "Expected report profile item to be of class SBAReportProfileItem, but it's a \(String(describing: type(of: reportItem))) instead")
    }

}
