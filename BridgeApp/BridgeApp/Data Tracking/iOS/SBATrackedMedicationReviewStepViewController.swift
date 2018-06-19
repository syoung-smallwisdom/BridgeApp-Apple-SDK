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
        if let reviewDataSource = self.tableData as? SBATrackedMedicationReviewDataSource {
            if let tableItem = reviewDataSource.tableItem(at: indexPath) as? RSDModalStepTableItem {
                let identifier = tableItem.identifier
                
                let detailStep = SBATrackedMedicationDetailStepObject(id: identifier)
                detailStep.title = identifier
                detailStep.detail = "Remove medication"
                let taskVc = SBATrackedMedicationDetailStepViewController(step: detailStep)
                var navigator = RSDConditionalStepNavigatorObject(with: [detailStep])
                navigator.progressMarkers = []
                let task = RSDTaskObject(identifier: step.identifier, stepNavigator: navigator)
                self.taskPath = RSDTaskPath(task: task)
                taskVc.taskController = self
                self.present(taskVc, animated: true, completion: nil)
            }
        }
    }
}

extension SBATrackedMedicationReviewStepViewController : RSDTaskController {
    public var taskPath: RSDTaskPath! {
        get {
            return self.taskController.taskPath
        }
        set(newValue) {
            
        }
    }
    
    public var canSaveTaskProgress: Bool {
        return false
    }
    
    public func handleTaskCancelled(shouldSave: Bool) {
        
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
    
    /// The target selector for tapping the button.
    @IBAction func buttonTapped() {
        
    }

    /// Override to set the content view background color to the color of the table background.
    override open var tableBackgroundColor: UIColor! {
        didSet {
            self.contentView.backgroundColor = tableBackgroundColor
        }
    }
    
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
            guard let loggingItem = tableItem as? SBATrackedMedicationReviewItem
                else {
                    return
            }
            
            self.titleLabel.text = loggingItem.loggedResult.identifier
            
            self.detailLabel.text = loggingItem.details
            if loggingItem.details != nil {
                self.actionButton.isHidden = false
                self.cheveronView.isHidden = true
            } else {
                self.actionButton.isHidden = true
                self.cheveronView.isHidden = false
            }
        }
    }
}
