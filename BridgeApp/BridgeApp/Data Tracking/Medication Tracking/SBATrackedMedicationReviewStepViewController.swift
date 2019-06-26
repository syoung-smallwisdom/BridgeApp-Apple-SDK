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

extension SBATrackedMedicationReviewStepObject : RSDStepViewControllerVendor {
}

open class SBATrackedMedicationReviewStepViewController: RSDTableStepViewController {
    
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
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyboard = UIStoryboard(name: "Medication", bundle: Bundle(for: SBAMedicationEditDetailsViewController.self))
        if let vc = storyboard.instantiateViewController(withIdentifier: "MedicationEditDetails") as? SBAMedicationEditDetailsViewController,
            let tableItem = self.tableData?.tableItem(at: indexPath) as? SBATrackedMedicationReviewItem {
            vc.delegate = self
            vc.medication = tableItem.medication
            vc.designSystem = self.designSystem
            self.present(vc, animated: true) {
            }
        }
    }
    
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
    
    /// Skip behavior should just do the same thing as "Save".
    override open func skipForward() {
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

extension SBATrackedMedicationReviewStepViewController: SBAMedicationEditDetailsViewControllerDelegate {
    
    func save(_ medication: SBAMedicationAnswer, from sender: SBAMedicationEditDetailsViewController) {
        if let dataSource = self.tableData as? SBATrackedMedicationReviewDataSource,
            let item = dataSource.tableItem(for: medication) {
            dataSource.saveMedication(medication, to: item)
            self.tableView.reloadRows(at: [item.indexPath], with: .automatic)
        }
        else {
            assertionFailure("Data source not of expected type")
        }
        sender.dismiss(animated: true, completion: nil)
    }
    
    func delete(_ medication: SBAMedicationAnswer, from sender: SBAMedicationEditDetailsViewController) {
        if let dataSource = self.tableData as? SBATrackedMedicationReviewDataSource,
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
    
    /// The nib to use with this cell. Default will instantiate a `SBATrackedMedicationReviewCell`.
    open class var nib: UINib {
        let bundle = Bundle(for: SBATrackedMedicationReviewCell.self)
        let nibName = String(describing: SBATrackedMedicationReviewCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
    
    @IBOutlet open var actionButton: UIButton!
    
    override open var tableItem: RSDTableItem! {
        didSet {
            guard let medItem = tableItem as? SBATrackedMedicationReviewItem
                else {
                    return
            }
            
            self.titleLabel?.text = medItem.medication.identifier
            if medItem.medication.hasRequiredValues {
                self.actionButton.setTitle(Localization.localizedString("MEDICATION_EDIT_DETAILS"), for: .normal)
                
                let doseCount = medItem.medication.dosageItems?.count ?? 0
                let formatString : String = NSLocalizedString("MEDICATION_DOSES",
                                                              tableName: "BridgeApp",
                                                              bundle: Bundle(for: SBATrackedMedicationReviewCell.self),
                                                              value: "%u doses",
                                                              comment: "Number of doses of medication")
                self.detailLabel?.text = String.localizedStringWithFormat(formatString, doseCount)
            } else {
                self.actionButton.setTitle(Localization.localizedString("MEDICATION_ADD_DETAILS"), for: .normal)
                self.detailLabel?.text = nil
            }
        }
    }
    
    override open var titleTextType: RSDDesignSystem.TextType {
        return .heading4
    }
}
