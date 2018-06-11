//
//  CodableTrackedDataTests.swift
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

class CodableTrackedDataTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        // setup to have an image wrapper delegate set so the image wrapper won't crash
        RSDImageWrapper.sharedDelegate = TestImageWrapperDelegate()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testTrackedSectionObject_Codable() {
        let json = """
        {
            "identifier": "foo",
            "text": "Text",
            "detail" : "Detail"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBATrackedSectionObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.text, "Text")
            XCTAssertEqual(object.detail, "Detail")
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "foo")
            XCTAssertEqual(dictionary["text"] as? String, "Text")
            XCTAssertEqual(dictionary["detail"] as? String, "Detail")
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTrackedItem_Codable() {
        let json = """
        {
            "identifier": "advil-ibuprofen",
            "sectionIdentifier": "pain",
            "title": "Advil",
            "shortText": "Adv",
            "detail": "(Ibuprofen)",
            "isExclusive": true,
            "icon": "pill",
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBATrackedItemObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "advil-ibuprofen")
            XCTAssertEqual(object.sectionIdentifier, "pain")
            XCTAssertEqual(object.text, "Advil")
            XCTAssertEqual(object.shortText, "Adv")
            XCTAssertEqual(object.detail, "(Ibuprofen)")
            XCTAssertEqual(object.isExclusive, true)
            XCTAssertEqual(object.icon?.imageName, "pill")
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "advil-ibuprofen")
            XCTAssertEqual(dictionary["sectionIdentifier"] as? String, "pain")
            XCTAssertEqual(dictionary["title"] as? String, "Advil")
            XCTAssertEqual(dictionary["shortText"] as? String, "Adv")
            XCTAssertEqual(dictionary["detail"] as? String, "(Ibuprofen)")
            XCTAssertEqual(dictionary["icon"] as? String, "pill")
            XCTAssertEqual(dictionary["isExclusive"] as? Bool, true)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTrackedItem_Codable_Default() {
        let json = """
        {
            "identifier": "Ibuprofen"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBATrackedItemObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "Ibuprofen")
            XCTAssertEqual(object.text, "Ibuprofen")
            XCTAssertNil(object.sectionIdentifier)
            XCTAssertNil(object.title)
            XCTAssertNil(object.shortText)
            XCTAssertNil(object.detail)
            XCTAssertFalse(object.isExclusive)
            XCTAssertNil(object.icon)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedicationItem_Codable() {
        let json = """
        {
            "identifier": "advil-ibuprofen",
            "sectionIdentifier": "pain",
            "title": "Advil",
            "shortText": "Adv",
            "detail": "(Ibuprofen)",
            "isExclusive": true,
            "icon": "pill",
            "injection": true
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAMedicationItem.self, from: json)
            
            XCTAssertEqual(object.identifier, "advil-ibuprofen")
            XCTAssertEqual(object.sectionIdentifier, "pain")
            XCTAssertEqual(object.text, "Advil")
            XCTAssertEqual(object.shortText, "Adv")
            XCTAssertEqual(object.detail, "(Ibuprofen)")
            XCTAssertEqual(object.isExclusive, true)
            XCTAssertEqual(object.icon?.imageName, "pill")
            XCTAssertEqual(object.isContinuousInjection, true)

            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "advil-ibuprofen")
            XCTAssertEqual(dictionary["sectionIdentifier"] as? String, "pain")
            XCTAssertEqual(dictionary["title"] as? String, "Advil")
            XCTAssertEqual(dictionary["shortText"] as? String, "Adv")
            XCTAssertEqual(dictionary["detail"] as? String, "(Ibuprofen)")
            XCTAssertEqual(dictionary["icon"] as? String, "pill")
            XCTAssertEqual(dictionary["isExclusive"] as? Bool, true)
            XCTAssertEqual(dictionary["injection"] as? Bool, true)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }

    func testMedicationItem_Codable_Default() {
        let json = """
        {
            "identifier": "Ibuprofen"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAMedicationItem.self, from: json)
            
            XCTAssertEqual(object.identifier, "Ibuprofen")
            XCTAssertEqual(object.text, "Ibuprofen")
            XCTAssertNil(object.sectionIdentifier)
            XCTAssertNil(object.title)
            XCTAssertNil(object.shortText)
            XCTAssertNil(object.detail)
            XCTAssertFalse(object.isExclusive)
            XCTAssertNil(object.icon)
            XCTAssertNil(object.isContinuousInjection)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedicationAnswer_Codable() {
        let json = """
        {
            "identifier": "ibuprofen",
            "dosage": "10/100 mg",
            "scheduleItems" : [ { "daysOfWeek": [1,3,5], "timeOfDay" : "8:00" }],
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(SBAMedicationAnswer.self, from: json)
            
            XCTAssertEqual(object.identifier, "ibuprofen")
            XCTAssertEqual(object.dosage, "10/100 mg")
            XCTAssertEqual(object.scheduleItems?.count, 1)
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "ibuprofen")
            XCTAssertEqual(dictionary["dosage"] as? String, "10/100 mg")
            if let items = dictionary["scheduleItems"] as? [[String : Any]] {
                XCTAssertEqual(items.count, 1)
            } else {
                XCTFail("Failed to encode the scheduled items")
            }

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedicationAnswer_Codable_Default() {
        let json = """
        {
            "identifier": "ibuprofen",
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAMedicationAnswer.self, from: json)
            
            XCTAssertEqual(object.identifier, "ibuprofen")
            XCTAssertNil(object.dosage)
            XCTAssertNil(object.scheduleItems)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTrackedItemsStepNavigator_Codable() {
        
        let json = """
        {
            "identifier":"Test",
            "items": [
                        { "identifier": "itemA1", "sectionIdentifier" : "a" },
                        { "identifier": "itemA2", "sectionIdentifier" : "a" },
                        { "identifier": "itemB1", "sectionIdentifier" : "b" },
                        { "identifier": "itemB2", "sectionIdentifier" : "b" },
                        { "identifier": "itemC1", "sectionIdentifier" : "c" }
                    ],
            "sections": [{ "identifier": "a" }, { "identifier": "b" }, { "identifier": "c" }]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBATrackedItemsStepNavigator.self, from: json)
            XCTAssertEqual(object.items.count, 5)
            XCTAssertEqual(object.sections?.count ?? 0, 3)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedicationTrackingStepNavigator_Codable() {
        
        let json = """
        {
            "identifier":"Test",
            "items": [
                        { "identifier": "itemA1", "sectionIdentifier" : "a" },
                        { "identifier": "itemA2", "sectionIdentifier" : "a" },
                        { "identifier": "itemB1", "sectionIdentifier" : "b" },
                        { "identifier": "itemB2", "sectionIdentifier" : "b" },
                        { "identifier": "itemC1", "sectionIdentifier" : "c" }
                    ],
            "sections": [{ "identifier": "a" }, { "identifier": "b" }, { "identifier": "c" }]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAMedicationTrackingStepNavigator.self, from: json)
            XCTAssertEqual(object.items.count, 5)
            XCTAssertEqual(object.sections?.count ?? 0, 3)
            XCTAssertNotNil(object.items as? [SBAMedicationItem])
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTriggerTrackingStepNavigator_Codable() {
        
        let json = """
            {
                "identifier": "logging",
                "type" : "tracking",
                "items": [
                            { "identifier": "itemA1", "sectionIdentifier" : "a" },
                            { "identifier": "itemA2", "sectionIdentifier" : "a" },
                            { "identifier": "itemA3", "sectionIdentifier" : "a" },
                            { "identifier": "itemB1", "sectionIdentifier" : "b" },
                            { "identifier": "itemB2", "sectionIdentifier" : "b" },
                            { "identifier": "itemC1", "sectionIdentifier" : "c" },
                            { "identifier": "itemC2", "sectionIdentifier" : "c" },
                            { "identifier": "itemC3", "sectionIdentifier" : "c" }
                        ],
                "selection": { "title": "What items would you like to track?",
                                "detail": "Select all that apply",
                                "colorTheme" : { "colorStyle" : { "header" : "darkBackground",
                                                "body" : "darkBackground",
                                                "footer" : "lightBackground" }}
                            },
                "logging": { "title": "Your logged items",
                             "actions": { "addMore": { "type": "default", "buttonTitle" : "Edit Logged Items" }}
                            }
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(RSDTaskObject.self, from: json)
            XCTAssertEqual(object.identifier, "logging")
            guard let navigator = object.stepNavigator as? SBATrackedItemsStepNavigator else {
                XCTFail("Failed to decode the step navigator. Exiting.")
                return
            }
            XCTAssertEqual(navigator.items.count, 8)
            XCTAssertNil(navigator.sections)
            XCTAssertEqual((navigator.selectionStep as? RSDUIStep)?.title, "What items would you like to track?")
            XCTAssertEqual((navigator.selectionStep as? RSDUIStep)?.detail, "Select all that apply")
            if let colorTheme = (navigator.selectionStep as? RSDThemedUIStep)?.colorTheme {
                XCTAssertEqual(colorTheme.colorStyle(for: .footer), .lightBackground)
            } else {
                XCTFail("Failed to decode the color Theme")
            }
            
            XCTAssertEqual((navigator.loggingStep as? RSDUIStep)?.title, "Your logged items")
            XCTAssertEqual((navigator.loggingStep as? RSDUIStepObject)?.actions?[.addMore]?.buttonTitle, "Edit Logged Items")
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    
    func testTrackedSelectionStepObject_Codable() {
        
        let json = """
        {
            "identifier": "foo",
            "type": "instruction",
            "title": "Hello World!",
            "text": "Some text.",
            "detail": "This is a test.",
            "footnote": "This is a footnote.",
            "image": { "type": "fetchable",
                       "imageName": "before"},
            "nextStepIdentifier": "boo",
            "actions": { "goForward": { "type": "default", "buttonTitle" : "Go, Dogs! Go!" },
                         "cancel": { "type": "default", "iconName" : "closeX" },
                         "learnMore": { "type": "webView", 
                                        "iconName" : "infoIcon",
                                        "url" : "fooInfo" }
                        },
            "shouldHideActions": ["goBackward", "skip"],
            "items" : [ {"identifier" : "itemA1", "sectionIdentifier" : "a"},
                        {"identifier" : "itemA2", "sectionIdentifier" : "a"},
                        {"identifier" : "itemA3", "sectionIdentifier" : "a"},
                        {"identifier" : "itemB1", "sectionIdentifier" : "b"},
                        {"identifier" : "itemB2", "sectionIdentifier" : "b"},
                        {"identifier" : "itemB3", "sectionIdentifier" : "b"}],
            "sections" : [ {"identifier" : "a"}, {"identifier" : "b"}]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(SBATrackedSelectionStepObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.title, "Hello World!")
            XCTAssertEqual(object.text, "Some text.")
            XCTAssertEqual(object.detail, "This is a test.")
            XCTAssertEqual(object.footnote, "This is a footnote.")
            XCTAssertEqual((object.imageTheme as? RSDFetchableImageThemeElementObject)?.imageName, "before")
            XCTAssertEqual(object.nextStepIdentifier, "boo")
            
            let goForwardAction = object.action(for: .navigation(.goForward), on: object)
            XCTAssertNotNil(goForwardAction)
            XCTAssertEqual(goForwardAction?.buttonTitle, "Go, Dogs! Go!")
            
            let cancelAction = object.action(for: .navigation(.cancel), on: object)
            XCTAssertNotNil(cancelAction)
            XCTAssertEqual((cancelAction as? RSDUIActionObject)?.iconName, "closeX")
            
            let learnMoreAction = object.action(for: .navigation(.learnMore), on: object)
            XCTAssertNotNil(learnMoreAction)
            XCTAssertEqual((learnMoreAction as? RSDWebViewUIActionObject)?.iconName, "infoIcon")
            XCTAssertEqual((learnMoreAction as? RSDWebViewUIActionObject)?.url, "fooInfo")
            
            XCTAssertTrue(object.shouldHideAction(for: .navigation(.goBackward), on: object) ?? false)
            
            XCTAssertEqual(object.items.count, 6)
            XCTAssertEqual(object.sections?.count ?? 0, 2)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTriggersJSON() {
        let resourceTransformer = RSDResourceTransformerObject(resourceName: "Triggers")
        do {
            let task = try testFactory.decodeTask(with: resourceTransformer)
            guard let navigator = task.stepNavigator as? SBATrackedItemsStepNavigator else {
                XCTFail("Failed to decode expected navigator.")
                return
            }
            
            let selectionStep = navigator.selectionStep
            XCTAssertEqual((selectionStep as? RSDUIStep)?.title, "What triggers would you like to track?")
            XCTAssertEqual((selectionStep as? RSDUIStep)?.detail, "Select all that apply")
            
            let loggingStep = navigator.loggingStep as? SBATrackedItemsLoggingStepObject
            XCTAssertNotNil(navigator.loggingStep)
            XCTAssertNotNil(loggingStep)
            XCTAssertEqual(loggingStep?.title, "Your triggers")
            XCTAssertEqual(loggingStep?.actions?[.addMore]?.buttonTitle, "Edit triggers")

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testSymptomsJSON() {
        let resourceTransformer = RSDResourceTransformerObject(resourceName: "Symptoms")
        do {
            let task = try testFactory.decodeTask(with: resourceTransformer)
            guard let navigator = task.stepNavigator as? SBATrackedItemsStepNavigator else {
                XCTFail("Failed to decode expected navigator.")
                return
            }
            
            let selectionStep = navigator.selectionStep
            XCTAssertEqual((selectionStep as? RSDUIStep)?.title, "What are your Parkinson’s Disease symptoms?")
            XCTAssertEqual((selectionStep as? RSDUIStep)?.detail, "Select all that apply")
            
            let loggingStep = navigator.loggingStep as? SBASymptomLoggingStepObject
            XCTAssertNotNil(navigator.loggingStep)
            XCTAssertNotNil(loggingStep)
            XCTAssertEqual(loggingStep?.title, "Today’s symptoms")
            XCTAssertEqual(loggingStep?.actions?[.addMore]?.buttonTitle, "Edit symptoms")
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
}
