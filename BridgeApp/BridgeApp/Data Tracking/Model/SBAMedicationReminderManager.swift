//
//  SBAMedicationReminderManager.swift
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
import UserNotifications

let SBAMedicationNotificationCategory = "Medication"
let SBAMedicationNotificationTakenAction = "MedicationTaken"

extension RSDIdentifier {
    
    public static let medicationTask: RSDIdentifier = "Medication"
}

open class SBAMedicationReminderManager : SBAScheduleManager, UNUserNotificationCenterDelegate {
    
    public static var shared = SBAMedicationReminderManager()
    
    public override init() {
        super.init()
        self.identifier = "LocalReminderManager"
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Play sound and show alert to the user
        completionHandler([.alert, .sound])
    }
    
    open func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Determine the user action
        switch response.actionIdentifier {
        case SBAMedicationNotificationTakenAction:
            medicationTaken(response.notification.request.content.userInfo, completionHandler: completionHandler)
        default:
            completionHandler()
        }
        
    }
    
    open func notificationCategories() -> Set<UNNotificationCategory> {
        
        // TODO: syoung 08/10/2018 Localize
        let takenAction = UNNotificationAction(identifier: SBAMedicationNotificationTakenAction,
                                                title: "Taken", options: [])
        let category = UNNotificationCategory(identifier: SBAMedicationNotificationCategory,
                                              actions: [takenAction],
                                              intentIdentifiers: [], options: [])
        
        return [category]
    }

    /// Override to set up to get most recent finished medication task.
    override open func fetchRequests() -> [FetchRequest] {
        let predicate = self.historyPredicate(for: .medicationTask)
        let sortDescriptors = [SBBScheduledActivity.finishedOnSortDescriptor(ascending: false)]
        return [FetchRequest(predicate: predicate, sortDescriptors: sortDescriptors, fetchLimit: 1)]
    }
    
    open func instantiateMedicationTrackingResult() -> SBAMedicationTrackingResult {
        return SBAMedicationTrackingResult(identifier: RSDIdentifier.trackedItemsResult.stringValue)
    }
    
    public func setupNotifications() {
        let categories = self.notificationCategories()
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }
    
    override open func didUpdateScheduledActivities(from previousActivities: [SBBScheduledActivity]) {
        super.didUpdateScheduledActivities(from: previousActivities)
        guard let medResult = self.getMedicationResult() else { return }
        DispatchQueue.main.async {
            self.updateNotifications(for: medResult)
        }
    }
    
    // MARK: Medication notification handling

    struct Reminder : RSDScheduleTime, Codable {
        private enum CodingKeys : String, CodingKey {
            case itemIdentifier, timingIdentifier
        }
        
        /// The identifier of the tracked item.
        public let itemIdentifier: String
        
        /// The timing identifier to map to a schedule.
        public let timingIdentifier: String
        
        /// Used to create a read/write object that can be mutated.
        public var timeOfDayString : String? {
            return timingIdentifier
        }
    }
    
    func getMedicationResult() -> SBAMedicationTrackingResult? {
        guard let clientData = self.clientData(with: RSDIdentifier.medicationTask.stringValue)
            else {
                return nil
        }
        do {
            var medicationTrackingResult = instantiateMedicationTrackingResult()
            try medicationTrackingResult.updateSelected(from: clientData, with: [])
            return medicationTrackingResult
        }
        catch let error {
            assertionFailure("Failed to decode medication result. \(error)")
            return nil
        }
    }
    
    func medicationTaken(_ userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        guard let medResult = self.getMedicationResult(),
            let schedule = self.scheduledActivity(for: RSDIdentifier.medicationTask.stringValue, in: nil)
            else {
                completionHandler()
                return
        }
        
        do {
            let reminder = try SBAFactory.shared.createJSONDecoder().decode(Reminder.self, from: userInfo as NSDictionary)
            var medicationTrackingResult = medResult
        
            let timestamp = reminder.timeOfDay(on: now())
            medicationTrackingResult.updateLogging(itemIdentifier: reminder.itemIdentifier,
                                                   timingIdentifier: reminder.timingIdentifier,
                                                   loggedDate: timestamp)
            let taskViewModel = self.instantiateTaskViewModel(for: schedule)
            taskViewModel.taskResult.appendAsyncResult(with: medicationTrackingResult)
            self.saveResults(from: taskViewModel, completionHandler)
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber -= 1;
            }
        }
        catch let error {
            assertionFailure("Failed to mark medication as taken. \(error)")
            completionHandler()
        }
    }
    
    func updateNotifications(for medicationResult: SBAMedicationTrackingResult) {
        guard let reminders = medicationResult.reminders, reminders.count > 0
            else {
                removeAllPendingNotifications()
                return
        }
        
        // use dispatch async to allow the method to return and put updating reminders on the next run loop
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .denied:
                    break   // Do nothing. We don't want to pester the user with message.
                case .notDetermined:
                    // The user has not given authorization, but the app has a record of previously requested
                    // authorization. This means that the app has been re-installed. Unfortunately, there isn't
                    // a great UI/UX for this senario, so just show the authorization request. syoung 07/19/2018
                    UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, _) in
                        if granted {
                            self.addNotifications(for: medicationResult)
                        }
                    }
                case .authorized, .provisional:
                    self.addNotifications(for: medicationResult)
                }
            }
        }
    }
    
    func getLocalNotifications(for medicationResult: SBAMedicationTrackingResult, with pendingRequests: [UNNotificationRequest]) -> (add: [UNNotificationRequest], removeIds: [String]) {
        
        var pendingRequestIds = pendingRequests.map { $0.identifier }
        guard let reminders = medicationResult.reminders, reminders.count > 0, medicationResult.medications.count > 0
            else {
                return ([], pendingRequestIds)
        }
        
        let requests: [UNNotificationRequest] = medicationResult.medications.compactMap { (med) -> [UNNotificationRequest]? in
            guard let scheduleItems = med.scheduleItems else { return nil }
            let scheduleRequests: [UNNotificationRequest] = scheduleItems.compactMap { (schedule) -> [UNNotificationRequest]? in
                guard let timeOfDay = schedule.timeOfDayString else { return nil }
                let triggers = schedule.notificationTriggers()
                let triggerRequests: [UNNotificationRequest] = triggers.map { (dateComponents) -> [UNNotificationRequest] in
                    let reminderRequests: [UNNotificationRequest] = reminders.compactMap { (reminderTimeInterval) -> UNNotificationRequest? in
                        let identifier = self.getLocalNotificationIdentifier(med, timeOfDay, dateComponents, reminderTimeInterval)
                        if pendingRequestIds.remove(where: { $0 == identifier }).count > 0 {
                            // If there is an unchanged pending request, then remove it from this list
                            // and do not create a new reminder for it.
                            return nil
                        }
                        else {
                            return self.createLocalNotification(med, timeOfDay, dateComponents, reminderTimeInterval)
                        }
                    }
                    return reminderRequests
                    }.flatMap { $0 }
                return triggerRequests
                }.flatMap { $0 }
            return scheduleRequests
            }.flatMap { $0 }
        
        return (requests, pendingRequestIds)
    }
    
    func getLocalNotificationIdentifier(_ medication: SBAMedicationAnswer, _ timeOfDay: String, _ dateComponents: DateComponents, _ reminderTimeInterval: Int) -> String {
        let weekday: String = {
            if let weekday = dateComponents.weekday, let dayCode = RSDWeekday(rawValue: weekday), let shortText = dayCode.shortText {
                return shortText
            }
            else {
                return "Daily"
            }
        }()
        return "\(medication.identifier) \(weekday) \(timeOfDay) \(reminderTimeInterval)"
    }
    
    func createLocalNotification(_ medication: SBAMedicationAnswer, _ timeOfDay: String, _ inDateComponents: DateComponents, _ reminderTimeInterval: Int) -> UNNotificationRequest {
        guard Thread.current.isMainThread else {
            var request: UNNotificationRequest!
            DispatchQueue.main.sync {
                request = self.createLocalNotification(medication, timeOfDay, inDateComponents, reminderTimeInterval)
            }
            return request
        }
        
        // Set up the notification
        let content = UNMutableNotificationContent()
        let medTitle = medication.shortText ?? medication.title ?? medication.identifier
        let reminder = Reminder(itemIdentifier: medication.identifier, timingIdentifier: timeOfDay)
        // TODO: syoung 08/10/2018 Figure out what the wording of the notification should be and localize.
        if let date = reminder.timeOfDay(on: now()) {
            let timeString = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
            content.body = "Take your \(medTitle) at \(timeString)"
        }
        content.sound = UNNotificationSound.default
        content.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber;
        content.categoryIdentifier = SBAMedicationNotificationCategory
        content.threadIdentifier = timeOfDay
        
        do {
            content.userInfo = try reminder.rsd_jsonEncodedDictionary()
        } catch let error {
            assertionFailure("Failed to encode the reminder. \(error)")
        }

        // Set the reminder
        var dateComponents = inDateComponents
        var minute = (dateComponents.minute ?? 0) - reminderTimeInterval
        var hour = dateComponents.hour ?? 0
        if minute < 0 {
            hour -= 1
            minute += 60
        }
        if hour < 0 {
            hour += 24
        }
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request.
        let identifier = self.getLocalNotificationIdentifier(medication, timeOfDay, dateComponents, reminderTimeInterval)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
    
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            let requestIds: [String] = requests.compactMap {
                guard $0.content.categoryIdentifier == SBAMedicationNotificationCategory else { return nil }
                return $0.identifier
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: requestIds)
        }
    }
    
    func addNotifications(for medicationResult: SBAMedicationTrackingResult) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (pendingRequests) in
            let filteredRequests = pendingRequests.filter { $0.content.categoryIdentifier == SBAMedicationNotificationCategory }
            let notifications = self.getLocalNotifications(for: medicationResult, with: filteredRequests)
            debugPrint("Update notifications: \(notifications)")
            if notifications.removeIds.count > 0 {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notifications.removeIds)
            }
            notifications.add.forEach {
                UNUserNotificationCenter.current().add($0)
            }
        }
    }
}
