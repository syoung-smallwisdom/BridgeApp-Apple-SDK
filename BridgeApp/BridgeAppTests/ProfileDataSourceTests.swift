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
import Research
@testable import BridgeApp

class ProfileDataSourceTests: XCTestCase {

    static let testReportProfileKey: String = "testFlag"
    static let testReportSourceKey: String = "sourceTestFlag"
    static let testSectionTitle: String = "testSectionTitle"
    static let testProfileItemTitle: String = "testProfileItemTitle"
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testProfileTableItems() {
        let pds = SBAProfileDataSourceObject.shared
        let numSections = pds.numberOfSections()
        XCTAssert(numSections == 1, "Expected one profile section but got \(numSections)")
        
        let numRows = pds.numberOfRows(for: 0)
        XCTAssert(numRows == 1, "Expected one row in section 0 but got \(numRows)")
        
        let sectionTitle = pds.title(for: 0)
        XCTAssert(sectionTitle == ProfileDataSourceTests.testSectionTitle, "Expected section title to be \(ProfileDataSourceTests.testSectionTitle) but got \(String(describing: sectionTitle)) instead")
    }
    
    func testProfileItemProfileTableItems() {
        let pds = SBAProfileDataSourceObject.shared
        guard let item00 = pds.profileTableItem(at: IndexPath(row: 0, section: 0))
            else {
                XCTAssert(false, "Expected there to be a profile table item for section 0 row 0 but it's coming back as nil")
                return
        }
        guard var piptItem = item00  as? SBAProfileItemProfileTableItem
            else {
                XCTAssert(false, "Expected profile table item for section 0 row 0 to be an SBAProfileItemProfileTableItem but instead it's \(String(describing: type(of: item00)))")
                return
        }
        
        XCTAssert(piptItem.title == ProfileDataSourceTests.testProfileItemTitle, "Expected profile table item title to be '\(ProfileDataSourceTests.testProfileItemTitle)' but got '\(String(describing:piptItem.title))' instead")
        
        XCTAssert(piptItem.profileItem?.itemType == .base(.boolean), "Expected profile table item's profile item type to be boolean, but it's \(String(describing: piptItem.profileItem?.itemType)) instead")
        
        XCTAssert(piptItem.profileItemValue == nil, "Expected default profile item value to be nil but it's \(String(describing: piptItem.profileItemValue))")
        
        XCTAssert(piptItem.detail == "", "Expected default profile table item detail to be an empty string, but it's \(String(describing: piptItem.detail))")
        
        piptItem.profileItemValue = false
        
        XCTAssert(piptItem.profileItemValue as? Bool == false, "Expected profile item value to be false but it's \(String(describing: piptItem.profileItemValue))")
        
        let offStr = Localization.localizedString("SETTINGS_STATE_OFF")
        XCTAssert(piptItem.detail == offStr, "Expected profile table item detail to be \(offStr), but it's \(String(describing: piptItem.detail))")

        piptItem.profileItemValue = true
        
        XCTAssert(piptItem.profileItemValue as? Bool == true, "Expected profile item value to be true but it's \(String(describing: piptItem.profileItemValue))")
        
        let onStr = Localization.localizedString("SETTINGS_STATE_ON")
        XCTAssert(piptItem.detail == onStr, "Expected profile table item detail to be \(onStr), but it's \(String(describing: piptItem.detail))")
    }

}
