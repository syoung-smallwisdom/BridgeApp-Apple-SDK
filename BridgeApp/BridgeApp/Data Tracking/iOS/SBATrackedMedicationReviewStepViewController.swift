//
//  SBATrackedMedicationReviewStepViewController.swift
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

open class SBATrackedMedicationReviewStepViewController: RSDTableStepViewController, RSDTaskViewControllerDelegate {
    
    open var reviewStep: SBATrackedItemsReviewStepObject? {
        return self.step as? SBATrackedItemsReviewStepObject
    }
    
    override open func registerReuseIdentifierIfNeeded(_ reuseIdentifier: String) {
        guard !_registeredIdentifiers.contains(reuseIdentifier) else { return }
        _registeredIdentifiers.insert(reuseIdentifier)

        if reuseIdentifier == SBATrackedMedicationReviewCell.reuseId {
            tableView.register(SBATrackedMedicationReviewCell.nib, forCellReuseIdentifier: reuseIdentifier)
        } else {
            super.registerReuseIdentifierIfNeeded(reuseIdentifier)
        }
    }
    private var _registeredIdentifiers = Set<String>()
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let reviewDataSource = self.tableData as? SBATrackedMedicationReviewDataSource {
            if let tableItem = reviewDataSource.tableItem(at: indexPath) as? RSDModalStepTableItem {
                let identifier = tableItem.identifier
                let detailStep = SBATrackedMedicationDetailStepObject(id: identifier)
                detailStep.title = identifier
                var navigator = RSDConditionalStepNavigatorObject(with: [detailStep])
                navigator.progressMarkers = []
                let task = RSDTaskObject(identifier: step.identifier, stepNavigator: navigator)
                let taskVc = RSDTaskViewController(task: task)
                taskVc.delegate = self
                
                // TODO: mdephillips 6/27/18 I wasn't able to pass the existing details result to the detail vc using this code below, how can i do that?
                if let source = tableData as? SBATrackedMedicationReviewDataSource,
                    let selectedMed = source.trackingResult().selectedAnswers[indexPath.row] as? SBAMedicationAnswer,
                    let dosageUnwrapped = selectedMed.dosage {
                    let existingDetailsResult = SBAMedicationDetailsResultObject(identifier: identifier)
                    existingDetailsResult.dosage = dosageUnwrapped
                    existingDetailsResult.schedules = selectedMed.scheduleItems
                    taskVc.taskPath.appendStepHistory(with: existingDetailsResult)
                }
                
                self.present(taskVc, animated: true, completion: nil)
            }
        }
    }
    
    override open func actionTapped(with actionType: RSDUIActionType) -> Bool {
        if actionType == .navigation(.goForward) {
            // TODO: mdephillips 6/27/18 move to med logging
            weak var weakSelf = self
            dismiss(animated: true, completion: {
                weakSelf?.dismiss(animated: true, completion: nil)
            })
            return true
        } else {
            return super.actionTapped(with: actionType)
        }
    }
    
    public func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        
        guard let reviewDataSource = self.tableData as? SBATrackedMedicationReviewDataSource else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        if reason == .completed {  // details added
            if let detailsResult = taskController.taskResult.stepHistory.last as? SBAMedicationDetailsResultObject {
                reviewDataSource.updateResults(with: detailsResult)
            }
            if let removeMedResult = taskController.taskResult.stepHistory.last as? SBARemoveMedicationResultObject {
                reviewDataSource.updateResults(byRemoving: removeMedResult.identifier)
            }
            updateUIToDetailsMode()
            // TODO: mdephillips 6/27/18 only reload the updated cell
            self.tableView.reloadData()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    public func updateUIToDetailsMode() {
        // Set the default values for the title and subtitle to display depending upon state.
        // TODO: mdephillips 6/19/18 localize in mPower strings file
        self.navigationHeader?.titleLabel?.text = Localization.localizedString("MEDICATION_LIST_TITLE")
    }
    
    public func taskController(_ taskController: RSDTaskController, readyToSave taskPath: RSDTaskPath) {
        // no-op
    }
    
    public func taskController(_ taskController: RSDTaskController, asyncActionControllerFor configuration: RSDAsyncActionConfiguration) -> RSDAsyncActionController? {
        // no-op
        return nil
    }
}

/// Table cell for logging tracked data.
open class SBATrackedMedicationReviewCell: RSDTableViewCell {
    
    public static let reuseId = "medicationReview"
    
    /// The nib to use with this cell. Default will instantiate a `SBATrackedLoggingCell`.
    open class var nib: UINib {
        let bundle = Bundle(for: SBATrackedMedicationReviewCell.self)
        let nibName = String(describing: SBATrackedMedicationReviewCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var cheveronView: UIImageView!
    
    /// Action button that is associated with this cell.
    @IBOutlet open var actionButton: UIButton!
    
    var loggedButton: RSDRoundedButton? {
        return self.actionButton as? RSDRoundedButton
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()

        self.loggedButton?.isSecondaryButton = false
        self.loggedButton?.usesLightStyle = false

        self.actionButton.setTitle(Localization.localizedString("BUTTON_EDIT"), for: .normal)
    }
    
    override open var tableItem: RSDTableItem! {
        didSet {
            guard let medItem = tableItem as? SBATrackedMedicationReviewItem
                else {
                    return
            }
            
            if let dosageUnwrapped = medItem.medication.dosage {
                self.titleLabel.text = String(format: "%@ %@", medItem.medication.identifier, dosageUnwrapped)
                if let schedules = medItem.medication.scheduleItems {
                    var timeStr = ""
                    if schedules.first?.scheduleAtAnytime ?? false == true {
                        timeStr = Localization.localizedString("MEDICATION_ANYTIME")
                    } else {
                        let timeArray = schedules.filter({ $0.weeklyScheduleObject.timeOfDayString != nil })
                            .map({ (schedule) -> String in
                                let time = RSDDateCoderObject.hourAndMinutesOnly.inputFormatter.date(from: schedule.weeklyScheduleObject.timeOfDayString!) ?? Date()
                                return DateFormatter.localizedString(from: time, dateStyle: .none, timeStyle: .short)
                            })
                        timeStr = timeArray.joined(separator: ", ")
                    }
                    
                    var weekdaySet: Set<RSDWeekday> = Set()
                    for schedule in schedules {
                        for weekday in schedule.weeklyScheduleObject.daysOfWeek {
                            weekdaySet.insert(weekday)
                        }
                    }
                    let weekdayStr = SBATrackedWeeklyScheduleCell.weekdayTitle(for: Array(weekdaySet))
                    self.detailLabel.text = String(format: "%@\n%@", timeStr, weekdayStr)
                }
                self.actionButton.isHidden = false
                self.cheveronView.isHidden = true
            } else {
                self.titleLabel.text = medItem.medication.identifier
                self.detailLabel.text = nil
                self.actionButton.isHidden = true
                self.cheveronView.isHidden = false
            }
        }
    }
}
