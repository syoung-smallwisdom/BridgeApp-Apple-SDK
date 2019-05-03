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

    static let profileKey: String = "testFlag"
    static let sourceKey: String = "sourceTestFlag"
    static let profileKeyIsClientData: String = "testFlagIsClientData"
    static let sourceKeyIsClientData: String = "sourceTestFlagIsClientData"
    static let profileKeyNotClientData: String = "testFlagNotClientData"
    static let sourceKeyNotClientData: String = "sourceTestFlagNotClientData"
    let appConfigJSON: [String: Any] = [
        "clientData": [
            "profile": [
                "manager": [
                    "items": [
                        [
                            "profileKey": ProfileManagerTests.profileKey,
                            "sourceKey": ProfileManagerTests.sourceKey,
                            "itemType": "boolean",
                            "readonly": false,
                            "type": "report"
                        ],
                        [
                            "profileKey": ProfileManagerTests.profileKeyIsClientData,
                            "sourceKey": ProfileManagerTests.sourceKeyIsClientData,
                            "clientDataIsItem": true,
                            "itemType": "boolean",
                            "readonly": false,
                            "type": "report"
                        ],
                        [
                            "profileKey": ProfileManagerTests.profileKeyNotClientData,
                            "sourceKey": ProfileManagerTests.sourceKeyNotClientData,
                            "clientDataIsItem": false,
                            "itemType": "boolean",
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
    
    func checkFor(profileKey: String) {
        let pm = SBABridgeConfiguration.shared.profileManager
        let items = pm.profileItems()
        let keys = pm.profileKeys()
        XCTAssert(keys.contains(profileKey), "Expected profile keys to include '\(profileKey)' but it doesn't")
        guard let reportItem = items[profileKey]
            else {
                XCTAssert(false, "Expected profile items to include one with the profile key '\(profileKey)' but it doesn't")
                return
        }
        XCTAssert(type(of: reportItem) == SBAReportProfileItem.self, "Expected report profile item to be of class SBAReportProfileItem, but it's a \(String(describing: type(of: reportItem))) instead")
    }

    func testProfileItems() {
        self.checkFor(profileKey: ProfileManagerTests.profileKey)
        self.checkFor(profileKey: ProfileManagerTests.profileKeyIsClientData)
        self.checkFor(profileKey: ProfileManagerTests.profileKeyNotClientData)
    }
    
    func checkStorage(profileKey: String) {
        let pm = SBABridgeConfiguration.shared.profileManager
        let items = pm.profileItems()
        guard var reportItem = items[profileKey] as? SBAReportProfileItem
            else {
                XCTAssert(false, "Expected profile items to include a SBAReportProfileItem with the profile key '\(profileKey)' but it doesn't")
                return
        }
        
        reportItem.value = true
        
        // check that it's stored in the appropriate Report as the expected value
        do {
            let reportData = try BridgeSDK.participantManager.getLatestCachedData(forReport: reportItem.sourceKey)
            guard let data = reportData.data
                else {
                    XCTAssert(false, "Expected reportData.data to exist but it's nil")
                    return
            }
            var reportValue = data as? RSDJSONSerializable
            if !reportItem.clientDataIsItem {
                guard let clientData = data as? [String : RSDJSONSerializable]
                    else {
                        XCTAssert(false, "Expected reportData.data to be castable to a JSON-serializable Dictionary, but it's not: \(String(describing: type(of: reportData.data)))")
                        return
                }
                reportValue = clientData[reportItem.demographicKey]
            }
            guard let boolValue = (reportValue as? NSNumber)?.boolValue
                else {
                    XCTAssert(false, "Expected report value to be an NSNumber with a boolValue, but it's a \(String(describing: type(of: reportValue))) instead")
                    return
            }
            XCTAssert(boolValue == true, "Expected reportValue to be 'true' but it's \(String(describing: boolValue))")
        } catch let error {
            XCTAssert(false, "Expected there to be 'latest cached data' for report '\(profileKey)' but there isn't\n error: \(String(describing: error))")
            return
        }
        
        // check that we can correctly retrieve it from the reportItem
        XCTAssert(reportItem.value as? Bool == true, "Expected reportItem.value to be 'true' but it's '\(String(describing: reportItem.value))'")
    }
    
    func testReportProfileItems() {
        self.checkStorage(profileKey: ProfileManagerTests.profileKey)
        self.checkStorage(profileKey: ProfileManagerTests.profileKeyIsClientData)
        self.checkStorage(profileKey: ProfileManagerTests.profileKeyNotClientData)
    }

}
