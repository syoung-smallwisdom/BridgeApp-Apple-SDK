//
//  SBAMedicationRemindersViewController.swift
//  mPower2
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

open class SBAMedicationRemindersStepViewController: RSDTableStepViewController {
    
    public var reminderStep: SBAMedicationRemindersStepObject? {
        return self.step as? SBAMedicationRemindersStepObject
    }

    override open func registerReuseIdentifierIfNeeded(_ reuseIdentifier: String) {
        guard !_registeredIdentifiers.contains(reuseIdentifier) else { return }
        _registeredIdentifiers.insert(reuseIdentifier)
        
        let reuseId = RSDFormUIHint(rawValue: reuseIdentifier)
        switch reuseId {
        case .modalButton:
            tableView.register(SBATrackedModalButtonCell.nib, forCellReuseIdentifier: reuseIdentifier)
            break
        default:
            super.registerReuseIdentifierIfNeeded(reuseIdentifier)
            break
        }
    }
    private var _registeredIdentifiers = Set<String>()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        // See if we don't currently have any reminder intervals saved, if so, set a default "do not remind me" state
        if intervals(from: taskController.taskPath, stepIdentifier: self.step.identifier) == nil {
            update(taskPath: taskController.taskPath, with: [], for: self.step.identifier)
            super.answersDidChange(in: 0)
        }
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Get the cell from super and update the label with the cancatenation of our current reminder intervals
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let labelString: String = {
            if let intervals = intervals(from: taskController.taskPath, stepIdentifier: self.step.identifier), intervals.count > 0 {
                return String(format: Localization.localizedString("MEDICATION_REMINDER_CHOICES_%@"), Localization.localizedAndJoin(intervals.compactMap { return String($0) }))
            }
            else {
                return Localization.localizedString("MEDICATION_REMINDER_CHOICES_NONE_SET")
            }
        }()
        if let modalCell = cell as? SBATrackedModalButtonCell {
            modalCell.delegate = self
            modalCell.promptLabel.text = Localization.localizedString("MEDICATION_REMINDER_ADD")
            modalCell.actionButton.setTitle(labelString, for: .normal)
        }
        return cell
    }
    
    override open func didTapButton(on cell: RSDButtonCell) {
        self.showReminderDetailsTask()
    }
    
    func intervals(from taskPath: RSDTaskPath, stepIdentifier: String) -> [Int]? {
        guard let stepResult = taskPath.result.findResult(with: stepIdentifier) else { return nil }
        let aResult = (stepResult as? RSDCollectionResult)?.inputResults.first ?? stepResult
        return (aResult as? RSDAnswerResult)?.value as? [Int]
    }
    
    func showReminderDetailsTask() {

        guard let reminderChoicesStep = self.reminderStep?.reminderChoicesStep() else { return }
        
        // Instantiate and create the reminder details task
        var navigator = RSDConditionalStepNavigatorObject(with: [reminderChoicesStep])
        navigator.progressMarkers = []
        let task = RSDTaskObject(identifier: step.identifier, stepNavigator: navigator)
        let taskPath = RSDTaskPath(task: task)

        // See if we currently have any reminder intervals saved and, if so, add them to the result
        // for our new task so they are prepopulated for the user
        if let intervals = intervals(from: taskController.taskPath, stepIdentifier: self.step.identifier),
            intervals.count > 0  {
            update(taskPath: taskPath, with: intervals, for: reminderChoicesStep.identifier)
        }

        let vc = RSDTaskViewController(taskPath: taskPath)
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    func update(taskPath: RSDTaskPath, with intervals: [Int], for stepIdentifier: String) {
        
        var previousResult = RSDCollectionResultObject(identifier: stepIdentifier)
        var answerResult = RSDAnswerResultObject(identifier: stepIdentifier,
                                                 answerType: RSDAnswerResultType(baseType: .integer,
                                                                                 sequenceType: .array,
                                                                                 formDataType: .collection(.multipleChoice, .integer),
                                                                                 dateFormat: nil,
                                                                                 unit: nil,
                                                                                 sequenceSeparator: nil))
        answerResult.value = intervals
        previousResult.inputResults = [answerResult]
        taskPath.appendStepHistory(with: previousResult)
    }
}

extension SBAMedicationRemindersStepViewController: RSDTaskViewControllerDelegate {
    public func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
    public func taskController(_ taskController: RSDTaskController, readyToSave taskPath: RSDTaskPath) {
        if let intervals = intervals(from: taskPath, stepIdentifier: SBAMedicationRemindersStepObject.CodingKeys.reminderChoices.stringValue) {
            // Update our current task results with the intervals selected by the user
            update(taskPath: self.taskController.taskPath, with: intervals, for: self.step.identifier)
            tableView.reloadData()
            self.answersDidChange(in: 0)
        }
    }

    public func taskController(_ taskController: RSDTaskController, asyncActionControllerFor configuration: RSDAsyncActionConfiguration) -> RSDAsyncActionController? {
        return nil
    }
}

open class SBAMedicationRemindersStepObject: RSDUIStepObject, RSDFormUIStep, RSDStepViewControllerVendor {
    
    enum CodingKeys : String, CodingKey {
        case reminderChoices
    }
    
    public var reminderChoices: [RSDChoiceObject<Int>]?
    
    open var inputFields: [RSDInputField] {
        let dataType = RSDFormDataType.collection(.multipleChoice, .integer)
        let inputField = RSDInputFieldObject(identifier: RSDFormUIHint.modalButton.rawValue, dataType: dataType, uiHint: .modalButton, prompt: Localization.localizedString("MEDICATION_REMINDER_ADD"))
        inputField.isOptional = true
        return [inputField]
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let reminderChoices = try container.decode([RSDChoiceObject<Int>].self, forKey: .reminderChoices)
        self.reminderChoices = reminderChoices
    }
    
    public required init(identifier: String, type: RSDStepType?) {
        super.init(identifier: identifier, type: type)
    }
    
    public func instantiateViewController(with taskPath: RSDTaskPath) -> (UIViewController & RSDStepController)? {
        return SBAMedicationRemindersStepViewController(step: self)
    }
    
    override open func copyInto(_ copy: RSDUIStepObject) {
        super.copyInto(copy)
        guard let subclassCopy = copy as? SBAMedicationRemindersStepObject else {
            assertionFailure("Superclass implementation of the `copy(with:)` protocol should return an instance of this class.")
            return
        }
        subclassCopy.reminderChoices = self.reminderChoices
    }
    
    /// Returns the reminder choice step
    public func reminderChoicesStep() -> RSDStep? {
        guard let reminderChoicesUnwrapped = self.reminderChoices else { return nil }
        let identifier = String(describing: CodingKeys.reminderChoices.stringValue)
        let dataType = RSDFormDataType.collection(.multipleChoice, .integer)
        let inputField = RSDChoiceInputFieldObject(identifier: identifier, choices: reminderChoicesUnwrapped, dataType: dataType)
        let formStep = RSDFormUIStepObject(identifier: identifier, inputFields: [inputField])
        let formTitle = String(format: Localization.localizedString("MEDICATION_REMINDER_CHOICES_TITLE"))
        formStep.title = formTitle
        formStep.actions = [.navigation(.goForward) : RSDUIActionObject(buttonTitle: Localization.localizedString("BUTTON_SAVE"))]
        return formStep
    }
}

open class SBATrackedModalButtonCell : RSDButtonCell {
    
    @IBOutlet weak var promptLabel: UILabel!
    
    /// The nib to use with this cell. Default will instantiate a `SBATrackedMedicationDetailCell`.
    open class var nib: UINib {
        let bundle = Bundle(for: SBATrackedModalButtonCell.self)
        let nibName = String(describing: SBATrackedModalButtonCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
}
