//
//  ProfileDataSourceTests.swift
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

class ProfileDataSourceTests: XCTestCase {

    static let testReportProfileKey: String = "testFlag"
    static let testReportSourceKey: String = "sourceTestFlag"
    static let testSectionTitle: String = "testSectionTitle"
    static let testProfileItemTitle: String = "testProfileItemTitle"
    
    let appConfigJSON: [String: Any] = [
        "clientData": [
            "profile": [
                "manager": [
                    "items": [
                        [
                            "profileKey": ProfileDataSourceTests.testReportProfileKey,
                            "sourceKey": ProfileDataSourceTests.testReportSourceKey,
                            "itemType": "bool",
                            "readonly": false,
                            "type": "report"
                        ]
                    ]
                ],
                "dataSource": [
                    "sections": [
                        [
                            "title": ProfileDataSourceTests.testSectionTitle,
                            "items": [
                                [
                                    "type": "profileItem",
                                    "title": ProfileDataSourceTests.testProfileItemTitle,
                                    "profileItemKey": ProfileDataSourceTests.testReportProfileKey
                                ]
                            ]
                        ]
                    ]
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

    func testProfileTableItems() {
        let pds = SBABridgeConfiguration.shared.profileDataSource
        let numSections = pds.numberOfSections()
        XCTAssert(numSections == 1, "Expected one profile section but got \(numSections)")
        
        let numRows = pds.numberOfRows(for: 0)
        XCTAssert(numRows == 1, "Expected one row in section 0 but got \(numRows)")
        
        let sectionTitle = pds.title(for: 0)
        XCTAssert(sectionTitle == ProfileDataSourceTests.testSectionTitle, "Expected section title to be \(ProfileDataSourceTests.testSectionTitle) but got \(String(describing: sectionTitle)) instead")
    }
    
    func testProfileItemProfileTableItems() {
        let pds = SBABridgeConfiguration.shared.profileDataSource
        guard let item00 = pds.profileTableItem(at: IndexPath(row: 0, section: 0))
            else {
                XCTAssert(false, "Expected there to be a profile table item for section 0 row 0 but it's coming back as nil")
                return
        }
        guard let piptItem = item00  as? SBAProfileItemProfileTableItem
            else {
                XCTAssert(false, "Expected profile table item for section 0 row 0 to be an SBAProfileItemProfileTableItem but instead it's \(String(describing: type(of: item00)))")
                return
        }
        
        
        
    }

}
