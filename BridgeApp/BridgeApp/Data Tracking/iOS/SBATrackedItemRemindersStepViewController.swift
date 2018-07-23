//
//  SBATrackedItemRemindersStepViewController.swift
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

/// `SBATrackedItemRemindersStepViewController` contains a prompt butotn cell that
/// shows a form step view controller with the input fields from the form step.
///
/// - seealso: `RSDTableStepViewController`, `SBARemoveTrackedItemsResultObject`, `SBATrackedItemRemindersStepObject`
open class SBATrackedItemRemindersStepViewController: RSDTableStepViewController {
    
    public var reminderStep: SBATrackedItemRemindersStepObject? {
        return self.step as? SBATrackedItemRemindersStepObject
    }

    override open func registerReuseIdentifierIfNeeded(_ reuseIdentifier: String) {
        guard !_registeredIdentifiers.contains(reuseIdentifier) else { return }
        _registeredIdentifiers.insert(reuseIdentifier)
        
        if reuseIdentifier == RSDFormUIHint.modalButton.rawValue {
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
}

extension SBATrackedItemRemindersStepViewController: RSDTaskViewControllerDelegate {
    public func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
    public func taskController(_ taskController: RSDTaskController, readyToSave taskPath: RSDTaskPath) {
        if let dataSource = self.tableData as? SBATrackedItemReminderDataSource {
            dataSource.updateAnswer(from: taskPath, with: taskController.taskResult.identifier)
            self.tableView.reloadData()
        }
    }
    
    public func taskController(_ taskController: RSDTaskController, asyncActionControllerFor configuration: RSDAsyncActionConfiguration) -> RSDAsyncActionController? {
        return nil
    }
}

/// `SBATrackedItemRemindersStepObject` is a wrapped form step view controller
/// that contains a custom cell type that will launch the input fields of the step.
///
/// - seealso: `RSDFormUIStepObject`, `RSDStepViewControllerVendor`
open class SBATrackedItemRemindersStepObject: RSDFormUIStepObject, RSDStepViewControllerVendor {
    
    enum CodingKeys : String, CodingKey {
        case modalTitle, descriptionFormat, noReminderSetText
    }
    
    public let modalIdentifier = "ReminderModal"
    
    /// The title of the modal for selecting reminders.
    public var modalTitle: String
    
    /// The string format for the description of the selected reminder values.
    public var descriptionFormat: String
    
    /// The string format for the description of the selected reminder values.
    public var noReminderSetText: String
    
    /// The first input field's prompt.
    var prompt: String? {
        return (self.inputFields.first as? RSDInputFieldObject)?.inputPrompt
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let modalTitle = try container.decodeIfPresent(String.self, forKey: .modalTitle)
        self.modalTitle = modalTitle ?? Localization.localizedString("TRACKED_ITEM_REMINDER_MODAL_TITLE")
        let descriptionFormat = try container.decodeIfPresent(String.self, forKey: .descriptionFormat)
        self.descriptionFormat = descriptionFormat ?? "%@"
        let noReminderSetText = try container.decodeIfPresent(String.self, forKey: .noReminderSetText)
        self.noReminderSetText = noReminderSetText ?? Localization.localizedString("TRACKED_REMINDER_CHOICES_NONE_SET")
        try super.init(from: decoder)
    }
    
    public required init(identifier: String, type: RSDStepType?) {
        self.modalTitle = Localization.localizedString("TRACKED_ITEM_REMINDER_MODAL_TITLE")
        self.descriptionFormat = "%@"
        self.noReminderSetText = Localization.localizedString("TRACKED_REMINDER_CHOICES_NONE_SET")
        super.init(identifier: identifier, type: type)
    }
    
    override public init(identifier: String, inputFields: [RSDInputField], type: RSDStepType? = nil) {
        self.modalTitle = Localization.localizedString("TRACKED_ITEM_REMINDER_MODAL_TITLE")
        self.descriptionFormat = "%@"
        self.noReminderSetText = Localization.localizedString("TRACKED_REMINDER_CHOICES_NONE_SET")
        super.init(identifier: identifier, type: type ?? .form)
    }
    
    /// Override to return a `SBATrackedItemReminderDataSource`.
    open override func instantiateDataSource(with taskPath: RSDTaskPath, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBATrackedItemReminderDataSource(step: self, taskPath: taskPath, supportedHints: supportedHints)
    }

    public func instantiateViewController(with taskPath: RSDTaskPath) -> (UIViewController & RSDStepController)? {
        return SBATrackedItemRemindersStepViewController(step: self)
    }
    
    override open func copyInto(_ copy: RSDUIStepObject) {
        super.copyInto(copy)
        guard let subclassCopy = copy as? SBATrackedItemRemindersStepObject else {
            assertionFailure("Superclass implementation of the `copy(with:)` protocol should return an instance of this class.")
            return
        }
        subclassCopy.modalTitle = self.modalTitle
        subclassCopy.descriptionFormat = self.descriptionFormat
        subclassCopy.noReminderSetText = self.noReminderSetText
    }

    /// Returns the reminder choice step
    public func reminderChoicesStep() -> RSDStep? {
        let identifier = String(describing: modalIdentifier)
        let formStep = RSDFormUIStepObject(identifier: identifier, inputFields: self.inputFields)
        formStep.title = self.modalTitle
        formStep.actions = [.navigation(.goForward) : RSDUIActionObject(buttonTitle: Localization.localizedString("BUTTON_SAVE"))]
        return formStep
    }
}

/// `SBATrackedItemReminderDataSource` manages the reminder answer and building the table data sections.
///
/// - seealso: `RSDFormStepDataSourceObject`
open class SBATrackedItemReminderDataSource : RSDFormStepDataSourceObject {
    
    fileprivate var reminderStep: SBATrackedItemRemindersStepObject? {
        return self.step as? SBATrackedItemRemindersStepObject
    }
    
    override open func bulidSections() -> ([RSDTableSection], [RSDTableItemGroup]) {
        let item = RSDTableItem(identifier: self.step.identifier, rowIndex: 0, reuseIdentifier: RSDFormUIHint.modalButton.rawValue)
        let section = RSDTableSection(identifier: self.step.identifier, sectionIndex: 0, tableItems: [item])
        let group = RSDTableItemGroup(beginningRowIndex: 0, items: [item])
        return ([section], [group])
    }
    
    func updateAnswer(to result: RSDCollectionResultObject) {
        self.taskPath.appendStepHistory(with: result)
    }
    
    func updateAnswer(from modalTaskPath: RSDTaskPath, with stepIdentifier: String?) {
        if let modalStepIdentifier = stepIdentifier,
            let collectionResult = modalTaskPath.result.findResult(with: modalStepIdentifier) as? RSDCollectionResultObject {
            return self.updateAnswer(to: collectionResult.copy(with: self.step.identifier))
        }
    }
    
    /// - parameter result: The most recent result
    /// - returns : The description of the selected reminders.
    open func reminderDescription() -> String? {
        guard let answerResult = self.collectionResult().inputResults.last as? RSDAnswerResultObject else {
            return self.reminderStep?.noReminderSetText
        }
        if let reminderValues = answerResult.value as? [Any],
            reminderValues.count > 0 {
            let reminderValuesStr = Localization.localizedAndJoin(reminderValues.map({ "\($0)" }))
            if let descriptionFormat = self.reminderStep?.descriptionFormat {
                return String(format: descriptionFormat, reminderValuesStr)
            } else {
                return reminderValuesStr
            }
        }
        return self.reminderStep?.noReminderSetText
    }
    
    func modalTaskViewController() -> RSDTaskViewController? {
        guard let reminderChoicesStep = self.reminderStep?.reminderChoicesStep() else { return nil }
        var navigator = RSDConditionalStepNavigatorObject(with: [reminderChoicesStep])
        navigator.progressMarkers = []
        let task = RSDTaskObject(identifier: reminderChoicesStep.identifier, stepNavigator: navigator)
        let taskPath = RSDTaskPath(task: task)
        if let result = self.collectionResult() as? RSDCollectionResultObject {
            taskPath.appendStepHistory(with: result.copy(with: reminderChoicesStep.identifier))
        }
        return RSDTaskViewController(taskPath: taskPath)
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
