//
//  TimeZone+Utilities.swift
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

extension TimeZone {
    
    /// Parse the TimeZone from an iso8601 string.
    ///
    /// - note: This handles the formats used by both iOS and Android.
    /// Copied from https://stackoverflow.com/a/50384957
    public init?(iso8601: String) {
        if iso8601.hasSuffix("Z") {
            self.init(secondsFromGMT: 0)
            return
        }
        
        guard let zoneStart = iso8601.lastIndex(where: { $0 == "+" }) ?? iso8601.lastIndex(where: { $0 == "-" })
            else {
                return nil
        }
        
        let tz = iso8601[zoneStart...]
        if tz.count == 3 { // assume +/-HH
            if let hour = Int(tz) {
                self.init(secondsFromGMT: hour * 3600)
                return
            }
        } else if tz.count == 5 { // assume +/-HHMM
            if let hour = Int(tz.dropLast(2)), let min = Int(tz.dropFirst(3)) {
                self.init(secondsFromGMT: (hour * 60 + min) * 60)
                return
            }
        } else if tz.count == 6 { // assime +/-HH:MM
            let parts = tz.components(separatedBy: ":")
            if parts.count == 2 {
                if let hour = Int(parts[0]), let min = Int(parts[1]) {
                    self.init(secondsFromGMT: (hour * 60 + min) * 60)
                    return
                }
            }
        }
        return nil
    }
}
