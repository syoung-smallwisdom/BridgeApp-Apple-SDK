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
import BridgeSDK

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
    
    public static func notFinishedAvailableNowPredicate() -> NSPredicate {
        let now = Date()
        
        let finishedKey = #keyPath(finishedOn)
        let notFinishedPredicate = NSPredicate(format: "%K == nil", finishedKey)
        
        let expiredKey = #keyPath(expiresOn)
        let expiredPredicate = NSPredicate(format: "%K == nil OR (%K >= %@)", expiredKey, expiredKey, now as CVarArg)
        
        let scheduledKey = #keyPath(scheduledOn)
        let schedulePredicate = NSPredicate(format: "%K < %@", scheduledKey, now as CVarArg)
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [schedulePredicate, notFinishedPredicate, expiredPredicate])
    }
    
    public static func availablePredicate(from scheduledFrom: Date, to scheduledTo: Date) -> NSPredicate {
        let finishedKey = #keyPath(finishedOn)
        let finishedPredicate = NSPredicate(format: "%K == nil OR ((%K >= %@) AND (%K < %@))", finishedKey, finishedKey, scheduledFrom as CVarArg, finishedKey, scheduledTo as CVarArg)
        
        let expiredKey = #keyPath(expiresOn)
        let expiredPredicate = NSPredicate(format: "%K == nil OR ((%K >= %@) AND (%K < %@))", expiredKey, expiredKey, scheduledFrom as CVarArg, expiredKey, scheduledTo as CVarArg)
        
        let scheduledKey = #keyPath(scheduledOn)
        let schedulePredicate = NSPredicate(format: "%K < %@", scheduledKey, scheduledTo as CVarArg)
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [schedulePredicate, finishedPredicate, expiredPredicate])
    }
    
    public static func finishedOnOrAfterPredicate(_ date: Date) -> NSPredicate {
        let finishedKey = #keyPath(finishedOn)
        return NSPredicate(format: "%K != nil AND %K >= %@", finishedKey, finishedKey, date as CVarArg)
    }
    
    public static func availableOnPredicate(on date: Date) -> NSPredicate {
        let startOfDay = date.startOfDay()
        let startOfNextDay = startOfDay.addingNumberOfDays(1)
        
        // Scheduled for this date or prior
        let scheduledKey = #keyPath(scheduledOn)
        let scheduledThisDayOrBefore = NSPredicate(format: "%K < %@", scheduledKey, startOfNextDay as CVarArg)
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
    
    public static func activityGuidPredicate(with guid: String) -> NSPredicate {
        return NSPredicate(format: "activity.guid == %@", guid)
    }
    
    public static func activityGroupPredicate(for activityGroup: SBAActivityGroup) -> NSPredicate {
        let identifiers = activityGroup.activityIdentifiers.map { $0.stringValue }
        if let guidMap = activityGroup.activityGuidMap {
            let predicates: [NSPredicate] = identifiers.map {
                if let guid = guidMap[$0] {
                    return activityGuidPredicate(with: guid)
                }
                else {
                    return activityIdentifierPredicate(with: $0)
                }
            }
            return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }
        else {
            let taskPredicate = includeTasksPredicate(with: identifiers)
            if let guid = activityGroup.schedulePlanGuid {
                let guidPredicate = schedulePlanPredicate(with: guid)
                return NSCompoundPredicate(andPredicateWithSubpredicates: [guidPredicate, taskPredicate])
            }
            else {
                return taskPredicate
            }
        }
    }
    
    public static func finishedOnSortDescriptor(ascending: Bool) -> NSSortDescriptor {
        let key = #keyPath(finishedOn)
        return NSSortDescriptor(key: key, ascending: ascending)
    }
    
    public static func scheduledOnSortDescriptor(ascending: Bool) -> NSSortDescriptor {
        let key = #keyPath(scheduledOn)
        return NSSortDescriptor(key: key, ascending: ascending)
    }
}
