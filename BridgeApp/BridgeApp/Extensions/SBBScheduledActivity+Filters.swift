//
//  SBBScheduledActivity+Filters.swift
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
    
    public static func finishedOnDatePredicate(on date: Date) -> NSPredicate {
        return NSPredicate(day: date, dateKey: #keyPath(finishedOn))
    }
    
    public static func isFinishedPredicate() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(finishedOn))
    }
    
    public static func scheduledOnDatePredicate(on date: Date) -> NSPredicate {
        return NSPredicate(day: date, dateKey: #keyPath(scheduledOn))
    }

    public static func expiredOnDatePredicate(on date: Date) -> NSPredicate {
        return NSPredicate(day: date, dateKey: #keyPath(expiresOn))
    }
    
    public static func availableBeforePredicate(_ date: Date) -> NSPredicate {
        let expiredKey = #keyPath(expiresOn)
        let expiredBefore = NSPredicate(format: "%K != nil AND %K < %@", expiredKey, expiredKey, date as CVarArg)
        let finishedKey = #keyPath(finishedOn)
        let finishedBefore = NSPredicate(format: "%K != nil AND %K < %@", finishedKey, finishedKey, date as CVarArg)
        return NSCompoundPredicate(orPredicateWithSubpredicates: [expiredBefore, finishedBefore])
    }
    
    public static func availableAfterPredicate(_ date: Date) -> NSPredicate {
        let scheduledKey = #keyPath(scheduledOn)
        let scheduleAfter = NSPredicate(format: "%K > %@", scheduledKey, date as CVarArg)
        let finishedKey = #keyPath(finishedOn)
        let finishedAfter = NSPredicate(format: "%K != nil AND %K > %@", finishedKey, finishedKey, date as CVarArg)
        return NSCompoundPredicate(orPredicateWithSubpredicates: [scheduleAfter, finishedAfter])
    }
    
    public static func availableOnPredicate(on date: Date) -> NSPredicate {
        let startOfDay = date.startOfDay()
        let startOfNextDay = startOfDay.addingNumberOfDays(1)
        
        // Scheduled for this date or prior
        let scheduledKey = #keyPath(scheduledOn)
        let scheduledThisDayOrBefore = NSPredicate(format: "%K == nil OR %K < %@", scheduledKey, scheduledKey, startOfNextDay as CVarArg)
        let unfinished = NSCompoundPredicate(notPredicateWithSubpredicate: isFinishedPredicate())
        let finishedOnThisDay = finishedOnDatePredicate(on: date)
        
        let expiredKey = #keyPath(expiresOn)
        let expiredOnThisDay = NSPredicate(format: "%K == nil OR (%K >= %@ AND %K < %@)", expiredKey, expiredKey, startOfDay as CVarArg, expiredKey, startOfNextDay as CVarArg)
        let expiredOnOrAfterThisDay = NSPredicate(format: "%K == nil OR %K > %@", expiredKey, expiredKey, startOfDay as CVarArg)
        
        switch(startOfDay.compare(Date().startOfDay())) {
            
        case .orderedAscending:
            // build a filter for a day in the past that includes expired on that day OR completed on that day
            let expired = NSCompoundPredicate(andPredicateWithSubpredicates: [unfinished, expiredOnThisDay])
            let finishedOrExpired = NSCompoundPredicate(orPredicateWithSubpredicates: [finishedOnThisDay, expired])
            return NSCompoundPredicate(andPredicateWithSubpredicates: [scheduledThisDayOrBefore, finishedOrExpired])
        
        case .orderedSame:
            // build a filter for today that includes activites completed today, expiring today or later and scheduled to 
            // include today
            let unfinishedOrFinishedToday = NSCompoundPredicate(orPredicateWithSubpredicates: [unfinished, finishedOnThisDay])
            return NSCompoundPredicate(andPredicateWithSubpredicates: [scheduledThisDayOrBefore, unfinishedOrFinishedToday, expiredOnOrAfterThisDay])
        
        case .orderedDescending:
            // For the future, we only want unfinished schedules
            return NSCompoundPredicate(andPredicateWithSubpredicates: [scheduledThisDayOrBefore, unfinished, expiredOnOrAfterThisDay])
        }
    }
    
    public static func availableTodayPredicate() -> NSPredicate {
        return availableOnPredicate(on: Date())
    }
    
    public static func includeTasksPredicate(with identifiers: [String]) -> NSPredicate {
        let predicates = identifiers.map { activityIdentifierPredicate(with: $0) }
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }
    
    public static func schedulePlanPredicate(with guid: String) -> NSPredicate {
        let key = #keyPath(schedulePlanGuid) as NSString
        return NSPredicate(format: "(%K == %@)", key, guid)
    }
    
    public static func activityIdentifierPredicate(with identifier: String) -> NSPredicate {
        let taskRefPredicate = NSPredicate(format: "(activity.task != nil) AND (activity.task.identifier == %@)", identifier)
        let surveyRefPredicate = NSPredicate(format: "(activity.survey != nil) AND (activity.survey.identifier == %@)", identifier)
        let comboRefPredicate = NSPredicate(format: "(activity.compoundActivity != nil) AND (activity.compoundActivity.taskIdentifier == %@)", identifier)
        return NSCompoundPredicate(orPredicateWithSubpredicates: [taskRefPredicate, surveyRefPredicate, comboRefPredicate])
    }
    
    public static func activityGroupPredicate(for activityGroup: SBAActivityGroup) -> NSPredicate {
        let identifiers = activityGroup.activityIdentifiers.map { $0.stringValue }
        if let _ = activityGroup.schedulePlanGuidMap {
            let predicates = identifiers.map { (identifier) -> NSPredicate in
                let taskPredicate = SBBScheduledActivity.activityIdentifierPredicate(with: identifier)
                if let guid = activityGroup.schedulePlanGuid(for: identifier) {
                    let guidPredicate = SBBScheduledActivity.schedulePlanPredicate(with: guid)
                    return NSCompoundPredicate(andPredicateWithSubpredicates: [guidPredicate, taskPredicate])
                } else {
                    return taskPredicate
                }
            }
            return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }
        else {
            let taskPredicate = SBBScheduledActivity.includeTasksPredicate(with: identifiers)
            if let guid = activityGroup.schedulePlanGuid {
                let guidPredicate = SBBScheduledActivity.schedulePlanPredicate(with: guid)
                return NSCompoundPredicate(andPredicateWithSubpredicates: [guidPredicate, taskPredicate])
            }
            else {
                return taskPredicate
            }
        }
    }
    
    public static func finishedOnSortDescriptor(ascending: Bool) -> NSSortDescriptor {
        let finishedKey = #keyPath(finishedOn)
        return NSSortDescriptor(key: finishedKey, ascending: ascending)
    }
}
