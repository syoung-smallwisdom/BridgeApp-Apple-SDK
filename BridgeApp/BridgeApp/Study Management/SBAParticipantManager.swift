//
//  SBAParticipantManager.swift
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

extension Notification.Name {
    
    /// Notification name posted by the `SBAParticipantManager` when this manager has finished fetching the
    /// updated schedules into the shared BridgeSDK cache.
    ///
    /// - note: This message is sent whether or not the user is offline and the server was not reached.
    /// However, if that is the case then the manager will set a timer to try again.
    public static let SBAFinishedUpdatingScheduleCache = Notification.Name(rawValue: "SBAFinishedUpdatingScheduleCache")
    
    /// Notification name posted by the `SBAParticipantManager` when this manager has updated the study participant.
    public static let SBAStudyParticipantUpdated = Notification.Name(rawValue: "SBAStudyParticipantUpdated")
}


/// The participant manager is used to wrap the study participant to ensure that the participant in
/// memory is up-to-date with what has been sent to the server.
public final class SBAParticipantManager : NSObject {
    
    /// A singleton instance of the manager.
    static public var shared = SBAParticipantManager()
    
    /// The study participant.
    public private(set) var studyParticipant: SBBStudyParticipant? {
        didSet {
            NotificationCenter.default.post(name: .SBAStudyParticipantUpdated, object: self)
        }
    }
    
    /// Is the participant authenticated?
    public private(set) var isAuthenticated: Bool = false
    
    /// Has the participant signed any and all required consents?
    public private(set) var isConsented: Bool = false
    
    /// Is this a test user?
    internal var isTestUser: Bool {
        return self.studyParticipant?.dataGroups?.contains("test_user") ?? false
    }
    
    /// The date when the user started the study. By default, this will check the `dayOne` value and use
    /// `today` if that is not set.
    public var startStudy: Date {
        return Calendar.current.startOfDay(for: dayOne ?? studyParticipant?.createdOn ?? Date())
    }
    
    public override init() {
        super.init()
        
        // Add an observer for changes to the study participant.
        NotificationCenter.default.addObserver(forName: .sbbUserSessionUpdated, object: nil, queue: self.updateQueue) { (notification) in
            guard let info = notification.userInfo?[kSBBUserSessionInfoKey] as? SBBUserSessionInfo else {
                fatalError("Expecting a non-nil user session info")
            }
            let authenticated = info.authenticated?.boolValue ?? false
            let consented = info.consentedValue
            let hasChanges = (authenticated && !self.isAuthenticated) ||
                consented != self.isConsented ||
                !RSDObjectEquality(info.studyParticipant.dataGroups, self.studyParticipant?.dataGroups)
            self.studyParticipant = info.studyParticipant
            self.isAuthenticated = authenticated
            self.isConsented = consented
            if hasChanges {
                self.reload(allFuture: true)
            }
        }
        
        // Add an observer that a schedule manager has updated the scheduled activities. Often updating the
        // schedules will change the available "next" schedule.
        NotificationCenter.default.addObserver(forName: .SBADidSendUpdatedScheduledActivities, object: nil, queue: self.updateQueue) { (notification) in
            self.reload(allFuture: true)
        }
        
        // Add an observer the app entering the foreground to check for whether or not "today" is still valid.
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: self.updateQueue) { (notification) in
            self.reload(allFuture: false)
        }
    }
    
    // MARK: Shared schedule cache management.
    
    private let userDefaultsQueue = DispatchQueue(label: "org.sagebionetworks.BridgeApp.SBAParticipantManager.UserDefaults")
    private let updateQueue = OperationQueue()
    
    /// Marks the start of today's date. This value is updated on a reload to update the current day.
    public private(set) var today = Date().startOfDay()
    
    /// Tracking for the last time the app pinged the server to update schedules.
    public private(set) var lastPing: Date? {
        get {
            var ret: Date?
            userDefaultsQueue.sync {
                ret = UserDefaults.standard.object(forKey: "kSBALastPingTimestampKey") as? Date
            }
            return ret
        }
        set {
            userDefaultsQueue.async {
                UserDefaults.standard.set(newValue, forKey: "kSBALastPingTimestampKey")
            }
        }
    }

    /// The "first" day that the participant performed an activity for the study.
    public private(set) var dayOne: Date? {
        get {
            var ret: Date?
            userDefaultsQueue.sync {
                ret = UserDefaults.standard.object(forKey: "kSBADayOneKey") as? Date
            }
            return ret
        }
        set {
            userDefaultsQueue.async {
                UserDefaults.standard.set(newValue, forKey: "kSBADayOneKey")
            }
        }
    }
    
    /// State management for whether or not the schedules are reloading.
    public private(set) var isReloading: Bool = false
    fileprivate var _loadingBlocked: Bool = false
    fileprivate var _timerReload: Bool = false

    /// Exit early if already reloading activities. This can happen if the user flips quickly back and forth
    /// from this tab to another tab.
    private func shouldContinueLoading() -> Bool {
        if (isReloading) {
            _loadingBlocked = true
            return false
        }
        _loadingBlocked = false
        isReloading = true
        return true
    }
    
    /// Reload the schedules. This is triggered automatically by a change to data groups and when returning
    /// from the background.
    public func updateSchedules() {
        self.updateQueue.addOperation {
            self.reload(allFuture: true)
        }
    }
    
    private func reload(allFuture: Bool) {
        guard self.isAuthenticated && (allFuture || !Calendar.current.isDateInToday(self.today)),
            shouldContinueLoading()
            else {
                return
        }
        
        let daysIntoFuture = BridgeSDK.bridgeInfo.cacheDaysAhead + 1
        var fromDate: Date = self.lastPing ?? self.startStudy
        let toDate: Date = Date().addingNumberOfDays(daysIntoFuture).startOfDay()
        
        if allFuture {
            let predicate = SBBScheduledActivity.notFinishedAvailableNowPredicate()
            let sortDescriptors = [SBBScheduledActivity.scheduledOnSortDescriptor(ascending: true)]
            let schedules = try? BridgeSDK.activityManager.getCachedSchedules(using: predicate, sortDescriptors: sortDescriptors, fetchLimit: 1)
            if let scheduledOn = schedules?.first?.scheduledOn, scheduledOn < fromDate {
                // Found a schedule. Need to check if it is still valid.
                fromDate = scheduledOn
            }
        }

        // Reset "today"
        self.today = Date().startOfDay()
        
        fetchScheduledActivities(from: fromDate, to: toDate)
    }

    /// Some (but possibly not all) of the requested schedules have been fetched. Handle adding them and
    /// fetch more of the range if needed.
    fileprivate func handleLoadedActivities(pingDate: Date, scheduledActivities: [SBBScheduledActivity]?, error: Error?) {
        
        self.isReloading = false
        self._timerReload = false
        
        // If the participant is not consented, don't spam the server logs with 412s by retrying every 5 minutes.
        // https://sagebionetworks.jira.com/browse/IA-711
        // Note that we check for (a) the case where we bypassed calling Bridge because we believe we are not consented,
        // and also (b) the case where we hit Bridge thinking we were consented but it turns out we in fact are not.
        let isConsentError: Bool  = {
            if let err = error as? InternalError, err == .unconsented {
                return true
            }
            else if let err = error, (err as NSError).code == SBBErrorCode.serverPreconditionNotMet.rawValue {
                return true
            }
            else {
                return false
            }
        }()
        
        guard !isConsentError else {
            return
        }

        // Failed to ping server for some other reason; try again in 5 minutes.
        guard error == nil, let scheduledActivities = scheduledActivities else {
            self._timerReload = true
            let delay = DispatchTime.now() + .seconds(5 * 60)
            DispatchQueue.main.asyncAfter(deadline: delay) {
                self.updateQueue.addOperation {
                    if !self.isReloading && self._timerReload {
                        self.reload(allFuture: true)
                    }
                }
            }
            return
        }
        
        // Save the last ping date for a successful ping of the server.
        self.lastPing = pingDate
            
        // Set the dayOne value.
        if (self.dayOne == nil) {
            let dayOne = scheduledActivities.compactMap{ $0.finishedOn }.sorted().first
            SBAParticipantManager.shared.dayOne = dayOne
        }
        
        // Preload all the surveys so that they can be accessed offline.
        var surveys: [String] = []
        scheduledActivities.forEach {
            if let survey = $0.activity.survey, !surveys.contains(survey.href) {
                surveys.append(survey.href)
                BridgeSDK.surveyManager.getSurveyByRef(survey.href, cachingPolicy: .checkCacheFirst) { (_, _) in }
            }
        }
        
        // Including all the surveys listed in the appConfig (now that we know the user is authenticated).
        if let appConfig = BridgeSDK.appConfig(), let surveyRefs = appConfig.surveyReferences as? [SBBSurveyReference] {
            surveyRefs.forEach { (survey) in
                if !surveys.contains(survey.href) {
                    BridgeSDK.surveyManager.getSurveyByRef(survey.href, cachingPolicy: .checkCacheFirst) { (_, _) in }
                }
            }
        }

        if self._loadingBlocked {
            // If loading refresh was requested, but blocked, then reload again.
            reload(allFuture: true)
        }
        else {
            // We are done. Post notification that the schedules were updated.
            NotificationCenter.default.post(name: .SBAFinishedUpdatingScheduleCache,
                                            object: self)
        }
    }
    
    private enum InternalError: Error {
        case unconsented
    }
    
    /// Convenience method for wrapping the call to BridgeSDK.
    fileprivate func fetchScheduledActivities(from fromDate: Date, to toDate: Date) {
        let pingDate = Date()
        guard self.isConsented else {
            // don't hit Bridge for scheduled activities when we are pretty sure we are not consented--
            // but still call the handler
            let error = InternalError.unconsented
            self.updateQueue.addOperation {
                self.handleLoadedActivities(pingDate: pingDate, scheduledActivities: nil, error: error)
            }
            return
        }
        BridgeSDK.activityManager.getScheduledActivities(from: fromDate, to: toDate, cachingPolicy: .fallBackToCached) { (obj, error) in
            //print("\n\n---Fetch Results pingDate:\(pingDate) from:\(fromDate) to:\(toDate)\n\(String(describing: obj))")
            self.updateQueue.addOperation {
                self.handleLoadedActivities(pingDate: pingDate,
                                            scheduledActivities: obj as? [SBBScheduledActivity],
                                            error: error)
            }
        }
    }
}
