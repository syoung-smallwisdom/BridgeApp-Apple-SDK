//
//  SBATriggerResult.swift
//  BridgeApp (iOS)
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

import Foundation

public struct SBATriggerResult : RSDResult, Codable, RSDScoringResult {
    public let type: RSDResultType = .trigger
    
    private enum CodingKeys : String, CodingKey {
        case identifier, loggedDate, text
    }
    
    public let identifier: String
    
    /// The start date timestamp for the result.
    public var startDate: Date = Date()
    
    /// The end date timestamp for the result.
    public var endDate: Date = Date()
    
    /// The text shown to the user as the title.
    public let text: String
    
    /// The date timestamp for when the item was logged.
    public var loggedDate: Date?
    
    /// Time zone.
    public var timeZone: TimeZone = TimeZone.current
    
    public func dataScore() throws -> RSDJSONSerializable? {
        return try self.rsd_jsonEncodedDictionary().jsonObject()
    }
    
    public func buildArchiveData(at stepPath: String?) throws -> (manifest: RSDFileManifest, data: Data)? {
        // create the manifest and encode the result.
        let manifest = RSDFileManifest(filename: self.identifier, timestamp: self.startDate, contentType: "application/json", identifier: self.identifier, stepPath: stepPath)
        let data = try self.rsd_jsonEncodedData()
        return (manifest, data)
    }
    
    public init(identifier: String, text: String? = nil) {
        self.identifier = identifier
        self.text = text ?? identifier
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(String.self, forKey: .identifier)
        self.identifier = identifier
        let text = try container.decodeIfPresent(String.self, forKey: .text)
        self.text = text ?? identifier
        self.loggedDate = try container.decodeIfPresent(Date.self, forKey: .loggedDate)
        if let iso8601 = try container.decodeIfPresent(String.self, forKey: .loggedDate),
            let timezone = TimeZone(iso8601: iso8601) {
            self.timeZone = timezone
        }
        else {
            self.timeZone = TimeZone.current
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.text, forKey: .text)
        if let loggedDate = self.loggedDate {
            let formatter = encoder.factory.timestampFormatter
            formatter.timeZone = self.timeZone
            let loggingString = formatter.string(from: loggedDate)
            try container.encode(loggingString, forKey: .loggedDate)
        }
    }
}


/// Wrapper for a collection of symptoms as a result.
public struct SBATriggerCollectionResult : Codable, RSDCollectionResult {
    public let type: RSDResultType = .triggerCollection
    
    private enum CodingKeys : String, CodingKey {
        case identifier, type, startDate, endDate, triggerResults = "items"
    }
    
    /// The identifier for the result.
    public let identifier: String
    
    /// The start date timestamp for the result.
    public var startDate: Date = Date()
    
    /// The end date timestamp for the result.
    public var endDate: Date = Date()
    
    /// List of the results.
    public var triggerResults: [SBATriggerResult] = []
    
    /// A wrapper for the codable results.
    public var inputResults: [RSDResult] {
        get {
            return triggerResults
        }
        set {
            triggerResults = newValue.compactMap { $0 as? SBATriggerResult }
        }
    }
    
    public init(identifier: String) {
        self.identifier = identifier
    }
}

