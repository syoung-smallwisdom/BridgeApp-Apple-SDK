//
//  ScheduledAssessment.swift
//  BridgeApp (iOS)
//
//  Copyright © 2020 Sage Bionetworks. All rights reserved.
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

public protocol AssessmentSchedule {
    
    /// A localized string with the label for the timing for when the assessment is available.
    var availabilityLabel: String? { get }
    
    /// The task info associated with this schedule.
    var taskInfo: RSDTaskInfo { get }
    
    /// Is the schedule available now?
    var isAvailableNow: Bool { get }
    
    /// Is this a schedule that is available all day for one day only?
    var isAllDay: Bool { get }
    
    /// Has the available time expired?
    var isExpired: Bool { get }
}

public protocol AssessmentScheduleManager : RSDTaskControllerDelegate {
    var assessmentSchedules: [AssessmentSchedule] { get }
    func reloadData()
    func isCompleted(for taskInfo: RSDTaskInfo, on date: Date) -> Bool
    func instantiateTaskViewModel(for assessmentSchedule: AssessmentSchedule) -> RSDTaskViewModel
}

extension SBAScheduleManager : AssessmentScheduleManager {
    public var assessmentSchedules: [AssessmentSchedule] {
        return self.scheduledActivities
    }
    
    public func instantiateTaskViewModel(for assessmentSchedule: AssessmentSchedule) -> RSDTaskViewModel {
        guard let schedule = assessmentSchedule as? SBBScheduledActivity else {
            fatalError("This schedule manager only supports instantiating a task view model from it's own assessments.")
        }
        return self.instantiateTaskViewModel(for: schedule)
    }
}

extension SBBScheduledActivity : AssessmentSchedule {
    
    public var taskInfo: RSDTaskInfo {
        return self.activity
    }
    
    /// Is this a schedule that is available all day for one day only?
    public var isAllDay: Bool {
        guard let expireDate = self.expiresOn else { return false }
        let startOfDay = scheduledOn.startOfDay()
        return startOfDay == scheduledOn && startOfDay.addingNumberOfDays(1) == expireDate
    }
    
    /// Is the schedule available now?
    public var isAvailableNow: Bool {
        let now = Date()
        if scheduledOn > now { return false }
        else if let expireDate = self.expiresOn { return now < expireDate }
        else { return true }
    }
    
    private var now: Date {
        return Date()
    }
    
    public var availabilityLabel: String? {
        if let finished = finishedOn {
            let timeStr = finished.localizedAvailabilityString()
            let formatStr = Localization.localizedString("Completed: %@")
            return String.localizedStringWithFormat(formatStr, timeStr)
        }
        else if isAvailableNow {
            if let expireTime = self.expiresOn, !isAllDay {
                let timeStr = expireTime.localizedAvailabilityString()
                let formatStr = Localization.localizedString("Available until %@")
                return String.localizedStringWithFormat(formatStr, timeStr)
            }
            else {
                // Do not show anything for the availability string if available now
                // and will not expire or if it is a daily schedule.
                return nil
            }
        }
        else if let expireTime = self.expiresOn, !isAllDay {
            if expireTime < now, !isCompleted {
                let timeStr = expireTime.localizedAvailabilityString()
                let formatStr = Localization.localizedString("Expired: %@")
                return String.localizedStringWithFormat(formatStr, timeStr)
            }
            else {
                let formatter = DateIntervalFormatter()
                formatter.dateStyle = scheduledOn.isToday ? .none : .short
                formatter.timeStyle = scheduledOn.isToday ? .short : .none
                let timeStr = formatter.string(from: scheduledOn, to: expireTime)
                let formatStr = Localization.localizedString("Available: %@")
                return String.localizedStringWithFormat(formatStr, timeStr)
            }
        }
        else {
            let timeStr = scheduledOn.localizedAvailabilityString()
            let formatStr = Localization.localizedString("Available: %@")
            return String.localizedStringWithFormat(formatStr, timeStr)
        }
    }
}

extension Date {
    fileprivate func localizedAvailabilityString() -> String {
        if isToday {
            return DateFormatter.localizedString(from: self, dateStyle: .none, timeStyle: .short)
        }
        else if self.startOfDay() == self {
            return DateFormatter.localizedString(from: self, dateStyle: .short, timeStyle: .none)
        }
        else {
            return DateFormatter.localizedString(from: self, dateStyle: .short, timeStyle: .short)
        }
    }
}
