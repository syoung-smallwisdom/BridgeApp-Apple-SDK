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
    static let profileKeyParticipantEmail: String = "profileKeyParticipantEmail"
    static let profileKeyParticipantPhone: String = "profileKeyParticipantPhone"
    static let profileKeyParticipantFirst: String = "profileKeyParticipantFirst"
    static let profileKeyParticipantClientDataFirst: String = "profileKeyParticipantClientDataFirst"
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func checkFor(profileKey: String) {
        let pm = SBAProfileManagerObject.shared
        let items = pm.profileItems()
        let keys = pm.profileKeys()
        XCTAssert(keys.contains(profileKey), "Expected profile keys to include '\(profileKey)' but it doesn't")
        guard items[profileKey] != nil
            else {
                XCTAssert(false, "Expected profile items to include one with the profile key '\(profileKey)' but it doesn't")
                return
        }
    }

    func testProfileItems() {
        self.checkFor(profileKey: ProfileManagerTests.profileKey)
        self.checkFor(profileKey: ProfileManagerTests.profileKeyIsClientData)
        self.checkFor(profileKey: ProfileManagerTests.profileKeyNotClientData)
        self.checkFor(profileKey: ProfileManagerTests.profileKeyParticipantEmail)
        self.checkFor(profileKey: ProfileManagerTests.profileKeyParticipantFirst)
        self.checkFor(profileKey: ProfileManagerTests.profileKeyParticipantPhone)
        self.checkFor(profileKey: ProfileManagerTests.profileKeyParticipantClientDataFirst)
    }
    
    func checkProfileItemStorage(profileKey: String) {
        let pm = SBAProfileManagerObject.shared
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
            guard let wrappedData = reportData.data
                else {
                    XCTAssert(false, "Expected reportData.data to exist but it's nil")
                    return
            }
            var data: Any!
            if let dict = wrappedData as? NSDictionary,
                let clientData = dict[kReportClientDataKey] {
                    data = clientData
            }
            else {
                data = wrappedData
            }
            var reportValue = data
            if !reportItem.clientDataIsItem {
                guard let clientData = data as? NSDictionary
                    else {
                        XCTAssert(false, "Expected reportData.data to be castable to a Dictionary, but it's not: \(String(describing: type(of: reportData.data)))")
                        return
                }
                reportValue = clientData[reportItem.demographicKey]
            }
            // syoung 10/08/2018 
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
    
    func checkParticipantItemStorage(profileKey: String) {
        let pm = SBAProfileManagerObject.shared
        let items = pm.profileItems()
        guard var participantItem = items[profileKey] as? SBAStudyParticipantProfileItem
            else {
                XCTAssert(false, "Expected profile items to include a SBAStudyParticipantProfileItem with the profile key '\(profileKey)' but it doesn't")
                return
        }
        
        let testString = "garbage"
        let savedValue = participantItem.value as? String
        participantItem.value = testString
        
        // check that it's stored at the appropriate key path as the expected value
        guard let participant = SBAParticipantManager.shared.studyParticipant
            else {
                XCTAssert(false, "Expected participant to exist but it's nil")
                return
        }
        
        let itemValue = participant.value(forKeyPath: participantItem.sourceKey)
        
        if participantItem.readonly {
            XCTAssert((itemValue as? String) == savedValue, "Expected participant.\(participantItem.sourceKey) to be '\(String(describing: savedValue))' because it's readonly, but instead it's '\(String(describing: itemValue))'")
            return
        }
        
        if itemValue == nil {
            XCTAssert(false, "Expected participant.\(participantItem.sourceKey) to be a String, but instead it's nil")
            return
        }
        
        guard let stringValue = itemValue as? String
            else {
                XCTAssert(false, "Expected participant.\(participantItem.sourceKey) value to be a String, but it's a \(String(describing: type(of: itemValue))) instead")
                return
        }
        
        XCTAssert(stringValue == testString, "Expected stringValue to be '\(testString)' but it's \(String(describing: stringValue))")
    }
    
    func checkParticipantClientDataItemStorage(profileKey: String) {
        let pm = SBAProfileManagerObject.shared
        let items = pm.profileItems()
        guard var clientDataItem = items[profileKey] as? SBAStudyParticipantClientDataProfileItem
            else {
                XCTAssert(false, "Expected profile items to include a SBAStudyParticipantClientDataProfileItem with the profile key '\(profileKey)' but it doesn't")
                return
        }
        
        if let fallback = clientDataItem.fallbackKeyPath {
            guard let participantItemTuple = items.first(where: { (keyAndValue) -> Bool in
                return keyAndValue.value.sourceKey == fallback
            }) else {
                XCTAssert(false, "Expected profile items to include an item with the source key '\(fallback)' but it doesn't")
                return
            }
            guard var participantItem = participantItemTuple.value as? SBAStudyParticipantProfileItem
                else {
                    XCTAssert(false, "Expected profile items with the source key '\(fallback)' to be a SBAStudyParticipantProfileItem but instead it's a \(String(describing: type (of:participantItemTuple.value)))")
                    return
            }
            
            // set the fallback property's value
            let testFirstString = "testfirst"
            participantItem.value = testFirstString
            
            // make sure it falls back to the fallback property value until set
            let startingValue = clientDataItem.value as! String
            XCTAssert(startingValue == testFirstString, "Expected client data profile item to fall back to '\(testFirstString)' but instead it's '\(String(describing: startingValue))'")
        }
        
        
        let testString = "garbage"
        clientDataItem.value = testString
        
        // check that it's stored at the appropriate key path as the expected value
        guard let participant = SBAParticipantManager.shared.studyParticipant
            else {
                XCTAssert(false, "Expected participant to exist but it's nil")
                return
        }
        
        guard let clientData = participant.clientData as? [String : SBBJSONValue]
            else {
                XCTAssert(false, "Expected participant.clientData to be a [String : SBBJSONValue] but it's nil")
                return
        }
        
        guard let itemValue = clientData[clientDataItem.sourceKey]
            else {
                XCTAssert(false, "Expected client data item '\(clientDataItem.sourceKey)' value to be a String, but instead it's nil")
                return
        }
        
        guard let stringValue = itemValue as? String
            else {
                XCTAssert(false, "Expected client data item '\(clientDataItem.sourceKey)' value to be a String, but it's a \(String(describing: type(of: itemValue))) instead")
                return
        }
        
        XCTAssert(stringValue == testString, "Expected stringValue to be '\(testString)' but it's \(String(describing: stringValue))")

    }
    
    func testProfileItemsStorage() {
        self.checkProfileItemStorage(profileKey: ProfileManagerTests.profileKey)
        self.checkProfileItemStorage(profileKey: ProfileManagerTests.profileKeyIsClientData)
        self.checkProfileItemStorage(profileKey: ProfileManagerTests.profileKeyNotClientData)
        self.checkParticipantItemStorage(profileKey: ProfileManagerTests.profileKeyParticipantEmail)
        self.checkParticipantItemStorage(profileKey: ProfileManagerTests.profileKeyParticipantPhone)
        self.checkParticipantItemStorage(profileKey: ProfileManagerTests.profileKeyParticipantFirst)
        self.checkParticipantClientDataItemStorage(profileKey: ProfileManagerTests.profileKeyParticipantClientDataFirst)
    }

}
