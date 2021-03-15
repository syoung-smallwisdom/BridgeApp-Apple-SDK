//
//  SBATrackedItemRemindersStepObject.swift
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

import Foundation
import Research
import ResearchUI
import BridgeApp
import BridgeSDK

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
    
    /// The result for the reminders.
    var result: SBATrackedItemsResult?
    
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
    open override func instantiateDataSource(with parent: RSDPathComponent?, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource?  {
        return SBATrackedItemReminderDataSource(step: self, parent: parent, supportedHints: supportedHints)
    }
    
    #if !os(watchOS)
    open func instantiateViewController(with parent: RSDPathComponent?) -> (UIViewController & RSDStepController)? {
        return SBATrackedItemRemindersStepViewController(step: self, parent: parent)
    }
    #endif
    
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
    
    /// Returns the reminder choice step.
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
    
    override open func buildSections() -> ([RSDTableSection], [RSDTableItemGroup]) {
        let item = RSDTableItem(identifier: self.step.identifier, rowIndex: 0, reuseIdentifier: RSDFormUIHint.button.rawValue)
        let section = RSDTableSection(identifier: self.step.identifier, sectionIndex: 0, tableItems: [item])
        let group = RSDTableItemGroup(beginningRowIndex: 0, items: [item])
        return ([section], [group])
    }
    
    func updateAnswer(to result: RSDCollectionResultObject) {
        self.taskResult.appendStepHistory(with: result)
    }
    
    func updateAnswer(from modalTaskViewModel: RSDTaskViewModel, with stepIdentifier: String?) {
        if let modalStepIdentifier = stepIdentifier,
            let collectionResult = modalTaskViewModel.taskResult.findResult(with: modalStepIdentifier) as? RSDCollectionResultObject {
            return self.updateAnswer(to: collectionResult.copy(with: self.step.identifier))
        }
    }
    
    /// - returns : The description of the selected reminders.
    open func reminderDescription() -> String? {
        guard let reminderValues = self.currentAnswers(),
            reminderValues.count > 0
            else {
                return self.reminderStep?.noReminderSetText
        }
        let reminderValuesStr = Localization.localizedAndJoin(reminderValues.map({ "\($0)" }))
        if let descriptionFormat = self.reminderStep?.descriptionFormat {
            return String(format: descriptionFormat, reminderValuesStr)
        }
        else {
            return reminderValuesStr
        }
    }
    
    func currentAnswers() -> [Int]? {
        if let answerResult = self.collectionResult().inputResults.last as? RSDAnswerResultObject {
            if let array = answerResult.value as? [Int] {
                return array
            }
            else if let answer = answerResult.value as? Int {
                return [answer]
            }
            else {
                return nil
            }
        }
        else if let trackingResult = self.reminderStep?.result as? SBAMedicationTrackingResult {
            return trackingResult.reminders
        }
        else {
            return nil
        }
    }
    
    func modalTaskViewController() -> RSDTaskViewController? {
        guard let reminderChoicesStep = self.reminderStep?.reminderChoicesStep() else { return nil }
        var navigator = RSDConditionalStepNavigatorObject(with: [reminderChoicesStep])
        navigator.progressMarkers = []
        let task = RSDTaskObject(identifier: reminderChoicesStep.identifier, stepNavigator: navigator)
        let taskViewModel = RSDTaskViewModel(task: task)
        if let result = self.collectionResult() as? RSDCollectionResultObject {
            self.taskResult.appendStepHistory(with: result.copy(with: reminderChoicesStep.identifier))
        }
        return RSDTaskViewController(taskViewModel: taskViewModel)
    }
}
