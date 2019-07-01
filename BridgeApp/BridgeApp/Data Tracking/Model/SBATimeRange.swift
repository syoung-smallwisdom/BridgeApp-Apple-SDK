//
//  SBATimeRange.swift
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


/// A time range is a set of groupings used in scheduling to group a time into morning, afternoon, evening, and night.
public enum SBATimeRange : String, Codable, CaseIterable {
    case morning, afternoon, evening, night
    
    private static let _hours: [SBATimeRange : Array<Int>] = [
        .morning: Array(5..<12),
        .afternoon: Array(12..<17),
        .evening: Array(17..<22),
        .night: Array(22..<24) + Array(0..<5)]
    
    /// An ordered set of the hours included in this time range.
    public var hours: Array<Int> {
        return SBATimeRange._hours[self]!
    }
    
    /// Initialize by returning the time range for the given hour.
    public init?(hour: Int) {
        guard let kv = SBATimeRange._hours.first(where: { $0.value.contains(hour) }) else { return nil }
        self = kv.key
    }
    
    /// Return a sorted list of times at the given intervals to include for this time range.
    public func times(at minuteInterval: Int) -> [[SBATime]] {
        guard 60 % minuteInterval == 0 else {
            assertionFailure("Not a valid minute interval")
            return []
        }
        let mod = 60 / minuteInterval
        let times = self.hours.map ({ (hour) -> [SBATime] in
            return Array(0..<mod).map { SBATime(hour: hour, minute: $0*minuteInterval) }
        })
        return times
    }
    
    /// Using the time ranges and comparing with a "day" starting at the morning time,
    /// compare the date components and return which is "earlier" in the day.
    ///
    /// - parameters:
    ///     - lhs: The left side of the comparison.
    ///     - rhs: The right side of the comparison.
    /// - returns: `true` if the left time is earlier than the right time where the earliest time is "morning".
    public static func lessThan(_ lhs: DateComponents, _ rhs: DateComponents) -> Bool {
        guard let lHour = lhs.hour, let lRange = SBATimeRange(hour: lHour),
            let rHour = rhs.hour, let rRange = SBATimeRange(hour: rHour)
            else {
                return false
        }
        if lRange != rRange {
            return lRange < rRange
        }
        else if lHour != rHour,
            let leftIndex = lRange.hours.firstIndex(of: lHour),
            let rightIndex = rRange.hours.firstIndex(of: rHour) {
            return leftIndex < rightIndex
        }
        else if let lMinute = lhs.minute, let rMinute = rhs.minute {
            return lMinute < rMinute
        }
        else {
            return false
        }
    }
}

extension SBATimeRange : Comparable {
    public static func < (lhs: SBATimeRange, rhs: SBATimeRange) -> Bool {
        return SBATimeRange.allCases.firstIndex(of: lhs)! < SBATimeRange.allCases.firstIndex(of: rhs)!
    }
}


/// `SBATime` is a simple object used to hold time schedule information.
public struct SBATime: Hashable, Codable, RSDScheduleTime {
    
    public let timeOfDay: String
    
    public var timeOfDayString: String? {
        return timeOfDay
    }
    
    public init(timeOfDay: String) {
        self.timeOfDay = timeOfDay
    }
    
    public init(hour: Int, minute: Int) {
        guard hour >= 0, hour < 24, minute >= 0, minute < 60
            else {
                assertionFailure("Not a valid hour \(hour) or minute \(minute)")
                self.timeOfDay = "00:00"
                return
        }
        self.timeOfDay = String(format: "%02d:%02d", hour, minute)
    }
}

extension SBATime: Comparable {
    public static func < (lhs: SBATime, rhs: SBATime) -> Bool {
        guard let ltc = lhs.timeComponents, let rtc = rhs.timeComponents else { return false }
        return SBATimeRange.lessThan(ltc, rtc)
    }
}
