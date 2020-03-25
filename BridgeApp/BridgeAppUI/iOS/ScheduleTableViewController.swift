//
//  ScheduleTableViewController.swift
//  BridgeAppUI (iOS)
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

import UIKit

open class ScheduleTableViewController: UITableViewController, RSDTaskViewControllerDelegate {

    public var designSystem: RSDDesignSystem = RSDDesignSystem.shared
    
    public var scheduleManager: AssessmentScheduleManager = SBAScheduleManager() {
        didSet {
            guard isViewLoaded else { return }
            _setupChangesObserver()
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        _setupChangesObserver()
    }
    
    private func _setupChangesObserver() {
        if let observer = _changesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        _changesObserver = NotificationCenter.default.addObserver(forName: .SBAUpdatedScheduledActivities, object: scheduleManager, queue: OperationQueue.main) { (notification) in
            self.tableView.reloadData()
        }
        scheduleManager.reloadData()
    }
    private var _changesObserver : Any?

    // MARK: Table data source

    override open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scheduleManager.assessmentSchedules.count
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let schedule = scheduleManager.assessmentSchedules[indexPath.row]
        let taskInfo = schedule.taskInfo
        let completed = scheduleManager.isCompleted(for: taskInfo, on: Date())
        let expired = !completed && schedule.isExpired
        let available = !completed && schedule.isAvailableNow
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
        cell.accessoryType = completed ? .checkmark : .none
        cell.textLabel?.text = schedule.taskInfo.title ?? schedule.taskInfo.identifier
        let textColor = available ?
            designSystem.colorRules.palette.text.dark.color :
            designSystem.colorRules.palette.text.normal.color
        cell.textLabel?.textColor = textColor
        cell.detailTextLabel?.text = schedule.availabilityLabel
        cell.detailTextLabel?.textColor = expired ? designSystem.colorRules.palette.errorRed.normal.color : textColor
        if let imageView = cell.imageView, let imageData = taskInfo.imageData as? RSDResourceImageData {
            imageView.image = imageData.embeddedImage(using: designSystem, compatibleWith: traitCollection)
        }
        return cell
    }

    // MARK: Table delegate
    
    override open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let schedule = scheduleManager.assessmentSchedules[indexPath.row]
        let taskInfo = schedule.taskInfo
        let completed = scheduleManager.isCompleted(for: taskInfo, on: Date())
        let selectable = schedule.isAvailableNow && !completed
        return selectable ? indexPath : nil
    }

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let taskPath = scheduleManager.instantiateTaskViewModel(for: scheduleManager.assessmentSchedules[indexPath.row])
        let vc = RSDTaskViewController(taskViewModel: taskPath)
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    // MARK: RSDTaskViewControllerDelegate

    public func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        scheduleManager.taskController(taskController, didFinishWith: reason, error: error)
        // dismiss the view controller
        (taskController as? UIViewController)?.dismiss(animated: true) {
        }
    }

    public func taskController(_ taskController: RSDTaskController, readyToSave taskViewModel: RSDTaskViewModel) {
        scheduleManager.taskController(taskController, readyToSave: taskViewModel)
    }
}
