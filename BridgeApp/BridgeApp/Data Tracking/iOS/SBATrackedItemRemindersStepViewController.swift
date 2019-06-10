//
//  SBATrackedItemRemindersStepViewController.swift
//  BridgeApp (iOS)
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

import UIKit
import UserNotifications


/// `SBATrackedItemRemindersStepViewController` contains a prompt butotn cell that
/// shows a form step view controller with the input fields from the form step.
///
/// - seealso: `RSDTableStepViewController`, `SBATrackedItemRemindersStepObject`
open class SBATrackedItemRemindersStepViewController: RSDTableStepViewController {
    
    public var reminderStep: SBATrackedItemRemindersStepObject? {
        return self.step as? SBATrackedItemRemindersStepObject
    }

    override open func registerReuseIdentifierIfNeeded(_ reuseIdentifier: String) {
        guard !_registeredIdentifiers.contains(reuseIdentifier) else { return }
        _registeredIdentifiers.insert(reuseIdentifier)
        
        if reuseIdentifier == RSDFormUIHint.button.rawValue {
            tableView.register(SBATrackedReminderModalButtonCell.nib, forCellReuseIdentifier: reuseIdentifier)
        } else {
            super.registerReuseIdentifierIfNeeded(reuseIdentifier)
        }
    }
    private var _registeredIdentifiers = Set<String>()

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let modalCell = cell as? SBATrackedReminderModalButtonCell {
            modalCell.delegate = self
            modalCell.promptLabel.text = self.reminderStep?.prompt
            if let dataSource = self.tableData as? SBATrackedItemReminderDataSource {
                modalCell.actionButton.setTitle(dataSource.reminderDescription(), for: .normal)
            }
        }
        return cell
    }
    
    override open func didTapButton(on cell: RSDButtonCell) {
        if let dataSource = self.tableData as? SBATrackedItemReminderDataSource,
            let vc = dataSource.modalTaskViewController() {
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    open override func goForward() {
        
        let shouldSetReminder : Bool = {
            guard let stepResult = self.stepViewModel.taskResult.findResult(for: self.step),
                let value = stepResult.firstAnswerResult()?.value
                else {
                    return false
            }
            return ((value as? [Any])?.count ?? 1) > 0
        }()
        
        // Check if there is a no reminders flag to **not** set the local notification.
        if shouldSetReminder {
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, _) in
                DispatchQueue.main.async {
                    if !granted {
                        // TODO: syoung 07/19/2018 Localize and word-smith
                        self.presentAlertWithOk(title: nil, message: "You have turned off notifications. To allow us to remind you, you will need to change this from the Settings app.", actionHandler: { (_) in
                            super.goForward()
                        })
                    }
                    else {
                        super.goForward()
                    }
                }
            }
        }
        else {
            super.goForward()
        }
    }
    
    override open func taskController(_ taskController: RSDTaskController, readyToSave taskViewModel: RSDTaskViewModel) {
        if let dataSource = self.tableData as? SBATrackedItemReminderDataSource {
            dataSource.updateAnswer(from: taskViewModel, with: taskViewModel.taskResult.identifier)
            self.tableView.reloadData()
        }
    }
}

open class SBATrackedReminderModalButtonCell : RSDButtonCell {
    
    @IBOutlet weak var promptLabel: UILabel!
    
    /// The nib to use with this cell. Default will instantiate a `SBATrackedModalButtonCell`.
    open class var nib: UINib {
        let bundle = Bundle(for: SBATrackedReminderModalButtonCell.self)
        let nibName = String(describing: SBATrackedReminderModalButtonCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
}

extension RSDResult {
    
    func firstAnswerResult() -> RSDAnswerResult? {
        return ((self as? RSDCollectionResult)?.inputResults.first ?? self) as? RSDAnswerResult
    }
}
