//
//  ActivityReferenceTests.swift
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
import Research
@testable import BridgeApp

let testFactory: RSDFactory = {
    RSDFactory.shared = SBAFactory()
    return RSDFactory.shared
}()

var decoder: JSONDecoder {
    return testFactory.createJSONDecoder()
}

var encoder: JSONEncoder {
    return testFactory.createJSONEncoder()
}

class ActivityReferenceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: Codable tests
    
    func testAppConfig_Setup() {
        
        let schemaRefFoo = SBBSchemaReference(dictionaryRepresentation:
            ["id" : "foo",
             "activityDescription" : "This is the activity description",
             "revision" : NSNumber(value: 3)])!
        
        let schemaRefGoo = SBBSchemaReference(dictionaryRepresentation:
            ["id" : "goo",
             "activityDescription" : "This is the activity description",
             "revision" : NSNumber(value: 2)])!
        
        let schemaRefC = SBBSchemaReference(dictionaryRepresentation:
            ["id" : "taskC",
             "activityDescription" : "This is the activity description",
             "revision" : NSNumber(value: 5)])!
        
        let clientData: [String : Any] = [
            "studyDuration" : ["month":3],
            "groups": [
                [
                    "identifier" : "group1",
                    "activityIdentifiers": ["taskA", "taskB", "taskC"]
                ],
                [
                    "identifier" : "group2",
                    "activityIdentifiers": ["taskC", "taskD", "taskF"]
                ],
                ],
            "activityList": [  ["identifier" : "taskA"],
                               ["identifier" : "taskC"],
                               ["identifier" : "taskD"]],
            "tasks": [ ["identifier" : "taskF", "steps":[] ]],
            "taskToSchemaIdentifierMap": [
                "taskA": "foo",
                "taskF": "goo"
            ]
        ]
        
        let appConfig = SBBAppConfig(dictionaryRepresentation:
            ["clientData": clientData
            ])!
        appConfig.addSchemaReferencesObject(schemaRefFoo)
        appConfig.addSchemaReferencesObject(schemaRefGoo)
        appConfig.addSchemaReferencesObject(schemaRefC)

        let config = SBABridgeConfiguration()
        config.setup(with: appConfig)
        
        XCTAssertEqual(config.studyDuration.month, 3)
        
        let group1 = config.activityGroup(with: "group1")
        XCTAssertNotNil(group1)
        let expectedIds = ["taskA", "taskB", "taskC"].map { RSDIdentifier(rawValue: $0) }
        XCTAssertEqual(group1?.activityIdentifiers, expectedIds)
        
        let group2 = config.activityGroup(with: "group2")
        XCTAssertNotNil(group2)
        
        let taskInfoA = config.activityInfo(for: "taskA")
        XCTAssertNotNil(taskInfoA)
        let schemaA = config.schemaInfo(for: "taskA")
        XCTAssertNotNil(schemaA)
        XCTAssertEqual(schemaA?.schemaIdentifier, "foo")
        
        let taskInfoC = config.activityInfo(for: "taskC")
        XCTAssertNotNil(taskInfoC)
        let schemaC = config.schemaInfo(for: "taskC")
        XCTAssertNotNil(schemaC)
        XCTAssertEqual(schemaC?.schemaIdentifier, "taskC")
        XCTAssertEqual(schemaC?.schemaVersion, 5)
        
        let taskInfoF = config.activityInfo(for: "taskF")
        XCTAssertNotNil(taskInfoF)
        let schemaF = config.schemaInfo(for: "taskF")
        XCTAssertNotNil(schemaF)
        XCTAssertEqual(schemaF?.schemaIdentifier, "goo")
    }
    
    func testActivityInfo_Codable_ModuleId() {
        
        let json = """
        {
            "identifier": "foo",
            "title": "Title",
            "subtitle": "Subtitle",
            "detail": "A detail about the object",
            "imageSource": "fooImage",
            "minuteDuration": 10,
            "moduleId": "tapping"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAActivityInfoObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.title, "Title")
            XCTAssertEqual(object.subtitle, "Subtitle")
            XCTAssertEqual(object.detail, "A detail about the object")
            XCTAssertEqual(object.imageSource?.imageName, "fooImage")
            XCTAssertEqual(object.estimatedMinutes, 10)
            XCTAssertEqual(object.moduleId?.stringValue, "tapping")
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testActivityInfo_Codable_Resource() {
        
        let json = """
        {
            "identifier": "foo",
            "title": "Title",
            "subtitle": "Subtitle",
            "detail": "A detail about the object",
            "imageSource": "fooImage",
            "minuteDuration": 10,
            "resource": {   "resourceName" : "Foo_Task",
                            "bundleIdentifier" : "org.example.Foo"
                        }
        }
        """.data(using: .utf8)! // our data in native (JSON) format

        do {
            let object = try decoder.decode(SBAActivityInfoObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.title, "Title")
            XCTAssertEqual(object.subtitle, "Subtitle")
            XCTAssertEqual(object.detail, "A detail about the object")
            XCTAssertEqual(object.imageSource?.imageName, "fooImage")
            XCTAssertEqual(object.estimatedMinutes, 10)
            XCTAssertEqual(object.resource?.resourceName, "Foo_Task")
            XCTAssertEqual(object.resource?.bundleIdentifier, "org.example.Foo")

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testActivityInfo_Codable_Default() {
        
        // Test that decoding a default object without any nullable proprties doesn't fail.
        let json = """
        {
            "identifier": "foo",
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            // Test that decoding a dictionary with none of the values set doesn't fail.
            let _ = try decoder.decode(SBAActivityInfoObject.self, from: json)
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testActivityGroup_Codable() {
        
        let json = """
        {
            "identifier": "foo",
            "title": "Title",
            "journeyTitle": "Journey title",
            "detail": "A detail about the object",
            "imageSource": "fooImage",
            "activityIdentifiers": ["boo", "bar", "goo"],
            "notificationIdentifier": "scheduleFoo",
            "schedulePlanGuid": "abcdef12-3456-7890"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAActivityGroupObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.title, "Title")
            XCTAssertEqual(object.journeyTitle, "Journey title")
            XCTAssertEqual(object.detail, "A detail about the object")
            XCTAssertEqual(object.imageSource?.imageName, "fooImage")
            let expectedIdentifiers: [RSDIdentifier] = ["boo", "bar", "goo"]
            XCTAssertEqual(object.activityIdentifiers, expectedIdentifiers)
            XCTAssertEqual(object.notificationIdentifier, "scheduleFoo")
            XCTAssertEqual(object.schedulePlanGuid, "abcdef12-3456-7890")
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testActivityGroup2_Codable() {
        
    let json = """
            {
                "identifier": "foo",
                "title": "Title",
                "journeyTitle": "Journey title",
                "detail": "A detail about the object",
                "imageSource": "fooImage",
                "activityIdentifiers": ["taskA", "taskB", "taskC"],
                "notificationIdentifier": "scheduleFoo",
                "activityGuidMap": {
                                     "taskA":"ababab12-3456-7890",
                                     "taskB":"cdcdcd12-3456-7890",
                                     "taskC":"efefef12-3456-7890"
                                     }
            }
            """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAActivityGroupObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.title, "Title")
            XCTAssertEqual(object.journeyTitle, "Journey title")
            XCTAssertEqual(object.detail, "A detail about the object")
            XCTAssertEqual(object.imageSource?.imageName, "fooImage")
            let expectedIdentifiers: [RSDIdentifier] = ["taskA", "taskB", "taskC"]
            XCTAssertEqual(object.activityIdentifiers, expectedIdentifiers)
            XCTAssertEqual(object.notificationIdentifier, "scheduleFoo")
            let expectedMap = [
                "taskA":"ababab12-3456-7890",
                "taskB":"cdcdcd12-3456-7890",
                "taskC":"efefef12-3456-7890"
            ]
            XCTAssertEqual(object.activityGuidMap, expectedMap)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testActivityGroup_Codable_Default() {
        
        // Test that decoding a default object without any nullable proprties doesn't fail.
        let json = """
        {
            "identifier": "foo",
            "activityIdentifiers": ["boo", "bar", "goo"]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let _ = try decoder.decode(SBAActivityGroupObject.self, from: json)
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }

    func testActivityMapping_Codable() {
        let json = """
        {
            "groups": [{   "identifier" : "group1",
                            "activityIdentifiers": ["taskA", "taskB", "taskC"]
                        },
                        {   "identifier" : "group2",
                            "activityIdentifiers": ["taskC", "taskD", "taskE"]
                        }],
            "activityList": [  {"identifier" : "taskA"},
                                {"identifier" : "taskB"},
                                {"identifier" : "taskC"},
                                {"identifier" : "taskD"},
                                {"identifier" : "taskE"}],
            "tasks": [ {"identifier" : "taskA", "steps":[] }]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
    
        do {
            let object = try decoder.decode(SBAActivityMappingObject.self, from: json)
            
            let expectedGroupIds = ["group1", "group2"]
            let groupIds = object.groups?.map { $0.identifier } ?? []
            XCTAssertEqual(groupIds, expectedGroupIds)
            
            let expectedActivityIds = ["taskA", "taskB", "taskC", "taskD", "taskE"]
            let activityIds = object.activityList?.map { $0.identifier } ?? []
            XCTAssertEqual(activityIds, expectedActivityIds)
            
            let expectedTaskIds = ["taskA"]
            let taskIds = object.tasks?.map { $0.identifier } ?? []
            XCTAssertEqual(taskIds, expectedTaskIds)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    // MARK: SBASingleActivityReference
    
    func testSBBSchemaReference() {
        
        let ref = SBBSchemaReference(dictionaryRepresentation: ["id" : "foo",
                                                                "activityDescription" : "This is the activity description",
                                                                "minuteDuration" : NSNumber(value: 5),
                                                                "revision" : NSNumber(value: 3)])!
        
        let activityInfo = SBAActivityInfoObject(identifier: "foo", title: "Title", subtitle: "Subtitle", detail: "Detail", estimatedMinutes: 0, iconImage: nil, resource: nil, moduleId: "tapping")
        SBABridgeConfiguration.shared.addMapping(with: activityInfo)
        
        XCTAssertEqual(ref.identifier, "foo")
        XCTAssertEqual(ref.title, "Title")
        XCTAssertEqual(ref.subtitle, "Subtitle")
        XCTAssertEqual(ref.detail, "This is the activity description")
        XCTAssertEqual(ref.estimatedMinutes, 5)
        
        XCTAssertEqual(ref.schemaInfo?.schemaIdentifier, "foo")
        XCTAssertEqual(ref.schemaInfo?.schemaVersion, 3)
    }
    
    func testSBBTaskReference() {
        
        let ref = SBBTaskReference(dictionaryRepresentation: [  "identifier" : "foo",
                                                                "activityDescription" : "This is the activity description",
                                                                "minuteDuration" : NSNumber(value: 5)])!
        
        let schema = SBBSchemaReference(dictionaryRepresentation: ["id" : "foo",
                                                                      "revision" : NSNumber(value: 3)])!
        SBABridgeConfiguration.shared.addMapping(with: schema)

        let activityInfo = SBAActivityInfoObject(identifier: "foo", title: "Title", subtitle: "Subtitle", detail: "Detail", estimatedMinutes: 0, iconImage: nil, resource: nil, moduleId: "tapping")
        SBABridgeConfiguration.shared.addMapping(with: activityInfo)
        
        XCTAssertEqual(ref.identifier, "foo")
        XCTAssertEqual(ref.title, "Title")
        XCTAssertEqual(ref.subtitle, "Subtitle")
        XCTAssertEqual(ref.detail, "This is the activity description")
        XCTAssertEqual(ref.estimatedMinutes, 5)
        
        XCTAssertEqual(ref.schemaInfo?.schemaIdentifier, "foo")
        XCTAssertEqual(ref.schemaInfo?.schemaVersion, 3)
    }
    
    func testSBBSurveyReference() {
        
        let ref = SBBSurveyReference(dictionaryRepresentation: [  "identifier" : "foo",
                                                                "activityDescription" : "This is the activity description",
                                                                "minuteDuration" : NSNumber(value: 5)])!
    
        let activityInfo = SBAActivityInfoObject(identifier: "foo", title: "Title", subtitle: "Subtitle", detail: "Detail", estimatedMinutes: 0, iconImage: nil, resource: nil, moduleId: "tapping")
        SBABridgeConfiguration.shared.addMapping(with: activityInfo)
        
        XCTAssertEqual(ref.identifier, "foo")
        XCTAssertEqual(ref.title, "Title")
        XCTAssertEqual(ref.subtitle, "Subtitle")
        XCTAssertEqual(ref.detail, "This is the activity description")
        XCTAssertEqual(ref.estimatedMinutes, 5)
        
        XCTAssertNil(ref.schemaInfo)
    }
    
    func testSBBSchemaReference_Shared() {
        
        let ref = SBBSchemaReference(dictionaryRepresentation: ["id" : "foo",
                                                                "revision" : NSNumber(value: 3)])!
        
        let activityInfo = SBAActivityInfoObject(identifier: "foo", title: "Title", subtitle: "Subtitle", detail: "Detail", estimatedMinutes: 5, iconImage: nil, resource: nil, moduleId: "tapping")
        SBABridgeConfiguration.shared.addMapping(with: activityInfo)
        
        XCTAssertEqual(ref.identifier, "foo")
        XCTAssertEqual(ref.title, "Title")
        XCTAssertEqual(ref.subtitle, "Subtitle")
        XCTAssertEqual(ref.detail, "Detail")
        XCTAssertEqual(ref.estimatedMinutes, 5)
    }
    
    func testSBBTaskReference_Shared() {
        
        let ref = SBBTaskReference(dictionaryRepresentation: [  "identifier" : "foo" ])!
        
        let activityInfo = SBAActivityInfoObject(identifier: "foo", title: "Title", subtitle: "Subtitle", detail: "Detail", estimatedMinutes: 5, iconImage: nil, resource: nil, moduleId: "tapping")
        SBABridgeConfiguration.shared.addMapping(with: activityInfo)
        
        XCTAssertEqual(ref.identifier, "foo")
        XCTAssertEqual(ref.title, "Title")
        XCTAssertEqual(ref.subtitle, "Subtitle")
        XCTAssertEqual(ref.detail, "Detail")
        XCTAssertEqual(ref.estimatedMinutes, 5)
    }
    
    func testSBBSurveyReference_Shared() {
        
        let ref = SBBSurveyReference(dictionaryRepresentation: [  "identifier" : "foo" ])!
        
        let activityInfo = SBAActivityInfoObject(identifier: "foo", title: "Title", subtitle: "Subtitle", detail: "Detail", estimatedMinutes: 5, iconImage: nil, resource: nil, moduleId: "tapping")
        SBABridgeConfiguration.shared.addMapping(with: activityInfo)
        
        XCTAssertEqual(ref.identifier, "foo")
        XCTAssertEqual(ref.title, "Title")
        XCTAssertEqual(ref.subtitle, "Subtitle")
        XCTAssertEqual(ref.detail, "Detail")
        XCTAssertEqual(ref.estimatedMinutes, 5)
    }
    
    func testCompoundActivity_HasSurveyAndSchema() {
        
        let compoundRef = SBBCompoundActivity(dictionaryRepresentation: [  "taskIdentifier" : "foo" ])!
        
        let surveyRef1 = SBBSurveyReference(dictionaryRepresentation: [  "identifier" : "survey1",
                                                                         "minuteDuration" : NSNumber(value: 5)])!
        let surveyRef2 = SBBSurveyReference(dictionaryRepresentation: [  "identifier" : "survey2",
                                                                         "minuteDuration" : NSNumber(value: 8)])!
        compoundRef.addSurveyListObject(surveyRef1)
        compoundRef.addSurveyListObject(surveyRef2)

        let schemaRef1 = SBBSchemaReference(dictionaryRepresentation: [  "id" : "schema1",
                                                                         "minuteDuration" : NSNumber(value: 2)])!
        let schemaRef2 = SBBSchemaReference(dictionaryRepresentation: [  "id" : "schema2",
                                                                         "minuteDuration" : NSNumber(value: 10)])!
        compoundRef.addSchemaListObject(schemaRef1)
        compoundRef.addSchemaListObject(schemaRef2)
        
        XCTAssertEqual(compoundRef.identifier, "foo")
        XCTAssertEqual(compoundRef.estimatedMinutes, 25)
        
        XCTAssertEqual(compoundRef.step(with: "survey1") as? SBBSurveyReference, surveyRef1)
        XCTAssertEqual(compoundRef.step(with: "survey2") as? SBBSurveyReference, surveyRef2)
        XCTAssertEqual(compoundRef.step(with: "schema1") as? SBBSchemaReference, schemaRef1)
        XCTAssertEqual(compoundRef.step(with: "schema2") as? SBBSchemaReference, schemaRef2)

        var taskResult = compoundRef.instantiateTaskResult()
        XCTAssertTrue(compoundRef.hasStep(after: nil, with: taskResult))
        XCTAssertTrue(compoundRef.hasStep(after: surveyRef1, with: taskResult))
        XCTAssertTrue(compoundRef.hasStep(after: surveyRef2, with: taskResult))
        XCTAssertTrue(compoundRef.hasStep(after: schemaRef1, with: taskResult))
        XCTAssertFalse(compoundRef.hasStep(after: schemaRef2, with: taskResult))
        
        XCTAssertFalse(compoundRef.hasStep(before: surveyRef1, with: taskResult))
        XCTAssertTrue(compoundRef.hasStep(before: surveyRef2, with: taskResult))
        XCTAssertTrue(compoundRef.hasStep(before: schemaRef1, with: taskResult))
        XCTAssertTrue(compoundRef.hasStep(before: schemaRef2, with: taskResult))

        XCTAssertEqual(compoundRef.step(after: nil, with: &taskResult).step as? SBBBridgeObject, surveyRef1)
        XCTAssertEqual(compoundRef.step(after: surveyRef1, with: &taskResult).step as? SBBBridgeObject, surveyRef2)
        XCTAssertEqual(compoundRef.step(after: surveyRef2, with: &taskResult).step as? SBBBridgeObject, schemaRef1)
        XCTAssertEqual(compoundRef.step(after: schemaRef1, with: &taskResult).step as? SBBBridgeObject, schemaRef2)
        XCTAssertNil(compoundRef.step(after: schemaRef2, with: &taskResult).step)
        
        XCTAssertEqual(compoundRef.step(before: schemaRef2, with: &taskResult) as? SBBBridgeObject, schemaRef1)
        XCTAssertEqual(compoundRef.step(before: schemaRef1, with: &taskResult) as? SBBBridgeObject, surveyRef2)
        XCTAssertEqual(compoundRef.step(before: surveyRef2, with: &taskResult) as? SBBBridgeObject, surveyRef1)
        XCTAssertNil(compoundRef.step(before: surveyRef1, with: &taskResult))
        
        XCTAssertEqual(compoundRef.progress(for: surveyRef1, with: taskResult)?.current, 1)
        XCTAssertEqual(compoundRef.progress(for: surveyRef2, with: taskResult)?.current, 2)
        XCTAssertEqual(compoundRef.progress(for: schemaRef1, with: taskResult)?.current, 3)
        XCTAssertEqual(compoundRef.progress(for: schemaRef2, with: taskResult)?.current, 4)
    }
    
    func testCompoundActivity_SurveyOnly() {
        
        let compoundRef = SBBCompoundActivity(dictionaryRepresentation: [  "taskIdentifier" : "foo" ])!
        
        let surveyRef1 = SBBSurveyReference(dictionaryRepresentation: [  "identifier" : "survey1",
                                                                         "minuteDuration" : NSNumber(value: 5)])!
        let surveyRef2 = SBBSurveyReference(dictionaryRepresentation: [  "identifier" : "survey2",
                                                                         "minuteDuration" : NSNumber(value: 8)])!
        compoundRef.addSurveyListObject(surveyRef1)
        compoundRef.addSurveyListObject(surveyRef2)
        
        XCTAssertEqual(compoundRef.identifier, "foo")
        XCTAssertEqual(compoundRef.estimatedMinutes, 13)
        
        XCTAssertEqual(compoundRef.step(with: "survey1") as? SBBSurveyReference, surveyRef1)
        XCTAssertEqual(compoundRef.step(with: "survey2") as? SBBSurveyReference, surveyRef2)
        
        var taskResult = compoundRef.instantiateTaskResult()
        XCTAssertTrue(compoundRef.hasStep(after: nil, with: taskResult))
        XCTAssertTrue(compoundRef.hasStep(after: surveyRef1, with: taskResult))
        XCTAssertFalse(compoundRef.hasStep(after: surveyRef2, with: taskResult))

        XCTAssertFalse(compoundRef.hasStep(before: surveyRef1, with: taskResult))
        XCTAssertTrue(compoundRef.hasStep(before: surveyRef2, with: taskResult))
        
        XCTAssertEqual(compoundRef.step(after: nil, with: &taskResult).step as? SBBBridgeObject, surveyRef1)
        XCTAssertEqual(compoundRef.step(after: surveyRef1, with: &taskResult).step as? SBBBridgeObject, surveyRef2)
        XCTAssertNil(compoundRef.step(after: surveyRef2, with: &taskResult).step)
        
        XCTAssertEqual(compoundRef.step(before: surveyRef2, with: &taskResult) as? SBBBridgeObject, surveyRef1)
        XCTAssertNil(compoundRef.step(before: surveyRef1, with: &taskResult))
        
        XCTAssertEqual(compoundRef.progress(for: surveyRef1, with: taskResult)?.current, 1)
        XCTAssertEqual(compoundRef.progress(for: surveyRef2, with: taskResult)?.current, 2)
    }
    
    func testCompoundActivity_SchemaOnly() {
        
        let compoundRef = SBBCompoundActivity(dictionaryRepresentation: [  "taskIdentifier" : "foo" ])!
        
        let schemaRef1 = SBBSchemaReference(dictionaryRepresentation: [  "id" : "schema1",
                                                                         "minuteDuration" : NSNumber(value: 2)])!
        let schemaRef2 = SBBSchemaReference(dictionaryRepresentation: [  "id" : "schema2",
                                                                         "minuteDuration" : NSNumber(value: 10)])!
        compoundRef.addSchemaListObject(schemaRef1)
        compoundRef.addSchemaListObject(schemaRef2)
        
        XCTAssertEqual(compoundRef.identifier, "foo")
        XCTAssertEqual(compoundRef.estimatedMinutes, 12)
        
        XCTAssertEqual(compoundRef.step(with: "schema1") as? SBBSchemaReference, schemaRef1)
        XCTAssertEqual(compoundRef.step(with: "schema2") as? SBBSchemaReference, schemaRef2)
        
        var taskResult = compoundRef.instantiateTaskResult()
        XCTAssertTrue(compoundRef.hasStep(after: nil, with: taskResult))
        XCTAssertTrue(compoundRef.hasStep(after: schemaRef1, with: taskResult))
        XCTAssertFalse(compoundRef.hasStep(after: schemaRef2, with: taskResult))
        
        XCTAssertFalse(compoundRef.hasStep(before: schemaRef1, with: taskResult))
        XCTAssertTrue(compoundRef.hasStep(before: schemaRef2, with: taskResult))
        
        XCTAssertEqual(compoundRef.step(after: nil, with: &taskResult).step as? SBBBridgeObject, schemaRef1)
        XCTAssertEqual(compoundRef.step(after: schemaRef1, with: &taskResult).step as? SBBBridgeObject, schemaRef2)
        XCTAssertNil(compoundRef.step(after: schemaRef2, with: &taskResult).step)
        
        XCTAssertEqual(compoundRef.step(before: schemaRef2, with: &taskResult) as? SBBBridgeObject, schemaRef1)
        XCTAssertNil(compoundRef.step(before: schemaRef1, with: &taskResult))
        
        XCTAssertEqual(compoundRef.progress(for: schemaRef1, with: taskResult)?.current, 1)
        XCTAssertEqual(compoundRef.progress(for: schemaRef2, with: taskResult)?.current, 2)
    }
}
