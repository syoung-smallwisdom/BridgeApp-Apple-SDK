//
//  SBBScheduledActivity+Utilities.swift
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


extension SBBScheduledActivity {
    
    /// Is the scheduled activity completed?
    public var isCompleted: Bool {
        return self.finishedOn != nil
    }
    
    /// Is the scheduled activity expired?
    public var isExpired: Bool {
        return (self.expiresOn != nil) && ((Date() as NSDate).earlierDate(self.expiresOn!) == self.expiresOn)
    }
    
    /// Is the scheduled activity available now? This is different from whether or not the activity is
    /// available *today*. Instead, the activity is available now if it is *not* completed and the scheduled
    /// window of time is currently active.
    ///
    /// For example, if the local time is 5:00pm, then the schedule with a window of 1:00pm - 2:00pm will
    /// return `false` and a schedule with a window of 4:00pm - 6:00pm will return `true`.
    public var isNow: Bool {
        return !isCompleted && ((self.scheduledOn.timeIntervalSinceNow < 0) && !isExpired)
    }
    
    /// Is the schedule available at some time today?
    public var isToday: Bool {
        return SBBScheduledActivity.availableTodayPredicate().evaluate(with: self)
    }
    
    /// Localized string for the currently scheduled time. This can be used to display the time window
    /// during which a schedule is available.
    public var scheduledTime: String {
        if isCompleted {
            return ""
        } else if isNow {
            return Localization.localizedString("TIME_NOW")
        } else {
            return DateFormatter.localizedString(from: scheduledOn, dateStyle: .none, timeStyle: .short)
        }
    }
    
    /// Localized string for the expiration time. This can be used to display the time window during
    /// which a schedule is available (if the task expires today) or else to show the date and time when
    /// the schedule expires.
    public var expiresTime: String? {
        guard let expireDate = self.expiresOn else { return nil }
        if expireDate.isToday {
            return DateFormatter.localizedString(from: expireDate, dateStyle: .none, timeStyle: .short)
        } else {
            return DateFormatter.localizedString(from: expireDate, dateStyle: .long, timeStyle: .short)
        }
    }
    
    /// Returns the identifier for the `SBBTaskReference`, `SBBSurveyReference`, or `SBBCompoundActivity`
    /// that is associated with this schedule.
    @objc public dynamic var activityIdentifier: String? {
        return self.activity.identifier
    }
    
    /// The UUID string from the scheduled activity `guid`.
    @objc public dynamic var scheduleIdentifier: String {
        if let range = self.guid.range(of: ":") {
            return String(self.guid[..<range.lowerBound])
        }
        else {
            return self.guid
        }
    }
}
