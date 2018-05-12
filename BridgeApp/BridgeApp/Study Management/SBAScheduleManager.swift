//
//  SBAScheduleManager.swift
//  BridgeApp
//
//  Copyright © 2016-2018 Sage Bionetworks. All rights reserved.
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

extension Notification.Name {
    
    /// Notification name posted by the `SBASchduleManager` when the activities have been updated.
    public static let SBAUpdatedScheduledActivities = Notification.Name(rawValue: "SBAUpdatedScheduledActivities")
}

/// Default data source handler for scheduled activities. This manager is used to get `SBBScheduledActivity`
/// objects and upload the task results for Bridge services. By default, this manager will fetch all the
/// activities, but will *not* cache them all in memory. Instead, it will filter out those activites that are
/// valid for today and the most recent finished activity (if any) for each activity identifier where the
/// "activity identifier" refers to an `SBBActivity` object's associated `SBAActivityReference`.
///
open class SBAScheduleManager: NSObject {
    
    /// List of keys used in the notifications sent by this manager.
    public enum NotificationKey : String {
        case previousActivities
    }
    
    public override init() {
        super.init()
        
        // Add an observer the app entering the foreground to check for whether or not "today" is still valid.
        NotificationCenter.default.addObserver(forName: .SBAFinishedUpdatingScheduleCache, object: nil, queue: .main) { (notification) in
            self.reloadData()
        }
    }
    
    // MARK: Data source
    
    /// This is an array of the activities fetched by the call to the server in `reloadData`. By default,
    /// this list includes the activities filtered using the `scheduleFilterPredicate`.
    @objc open var scheduledActivities: [SBBScheduledActivity] = []
    
    
    // MARK: Schedule loading
    
    /// A predicate that can be used to evaluate whether or not a schedule should be included in the
    /// `scheduledActivities` array. This can include block predicates and is evaluated on each
    /// `SBBScheduledActivity` object returned by the server.
    open var scheduleFilterPredicate: NSPredicate = NSPredicate(value: true)
    
    /// Convenience method for accessing the `startStudy` date from the shared `SBAParticipantManager`.
    public var startStudy: Date {
        return SBAParticipantManager.shared.startStudy
    }
    
    /// The date to use when reloading data as the minimum date to fetch.
    open var fromDate: Date {
        return startStudy
    }
    
    /// The date to use when reloading data as the maximum date to fetch.
    open var toDate: Date {
        return startStudy.addingDateComponents(SBABridgeConfiguration.shared.studyDuration)
    }
    
    /// State management for whether or not the schedules are reloading.
    public private(set) var isReloading: Bool = false
    
    /// Reload the data by fetching changes to the scheduled activities.
    open func reloadData() {
        loadScheduledActivities(from: fromDate, to: toDate)
    }
    
    /// Load a given range of schedules.
    public final func loadScheduledActivities(from fromDate: Date, to toDate: Date) {
        if isReloading { return }
        isReloading = true
        
        fetchScheduledActivities(from: fromDate, to: toDate) { [weak self] (schedules, error) in
            self?.handleLoadedActivities(schedules, from: fromDate, to: toDate)
        }
    }
    
    /// Some (but possibly not all) of the requested schedules have been fetched. Handle adding them and
    /// fetch more of the range if needed.
    open func handleLoadedActivities(_ scheduledActivities: [SBBScheduledActivity]?, from fromDate: Date, to toDate: Date) {
        DispatchQueue.main.async {
            if let scheduledActivities = self.sortActivities(scheduledActivities) {
                self.update(fetchedActivities: scheduledActivities, from: fromDate, to: toDate)
            }
        }
    }
    
    /// Convenience method for wrapping the call to BridgeSDK.
    fileprivate func fetchScheduledActivities(from fromDate: Date, to toDate: Date, completion: @escaping ([SBBScheduledActivity]?, Error?) -> Swift.Void) {
        // TODO: syoung 05/11/2018 Refactor to include a SQL query to use when fetching from cache to only
        // fetch the schedules of interest to this manager.
        BridgeSDK.activityManager.getScheduledActivities(from: fromDate, to: toDate, cachingPolicy: .cachedOnly) { (obj, error) in
                completion(obj as? [SBBScheduledActivity], error)
        }
    }

    
    // MARK: Data handling
    
    /// Called once the response from the server returns the scheduled activities.
    ///
    /// By default, this method will filter the scheduled activities to only include those that *this*
    /// schedule manager is designed to be able to handle.
    ///
    /// - parameters:
    ///     - scheduledActivities: The list of activities returned by the service.
    ///     - fromDate: The `fromDate` parameter included in the call to the server.
    ///     - toDate: The `toDate` parameter included in the call to the server.
    open func update(fetchedActivities: [SBBScheduledActivity], from fromDate: Date, to toDate: Date) {
        // Filter and update the schedules.
        let schedules = filterSchedules(fetchedActivities, from: fromDate, to: toDate)
        let hasChanges = (schedules != self.scheduledActivities)
        let previous = self.scheduledActivities
        self.scheduledActivities = schedules
        if hasChanges {
            self.didUpdateScheduledActivities(from: previous)
        }
    }
    
    /// Called when the schedules have changed.
    ///
    /// - parameter previousActivities: The schedules that were previously being stored in memory.
    open func didUpdateScheduledActivities(from previousActivities: [SBBScheduledActivity]) {
        
        // Post notification that the schedules were updated.
        NotificationCenter.default.post(name: .SBAUpdatedScheduledActivities,
                                        object: self,
                                        userInfo: [NotificationKey.previousActivities: previousActivities])
    }
    
    /// Sort the scheduled activities. By default this will sort by comparing the `scheduledOn` property.
    open func sortActivities(_ scheduledActivities: [SBBScheduledActivity]?) -> [SBBScheduledActivity]? {
        guard (scheduledActivities?.count ?? 0) > 0 else { return nil }
        return scheduledActivities!.sorted(by: { (scheduleA, scheduleB) -> Bool in
            return scheduleA.scheduledOn.compare(scheduleB.scheduledOn) == .orderedAscending
        })
    }
    
    /// Filter the scheduled activities to only include those that *this* version of the app is designed
    /// to be able to handle.
    ///
    /// - parameters:
    ///     - scheduledActivities: The list of activities returned by the service.
    ///     - fromDate: The `fromDate` parameter included in the call to the server.
    ///     - toDate: The `toDate` parameter included in the call to the server.
    /// - returns: The filtered list of activities.
    open func filterSchedules(_ schedules: [SBBScheduledActivity], from fromDate: Date, to toDate: Date) -> [SBBScheduledActivity] {
        let outsideRange = NSCompoundPredicate(orPredicateWithSubpredicates: [
            SBBScheduledActivity.availableBeforePredicate(fromDate),
            SBBScheduledActivity.availableAfterPredicate(toDate)])
        var activities = self.scheduledActivities.filter { (schedule) in
            outsideRange.evaluate(with: schedule) && !schedules.contains(where: { $0.guid == schedule.guid })
        }
        activities.append(contentsOf: schedules)
        return activities
    }
    
    
    // MARK: Schedule management
    
    /// If a schedule is unavailable, then the user is shown an alert explaining when it will become
    /// available.
    ///
    /// - parameter schedule: The schedule to check.
    /// - returns: The message to display in an alert for a schedule that is not currently available.
    open func messageForUnavailableSchedule(_ schedule: SBBScheduledActivity) -> String {
        var scheduledTime: String!
        if schedule.scheduledOn < Date().startOfDay().addingNumberOfDays(1) {
            scheduledTime = schedule.scheduledTime
        }
        else {
            scheduledTime = DateFormatter.localizedString(from: schedule.scheduledOn, dateStyle: .medium, timeStyle: .none)
        }
        return Localization.localizedStringWithFormatKey("ACTIVITY_SCHEDULE_MESSAGE_%@", scheduledTime)
    }
    
    /// Get the scheduled activity that is associated with this schedule identifier.
    ///
    /// - parameter scheduleIdentifier: The schedule identifier that was used to start the task.
    /// - returns: The schedule associated with this task view controller (if available).
    open func scheduledActivity(with scheduleIdentifier: String?) -> SBBScheduledActivity? {
        guard let scheduleIdentifier = scheduleIdentifier else { return nil }
        return self.scheduledActivities.first(where: { $0.scheduleIdentifier == scheduleIdentifier })
    }
    
    /// Get the scheduled activities associated with a given group that are available on a given day.
    /// The criteria for determining availablity is dependent upon the timing of the activity. For a
    /// day in the past, the criteria includes when the task was finished, expired, and scheduled. For
    /// a day in the future, the criterion is decided by when the activity is scheduled. For today, the
    /// activity must either be finished today, or available today (scheduled for a time window that
    /// includes this day.
    ///
    /// - parameters:
    ///     - activityGroup: The activity group to filter on.
    ///     - availableOn: The date for the day when the activities are "available".
    /// - returns: The schedule associated with this task view controller (if available).
    open func scheduledActivities(for activityGroup: SBAActivityGroup, availableOn: Date) -> [SBBScheduledActivity] {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
            [SBBScheduledActivity.availableOnPredicate(on: availableOn),
             SBBScheduledActivity.activityGroupPredicate(for: activityGroup)])
        return self.scheduledActivities.filter { predicate.evaluate(with: $0) }
    }
    
    /// Instantiate a task path appropriate to the given task info. This method will attempt to map the
    /// task info to a schedule, but if called, it is assumed that even if there is no schedule associated
    /// with this task, that the task path should be instantiated.
    ///
    /// The returned result includes the instantiated task path, the reference schedule (if found), and the
    /// clientData from the most recent finished run of the schedule (if found).
    ///
    /// - note: This method should not be used to instantiate child task paths that are used to track the
    /// task state for a subtask. Instead, it is intended for starting a new task and will set up any state
    /// handling (such as tracking data groups) that must be managed globally.
    ///
    /// - parameters:
    ///     - taskInfo: The task info object to use to create the task path.
    ///     - activityGroup: The activity group to use to determine the schedule. This is used for the case
    ///                      where there may be multiple schedules with the same task and the
    ///                      `schedulePlanGUID` on the activity group is used to determine which available
    ///                      schedule is the one to associate with this task.
    /// - returns:
    ///     - taskPath: The instantiated task path.
    ///     - referenceSchedule: The schedule to reference for uploading the task path results (if any).
    ///     - clientData: The client data from the most recent finished run of the schedule (if any).
    open func instantiateTaskPath(for taskInfo: RSDTaskInfo, in activityGroup: SBAActivityGroup? = nil) -> (taskPath: RSDTaskPath, referenceSchedule: SBBScheduledActivity?, clientData: SBBJSONValue?) {
        
        // Set up predicates.
        var taskPredicate = SBBScheduledActivity.activityIdentifierPredicate(with: taskInfo.identifier)
        if let guid = activityGroup?.schedulePlanGuid(for: taskInfo.identifier) {
            taskPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                taskPredicate, SBBScheduledActivity.schedulePlanPredicate(with: guid)])
        }

        // Get the schedule.
        let todaySchedules = self.scheduledActivities.filter {
            taskPredicate.evaluate(with: $0) && (($0.scheduledOn.timeIntervalSinceNow < 0) && !$0.isExpired)
        }
        let schedule = todaySchedules.rsd_last(where: { $0.isCompleted == false }) ?? todaySchedules.last
        
        // Get the clientData from the most recent finished schedule with the same activity identifier.
        var clientData: SBBJSONValue?
        var currentFinishedOn = Date.distantPast
        let activityPredicate = SBBScheduledActivity.activityIdentifierPredicate(with: taskInfo.identifier)
        self.scheduledActivities.forEach { (schedule) in
            if let data = schedule.clientData,
                let finishedOn = schedule.finishedOn, finishedOn > currentFinishedOn,
                activityPredicate.evaluate(with: schedule) {
                clientData = data
                currentFinishedOn = finishedOn
            }
        }
        
        // Create the task path, by looking for a valid task transformer.
        let taskPath: RSDTaskPath
        if let activityReference = schedule?.activity.activityReference {
            if let taskInfoStep = activityReference as? RSDTaskInfoStep {
                taskPath = RSDTaskPath(taskInfo: taskInfoStep)
            }
            else {
                let taskInfoStep = RSDTaskInfoStepObject(with: activityReference)
                taskPath = RSDTaskPath(taskInfo: taskInfoStep)
            }
        }
        else if let task = SBABridgeConfiguration.shared.taskMap[taskInfo.identifier] {
            // Copy if option available.
            if let copyableTask = task as? RSDCopyTask,
                let schema = SBABridgeConfiguration.shared.schemaReferenceMap[taskInfo.identifier] {
                taskPath = RSDTaskPath(task: copyableTask.copy(with: taskInfo.identifier, schemaInfo: schema.schemaInfo))
            }
            else {
                taskPath = RSDTaskPath(task: task)
            }
        }
        else if let _ = taskInfo.resourceTransformer {
            let taskInfoStep = RSDTaskInfoStepObject(with: taskInfo)
            taskPath = RSDTaskPath(taskInfo: taskInfoStep)
        }
        else {
            assertionFailure("Failed to instantiate the task for this task info.")
            let task = RSDTaskObject(identifier: taskInfo.identifier, stepNavigator: RSDConditionalStepNavigatorObject(with: []))
            taskPath = RSDTaskPath(task: task)
        }
        
        // Assign values to the task path from the schedule.
        taskPath.scheduleIdentifier = schedule?.scheduleIdentifier
        
        // Set up the data groups tracking rule.
        if let participant = SBAParticipantManager.shared.studyParticipant {
            // If there is an existing tracking rule then there was a task that wasn't
            // saved. So these changes should **not** be commited. Throw them out.
            SBAFactory.shared.trackingRules.remove(where: { $0 is DataGroupsTrackingRule})
            let rule = DataGroupsTrackingRule(initialCohorts: participant.dataGroups ?? [])
            SBAFactory.shared.trackingRules.append(rule)
        } else {
            debugPrint("WARNING: Missing a study particpant. Cannot get the data groups.")
        }
        
        return (taskPath, schedule, clientData)
    }
    
    /// subclass the cohorts tracking rule so that we can use casting to check for an existing
    /// tracking rule.
    class DataGroupsTrackingRule : RSDCohortTrackingRule {
    }
    
    // TODO: syoung 05/10/2018 - Implement handling for uploading archives and marking the schedule as finished.
}

