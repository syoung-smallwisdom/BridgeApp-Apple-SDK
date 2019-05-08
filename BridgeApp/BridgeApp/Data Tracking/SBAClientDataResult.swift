//
//  SBAClientDataResult.swift
//  BridgeApp
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

import Foundation

/// An `SBAClientDataResult` is an archivable result that can also save a clientData scoring object on
/// an associated `SBBScheduledActivity` or `SBBStudyParticipant` object.
///
/// - Deprecated. Use `RSDScoringResult` directly instead
@available(*, deprecated)
public protocol SBAClientDataResult : RSDScoringResult {
    
    /// Build the client data object appropriate to this result.
    func clientData() throws -> SBBJSONValue?
}

// TODO: syoung 05/07/2019 Remove once `SBAClientDataResult` is marked as unavailable.
public extension SBAClientDataResult {
    
    func dataScore() throws -> RSDJSONSerializable? {
        guard let data = try self.clientData() else { return nil }
        if let result = data as? RSDJSONSerializable {
            return result
        }
        else if let result = data as? RSDJSONValue {
            return result.jsonObject()
        }
        else {
            throw RSDValidationError.invalidType("Cannot convert \(data) to a `RSDJSONSerializable` object.")
        }
    }
}

public extension RSDJSONSerializable {
    func toClientData() -> SBBJSONValue {
        guard let data = self as? SBBJSONValue else {
            // Note: syoung 05/07/2019 All implementations of RSDJSONSerializable should be tested so this is
            // unexpected to happen. Nevertheless, if it does happen, only crash in Debug and not in Release.
            assertionFailure("Failed to convert \(self) to SBBJSONValue")
            return NSNull()
        }
        return data
    }
}
