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
}


/// The participant manager is used to wrap the study participant to ensure that the participant in
/// memory is up-to-date with what has been sent to the server.
public final class SBAParticipantManager : NSObject {
    
    /// A singleton instance of the manager.
    static public var shared = SBAParticipantManager()
    
    /// The study participant.
    public private(set) var studyParticipant: SBBStudyParticipant?
    
    /// Is the participant authenticated?
    public private(set) var isAuthenticated: Bool = false
    
    /// The "first" day that the participant performed an activity for the study.
    public private(set) var dayOne: Date?
    
    /// The date when the user started the study. By default, this will check the `dayOne` value and use
    /// `today` if that is not set.
    public var startStudy: Date {
        return Calendar.current.startOfDay(for: dayOne ?? studyParticipant?.createdOn ?? Date())
    }
    
    public override init() {
        super.init()
        
        // Add an observer for changes to the study participant.
        NotificationCenter.default.addObserver(forName: .sbbUserSessionUpdated, object: nil, queue: .main) { (notification) in
            guard let info = notification.userInfo?[kSBBUserSessionInfoKey] as? SBBUserSessionInfo else {
                fatalError("Expecting a non-nil user session info")
            }
            let authenticated = info.authenticated?.boolValue ?? false
            let hasChanges = (authenticated && !self.isAuthenticated) || !RSDObjectEquality(info.studyParticipant.dataGroups, self.studyParticipant?.dataGroups)
            self.studyParticipant = info.studyParticipant
            self.isAuthenticated = authenticated
            if hasChanges {
                self.reloadSchedules()
            }
        }
        
        // Add an observer that a schedule manager has updated the scheduled activities. Often updating the
        // schedules will change the available "next" schedule.
        NotificationCenter.default.addObserver(forName: .SBADidSendUpdatedScheduledActivities, object: nil, queue: .main) { (notification) in
            self.reloadSchedules()
        }
        
        // Add an observer the app entering the foreground to check for whether or not "today" is still valid.
        NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: .main) { (notification) in
            self.reloadIfTodayChanged()
        }
    }
    
    // MARK: Shared schedule cache management.
    
    /// Marks the start of today's date. This value is updated on a reload to update the current day.
    public private(set) var today = Date().startOfDay()
    
    /// Tracking of the loading state.
    public enum LoadState {
        case firstLoad
        case cachedLoad
        case fromServer
    }
    
    /// State management for what the current loading state is. This is used to pre-load from cache before
    /// going to the server for updates.
    public private(set) var loadingState: LoadState = .firstLoad
    
    /// State management for whether or not the schedules are reloading.
    public private(set) var isReloading: Bool = false
    fileprivate var _loadingBlocked: Bool = false

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
    public func reloadSchedules() {
        DispatchQueue.main.async {
            self.reload(allFuture: true)
        }
    }
    
    private func reloadIfTodayChanged() {
        DispatchQueue.main.async {
            self.reload(allFuture: false)
        }
    }
    
    private func reload(allFuture: Bool) {
        guard (allFuture || Calendar.current.isDateInToday(self.today)),
            shouldContinueLoading()
            else {
                return
        }
        
        let daysIntoFuture = allFuture ? BridgeSDK.bridgeInfo.cacheDaysAhead + 1 : 1
        let toDate = Date().addingNumberOfDays(daysIntoFuture).startOfDay()
        var fromDate = self.today
        var cachingPolicy: SBBCachingPolicy = .fallBackToCached
        self.today = Date().startOfDay()
        if loadingState == .firstLoad {
            fromDate = startStudy
            cachingPolicy = .cachedOnly
            loadingState = .cachedLoad
        }
        
        fetchScheduledActivities(from: fromDate, to: toDate, cachingPolicy: cachingPolicy) { (activities, error) in
            self.handleLoadedActivities(activities, from: fromDate, to: toDate, error: error)
        }
    }

    /// Some (but possibly not all) of the requested schedules have been fetched. Handle adding them and
    /// fetch more of the range if needed.
    fileprivate func handleLoadedActivities(_ scheduledActivities: [SBBScheduledActivity]?, from fromDate: Date, to toDate: Date, error: Error?) {
        DispatchQueue.main.async {
            
            // Mark the start of the participant's engagement in the study.
            if let scheduledActivities = scheduledActivities {
                
                // Set the dayOne value.
                if (self.dayOne == nil) || (fromDate < self.dayOne!) {
                    let dayOne = scheduledActivities.compactMap{ $0.finishedOn }.sorted().first
                    if (dayOne != nil) && ((self.dayOne == nil) || (dayOne! < self.dayOne!)) {
                        SBAParticipantManager.shared.dayOne = dayOne
                    }
                }
            
                // Preload all the surveys so that they can be accessed offline.
                var surveys: [String] = []
                scheduledActivities.forEach {
                    if let survey = $0.activity.survey, !surveys.contains(survey.href) {
                        surveys.append(survey.href)
                        BridgeSDK.surveyManager.getSurveyByRef(survey.href, cachingPolicy: .checkCacheFirst) { (_, _) in }
                    }
                }
            }
            
            if self.loadingState == .fromServer {
                // If the loading state is for the full range, then we are done.
                self.isReloading = false
                
                // Post notification that the schedules were updated.
                NotificationCenter.default.post(name: .SBAFinishedUpdatingScheduleCache,
                                                object: self)
            }
            else {
                // Otherwise, load more range from the server
                self.loadingState = .fromServer
                
                let nextFromDate = (scheduledActivities?.count ?? 0 > 0) ? Date() : fromDate
                
                self.fetchScheduledActivities(from: nextFromDate, to: toDate, cachingPolicy: .fallBackToCached) { (activities, error) in
                    self.handleLoadedActivities(activities, from: nextFromDate, to: toDate, error: error)
                }
            }
        }
    }
    
    /// Convenience method for wrapping the call to BridgeSDK.
    fileprivate func fetchScheduledActivities(from fromDate: Date, to toDate: Date, cachingPolicy policy: SBBCachingPolicy, completion: @escaping ([SBBScheduledActivity]?, Error?) -> Swift.Void) {
        BridgeSDK.activityManager.getScheduledActivities(from: fromDate, to: toDate, cachingPolicy: policy) { (obj, error) in
            completion(obj as? [SBBScheduledActivity], error)
        }
    }
}
