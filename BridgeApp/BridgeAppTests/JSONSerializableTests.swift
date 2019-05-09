//
//  JSONSerializableTests.swift
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
import BridgeApp

class JSONSerializableTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testString() {
        let obj = "foo"
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? String, "foo")
        let jsonData = clientData.toJSONSerializable()
        XCTAssertEqual(jsonData as? String, "foo")
    }

    func testArray() {
        let array: NSArray = [["identifier":"foo", "value":3], ["identifier":"goo", "value":4]]
        let json = array.jsonObject()
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? NSArray, array)
        let jsonData = clientData.toJSONSerializable()
        XCTAssertEqual(jsonData as? NSArray, array)
    }

    func testDictionary() {
        let dictionary: NSDictionary = ["one": ["identifier":"foo", "value":3], "two": ["identifier":"goo", "value":4], "three": 3]
        let json = dictionary.jsonObject()
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? NSDictionary, dictionary)
        let jsonData = clientData.toJSONSerializable()
        XCTAssertEqual(jsonData as? NSDictionary, dictionary)
    }

    func testNSNumber() {
        let obj: NSNumber = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? NSNumber, 3)
        let jsonData = clientData.toJSONSerializable()
        XCTAssertEqual(jsonData as? NSNumber, 3)
    }

    func testInt() {
        let obj: Int = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? Int, 3)
    }

    func testInt8() {
        let obj: Int8 = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? Int8, 3)
    }

    func testInt16() {
        let obj: Int16 = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? Int16, 3)
    }
    
    func testInt32() {
        let obj: Int32 = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? Int32, 3)
    }

    func testInt64() {
        let obj: Int64 = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? Int64, 3)
    }
    
    func testUInt() {
        let obj: UInt = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? UInt, 3)
    }
    
    func testUInt8() {
        let obj: UInt8 = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? UInt8, 3)
    }
    
    func testUInt16() {
        let obj: UInt16 = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? UInt16, 3)
    }
    
    func testUInt32() {
        let obj: UInt32 = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? UInt32, 3)
    }
    
    func testUInt64() {
        let obj: UInt64 = 3
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? UInt64, 3)
    }

    func testBool() {
        let obj: Bool = true
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? Bool, true)
    }

    func testDouble() {
        let obj: Double = 3.2
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? Double, 3.2)
    }

    func testFloat() {
        let obj: Float = 3.2
        let json = obj as RSDJSONSerializable
        let clientData = json.toClientData()
        XCTAssertEqual(clientData as? Float, 3.2)
    }
}
