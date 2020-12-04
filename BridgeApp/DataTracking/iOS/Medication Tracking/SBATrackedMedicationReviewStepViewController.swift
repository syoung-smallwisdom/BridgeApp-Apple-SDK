//
//  SBATrackedMedicationReviewStepViewController.swift
//  BridgeApp
//
//  Copyright © 2018-2019 Sage Bionetworks. All rights reserved.
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
import Research
import ResearchUI

extension SBATrackedMedicationReviewStepObject : RSDStepViewControllerVendor {
}

open class SBATrackedMedicationReviewStepViewController: SBAMedicationListStepViewController {

    /// Shoehorn in using the learn more to add medication b/c the new design has the "Add a medication"
    /// button in the place where typically this should be a "learn more" action. syoung 06/11/2019
    override open func showLearnMore() {
        let action = RSDUIActionObject(buttonTitle: Localization.localizedString("MEDICATION_ADD_BUTTON"))
        let tableItem = SBAModalSelectionTableItem(identifier: RSDUIActionType.addMore.stringValue,
                                                   rowIndex: 0,
                                                   reuseIdentifier: RSDFormUIHint.button.stringValue,
                                                   action: action)
        self.didSelectModalItem(tableItem, at: IndexPath(item: 0, section: 1))
    }
    
    override open func goForward() {
        // If saving, then check that the med result doesn't yet have reminders set. That means that this is a
        // "first time" set-up of the medications, in which case either logging or set reminders will come next.
        // Ask the user which to show.
        guard let medResult = self.stepViewModel.findStepResult() as? SBAMedicationTrackingResult,
            medResult.reminders == nil
            else {
                super.goForward()
                return
        }
        
        guard medResult.hasMedicationsToLog(at: Date()) else {
            // If there are no meds to log right now then do not show logging.
            self.assignSkipToIdentifier(SBATrackedItemsStepNavigator.StepIdentifiers.reminder.stringValue)
            super.goForward()
            return
        }
        
        var actions: [UIAlertAction] = []

        // Always add a choice to discard the results.
        let logging = UIAlertAction(title: Localization.localizedString("MEDICATION_RECORD_TODAY_YES"), style: .default) { (_) in
            // Default is to show logging.
            self.assignSkipToIdentifier(SBATrackedItemsStepNavigator.StepIdentifiers.logging.stringValue)
            super.goForward()
        }
        actions.append(logging)
        
        // Always add a choice to keep going.
        let doneAdding = UIAlertAction(title: Localization.localizedString("MEDICATION_RECORD_TODAY_NO"), style: .cancel) { (_) in
            // If the user does not want to log meds, then take them to reminders.
            self.assignSkipToIdentifier(SBATrackedItemsStepNavigator.StepIdentifiers.reminder.stringValue)
            super.goForward()
        }
        actions.append(doneAdding)
        
        self.presentAlertWithActions(title: nil, message: Localization.localizedString("MEDICATION_RECORD_TODAY_QUESTION"), preferredStyle: .actionSheet, actions: actions)
    }
    
    /// Tapping the skip button should exit the task.
    override open func skipForward() {
        self.assignSkipToIdentifier(RSDIdentifier.exit.stringValue)
        self.goForward()
    }
    
    /// Override viewWillAppear to always check if the "Add details later" button should be shown.
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let source = self.stepViewModel as? SBATrackedMedicationReviewDataSource {
            let allValid = source.allAnswersValid()
            self.navigationFooter!.isSkipHidden = allValid || source.trackingResult().selectedAnswers.count == 0
            self.navigationFooter!.nextButton?.isEnabled = allValid
        }
    }
}

open class SBAMedicationListStepViewController: RSDTableStepViewController {
    
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
        guard let tableItem = self.tableData?.tableItem(at: indexPath) as? SBATrackedMedicationReviewItem
            else {
                super.tableView(tableView, didSelectRowAt: indexPath)
                return
        }

        tableView.deselectRow(at: indexPath, animated: true)
        showMedicationDetails(for: tableItem)
    }
    
    func showMedicationDetails(for tableItem: SBATrackedMedicationReviewItem) {
        
        let storyboard = UIStoryboard(name: "Medication", bundle: Bundle.module)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "MedicationEditDetails") as? SBAMedicationEditDetailsViewController
            else {
                assertionFailure("Failed to instantiate expected view controller")
                return
        }
        vc.delegate = self
        vc.medication = tableItem.medication
        vc.designSystem = self.designSystem
        self.present(vc, animated: true) {
        }
    }
    
    open override func configure(cell: UITableViewCell, in tableView: UITableView, at indexPath: IndexPath) {
        super.configure(cell: cell, in: tableView, at: indexPath)
        if let reviewCell = cell as? SBATrackedMedicationReviewCell {
            reviewCell.controller = self
        }
    }
}

extension SBAMedicationListStepViewController: SBAMedicationEditDetailsViewControllerDelegate {
    
    func save(_ medication: SBAMedicationAnswer, from sender: SBAMedicationEditDetailsViewController) {
        if let dataSource = self.tableData as? SBAMedicationLoggingDataSource {
            dataSource.saveMedication(medication)
            self.tableView.reloadData()
        }
        else {
            assertionFailure("Data source not of expected type")
        }
        sender.dismiss(animated: true, completion: nil)
    }
    
    func delete(_ medication: SBAMedicationAnswer, from sender: SBAMedicationEditDetailsViewController) {
        if let dataSource = self.tableData as? SBAMedicationLoggingDataSource,
            let item = dataSource.tableItem(for: medication) {
            self.tableView.beginUpdates()
            let indexPath = item.indexPath
            dataSource.removeMedication(at: item)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.tableView.endUpdates()
        }
        else {
            assertionFailure("Data source not of expected type")
        }
        self.dismiss(animated: true, completion: nil)
    }
}

/// Table cell for displaying medication information to review.
open class SBATrackedMedicationReviewCell: RSDSelectionTableViewCell {
    
    public static let reuseId = "medicationReview"
    
    weak var controller: SBAMedicationListStepViewController?
    
    /// The nib to use with this cell. Default will instantiate a `SBATrackedMedicationReviewCell`.
    open class var nib: UINib {
        let bundle = Bundle.module
        let nibName = String(describing: SBATrackedMedicationReviewCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
    
    @IBOutlet open var editButton: UIButton!
    @IBOutlet weak var addDetailsButton: RSDRoundedButton!
    
    @IBAction func editTapped(_ sender: Any) {
        guard let medItem = tableItem as? SBATrackedMedicationReviewItem else { return }
        controller?.showMedicationDetails(for: medItem)
    }
    
    @IBAction func addDetailsTapped(_ sender: Any) {
        guard let medItem = tableItem as? SBATrackedMedicationReviewItem else { return }
        controller?.showMedicationDetails(for: medItem)
    }
    
    override open var tableItem: RSDTableItem! {
        didSet {
            guard let medItem = tableItem as? SBATrackedMedicationReviewItem
                else {
                    return
            }
            
            self.titleLabel?.text = medItem.medication.title ?? medItem.medication.identifier
            self.editButton.setTitle(Localization.localizedString("MEDICATION_EDIT_DETAILS"), for: .normal)
            self.addDetailsButton.setTitle(Localization.localizedString("MEDICATION_ADD_DETAILS"), for: .normal)
            
            let hasDetails = medItem.medication.hasRequiredValues
            self.editButton.isHidden = !hasDetails
            self.addDetailsButton.isHidden = hasDetails
            if hasDetails {
                let doseCount = medItem.medication.dosageItems?.count ?? 0
                let formatString : String = NSLocalizedString("MEDICATION_DOSES",
                                                              tableName: "BridgeApp",
                                                              bundle: Bundle.module,
                                                              value: "%u doses",
                                                              comment: "Number of doses of medication")
                self.detailLabel?.text = String.localizedStringWithFormat(formatString, doseCount)
            } else {
                self.detailLabel?.text = nil
            }
        }
    }
    
    override open var titleTextType: RSDDesignSystem.TextType {
        return .mediumHeader
    }
}
