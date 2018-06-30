//
//  SBATrackedMedicationDetailStepObject.swift
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

/// A step used for adding medication details like dosage, and the schedule behind when the user takes the medication
open class SBATrackedMedicationDetailStepObject : SBATrackedItemDetailsStepObject, RSDStepViewControllerVendor {
    
    fileprivate enum FieldIdentifiers : String, CodingKey {
        case dosage, schedules
    }
    
    override open func shouldHideAction(for actionType: RSDUIActionType, on step: RSDStep) -> Bool? {
        if actionType == .navigation(.goBackward) ||
            actionType == .navigation(.skip) {
            return true
        }
        // TODO: mdephillips 6/27/18 make X button be a back button
        return false
    }
    
    public func instantiateViewController(with taskPath: RSDTaskPath) -> (UIViewController & RSDStepController)? {
        return SBATrackedMedicationDetailStepViewController(step: self)
    }
    
    /// Override and return an `SBAMedicationAnswer`.
    override open func answer(from taskResult: RSDTaskResult) -> SBATrackedItemAnswer? {
        guard let detailsResult = taskResult.findResult(for: self) as? SBAMedicationDetailsResultObject else { return nil }
        var medication = SBAMedicationAnswer(identifier: self.identifier)
        medication.dosage = detailsResult.dosage
        if let schedulesUnwrapped = detailsResult.schedules {
            medication.scheduleItems = Set(schedulesUnwrapped)
        }
        return medication
    }
    
    /// Override to return a `SBATrackedWeeklyScheduleDataSource`.
    open override func instantiateDataSource(with taskPath: RSDTaskPath, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBATrackedWeeklyScheduleDataSource.init(identifier: identifier, step: self, taskPath: taskPath)
    }
}

/// A data source used to the weekly schedule for a medication
open class SBATrackedWeeklyScheduleDataSource : RSDModalStepDataSource, RSDModalStepTaskControllerDelegate {
    
    enum FieldIdentifiers : String {
        case header, dosage, schedules, addSchedule
        
        func sectionIndex() -> Int {
            switch self {
                case .header:       return 0
                case .dosage:       return 1
                case .schedules:    return 2
                case .addSchedule:  return 3
            }
        }
    }

    public var identifier: String
    
    public var delegate: RSDTableDataSourceDelegate?
    
    public var step: RSDStep
    
    public var taskPath: RSDTaskPath!
    
    public var sections: [RSDTableSection]
    
    public var schedulesSection: RSDTableSection {
        return self.sections[FieldIdentifiers.schedules.sectionIndex()]
    }
    
    open var dosageTableItem: RSDTextInputTableItem? {
        return self.sections[FieldIdentifiers.dosage.sectionIndex()].tableItems.first as? RSDTextInputTableItem
    }
    
    public init (identifier: String, step: RSDStep, taskPath: RSDTaskPath) {
        
        self.identifier = identifier
        self.step = step
        self.taskPath = taskPath
        self.sections = []
        
        let previousAnswer = (step as? SBATrackedMedicationDetailStepObject)?.previousAnswer as? SBAMedicationAnswer

        sections.append(createHeaderSection())
        sections.append(createDosageSection(with: previousAnswer))
        sections.append(createSchedulesSection(with: previousAnswer))
        if shouldCreateAddScheduleSection(with: previousAnswer) {
            sections.append(createAddScheduleSection())
        }
    }
    
    fileprivate func createHeaderSection() -> RSDTableSection {
        let headerTableItem = RSDTableItem(identifier: FieldIdentifiers.header.stringValue, rowIndex: 0, reuseIdentifier: FieldIdentifiers.header.stringValue)
        let headerSection = RSDTableSection(identifier: FieldIdentifiers.header.stringValue, sectionIndex: FieldIdentifiers.header.sectionIndex(), tableItems: [headerTableItem])
        return headerSection
    }
    
    fileprivate func createDosageSection(with previousAnswer: SBAMedicationAnswer?) -> RSDTableSection {
        let inputField = RSDInputFieldObject(identifier: FieldIdentifiers.dosage.stringValue, dataType: .base(.string), uiHint: .textfield, prompt: Localization.localizedString("MEDICATION_DOSAGE_PROMPT"))
        inputField.placeholder = Localization.localizedString("MEDICATION_DOSAGE_PLACEHOLDER")
        let dosageTableItem = RSDTextInputTableItem(rowIndex: 0, inputField: inputField, uiHint: .textfield)
        if let previousAnswerUnwrapped = previousAnswer {
            try? dosageTableItem.setAnswer(previousAnswerUnwrapped.dosage)
        }
        let dosageSection = RSDTableSection(identifier: FieldIdentifiers.dosage.stringValue, sectionIndex: FieldIdentifiers.dosage.sectionIndex(), tableItems: [dosageTableItem])
        return dosageSection
    }
    
    fileprivate func createSchedulesSection(with previousAnswer: SBAMedicationAnswer?) -> RSDTableSection {
        var scheduleTableItems = [SBATrackedWeeklyScheduleTableItem]()
        if let previousAnswerUnwrapped = previousAnswer,
            let scheduleItemsUnwrapped = previousAnswerUnwrapped.scheduleItems {
            for scheudle in scheduleItemsUnwrapped {
                let scheduleItem = SBATrackedWeeklyScheduleTableItem(identifier:
                    String(format: "%@%d", SBATrackedWeeklyScheduleCell.reuseId, 0), rowIndex: 0, reuseIdentifier: SBATrackedWeeklyScheduleCell.reuseId, schedule: scheudle)
                
                scheduleTableItems.append(scheduleItem)
            }
        } else {
            let scheduleItem = SBATrackedWeeklyScheduleTableItem(identifier:
                String(format: "%@%d", SBATrackedWeeklyScheduleCell.reuseId, 0), rowIndex: 0, reuseIdentifier: SBATrackedWeeklyScheduleCell.reuseId)
            scheduleTableItems.append(scheduleItem)
        }
        let scheduleSections = RSDTableSection(identifier: FieldIdentifiers.schedules.stringValue, sectionIndex: FieldIdentifiers.schedules.sectionIndex(), tableItems: scheduleTableItems)
        return scheduleSections
    }
    
    fileprivate func shouldCreateAddScheduleSection(with previousAnswer: SBAMedicationAnswer?) -> Bool {
        if let previousAnswerUnwrapped = previousAnswer {
            for schedule in previousAnswerUnwrapped.scheduleItems ?? [] {
                if schedule.timeOfDayString == nil {
                    return false
                }
            }
        }
        return true
    }
    
    fileprivate func createAddScheduleSection() -> RSDTableSection {
        let addScheduleTableItem = RSDTableItem(identifier: FieldIdentifiers.addSchedule.stringValue, rowIndex: 0, reuseIdentifier: FieldIdentifiers.addSchedule.stringValue)
        let addScheduleSection = RSDTableSection(identifier: FieldIdentifiers.addSchedule.stringValue, sectionIndex: FieldIdentifiers.addSchedule.sectionIndex(), tableItems: [addScheduleTableItem])
        return addScheduleSection
    }
    
    /**
     Adds a schedule item to the schedules section
     While not strictly enforced, this should not be called if any existing
     schedule items are set to schedule at anytime
    */
    public func addScheduleItem() {
        guard let schedulesSection = sections.filter({ $0.identifier == FieldIdentifiers.schedules.stringValue }).first else {
            return
        }
        let newIndex = schedulesSection.tableItems.count
        let scheduleTableItem = SBATrackedWeeklyScheduleTableItem(identifier:
            String(format: "%@%d", SBATrackedWeeklyScheduleCell.reuseId, newIndex), rowIndex: newIndex, reuseIdentifier: SBATrackedWeeklyScheduleCell.reuseId)
        var newTableItems = schedulesSection.tableItems
        newTableItems.append(scheduleTableItem)
        let newSchedulesSection = RSDTableSection(identifier: FieldIdentifiers.schedules.stringValue, sectionIndex: FieldIdentifiers.schedules.sectionIndex(), tableItems: newTableItems)
        sections[FieldIdentifiers.schedules.sectionIndex()] = newSchedulesSection
    }
    
    /**
     Call this method when the user has selected that they schedule this at anytime
     This will reduce the schedule section to 1 element
    */
    public func scheduleAtAnytimeChanged(selected: Bool) {
        guard let schedulesSection = sections.filter({ $0.identifier == FieldIdentifiers.schedules.stringValue }).first,
            schedulesSection.tableItems.count > 0 else {
            return
        }
        let lastIndex = schedulesSection.tableItems.count - 1
        let tableItem = schedulesSection.tableItems[lastIndex]
        guard let scheduleItem = tableItem as? SBATrackedWeeklyScheduleTableItem else { return }
        if selected {
            scheduleItem.time = nil
        } else {
            scheduleItem.time = Calendar.current.date(byAdding: .hour, value: 7, to: Date())
        }
        let newSchedulesSection = RSDTableSection(identifier: FieldIdentifiers.schedules.stringValue, sectionIndex: FieldIdentifiers.schedules.sectionIndex(), tableItems: [scheduleItem])
        sections[FieldIdentifiers.schedules.sectionIndex()] = newSchedulesSection
        
        // If the anytime field is selected, hide the add schedule button
        if !selected {
            if self.sections.count > FieldIdentifiers.addSchedule.sectionIndex() {
                self.sections[FieldIdentifiers.addSchedule.sectionIndex()] = self.createAddScheduleSection()
            } else {
                self.sections.append(self.createAddScheduleSection())
            }
        } else {
            if self.sections.count > FieldIdentifiers.addSchedule.sectionIndex() {
                self.sections.remove(at: FieldIdentifiers.addSchedule.sectionIndex())
            }
        }
    }
    
    internal var _currentTaskController: RSDModalStepTaskController?
    internal var _currentTableItem: RSDModalStepTableItem?
    
    public func willPresent(_ stepController: RSDStepController, from tableItem: RSDModalStepTableItem) {
        
        // Need to append the step history twice to put the result in both the **current** and previous results.
        // TODO: syoung 05/08/2018 Refactor to a less obfuscated way of getting results.
        let step = stepController.step!
        var navigator = RSDConditionalStepNavigatorObject(with: [step])
        navigator.progressMarkers = []
        let task = RSDTaskObject(identifier: step.identifier, stepNavigator: navigator)
        let path = RSDTaskPath(task: task)
//        if let previousResult = weeklyScheduleItem.result.findResult(with: step.identifier) {
//            path.appendStepHistory(with: previousResult)
//            path.appendStepHistory(with: previousResult)
//        }
        path.currentStep = stepController.step
        let taskController = RSDModalStepTaskController()
        _currentTaskController = taskController
        _currentTableItem = tableItem
        taskController.taskPath = path
        taskController.stepController = stepController
        taskController.delegate = self
        stepController.taskController = taskController
    }
    
    // MARK: RSDModalStepTaskControllerDelegate
    
    open func goForward(with taskController: RSDModalStepTaskController) {
        self.delegate?.tableDataSource(self, didFinishWith: taskController.stepController)
    }
    
    // MARK: Selection management

    
    /// Default behavior is to dismiss the view controller without changes.
    open func goBack(with taskController: RSDModalStepTaskController) {
        self.delegate?.tableDataSource(self, didFinishWith: taskController.stepController)
        _currentTaskController = nil
        _currentTableItem = nil
    }
    
    public func appendRemoveMedicationToTaskPath() {
        let stepResult = SBARemoveMedicationResultObject(identifier: step.identifier)
        self.taskPath.appendStepHistory(with: stepResult)
    }
    
    public func appendStepResultToTaskPathAndFinish(with stepViewController: RSDStepViewController) {
        var stepResult = SBAMedicationDetailsResultObject(identifier: step.identifier)
        stepResult.dosage = self.dosageTableItem?.answerText
        var scheduleResults = [RSDWeeklyScheduleObject]()
        for tableItem in self.schedulesSection.tableItems {
            if let scheduleItem = (tableItem as? SBATrackedWeeklyScheduleTableItem) {
                scheduleResults.append(scheduleItem.result)
            }
        }
        stepResult.schedules = scheduleResults
        
        self.taskPath.appendStepHistory(with: stepResult)
    }
    
    /// Returns the weekday choice step
    public func step(for tableItem: RSDModalStepTableItem) -> RSDStep {
        let identifier = String(describing: RSDWeekday.self)
        let choices: [RSDWeekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        let dataType = RSDFormDataType.collection(.multipleChoice, .string)
        let inputField = RSDChoiceInputFieldObject(identifier: identifier, choices: choices, dataType: dataType)
        let formStep = RSDFormUIStepObject(identifier: identifier, inputFields: [inputField])
        let formTitle = String(format: Localization.localizedString("MEDICATION_DAY_OF_WEEK_%@"), self.step.identifier)
        formStep.title = formTitle
        formStep.actions = [.navigation(.goForward) : RSDUIActionObject(buttonTitle: Localization.localizedString("BUTTON_SAVE"))]
        return formStep
    }
    
    public func itemGroup(at indexPath: IndexPath) -> RSDTableItemGroup? {
        return nil
    }
    
    public func allAnswersValid() -> Bool {
        if let dosageItem = self.sections[FieldIdentifiers.dosage.sectionIndex()].tableItems.first as? RSDTextInputTableItem {
            return dosageItem.answerText != nil
        }
        return true
    }
    
    public func saveAnswer(_ answer: Any, at indexPath: IndexPath) throws {
        let i = 0
    }
    
    public func selectAnswer(item: RSDTableItem, at indexPath: IndexPath) throws -> (isSelected: Bool, reloadSection: Bool) {
        return (false, false)
    }
}

public struct SBAMedicationDetailsResultObject: RSDResult {
    
    enum CodingKeys: String, CodingKey, Codable {
        case identifier, type, startDate, endDate, inputResults, dosage, schedules
    }
    
    public var inputResults: [RSDResult] = []
    
    public var identifier: String
    
    public var type: RSDResultType
    
    public var startDate: Date
    
    public var endDate: Date
    
    public var dosage: String?
    
    public var schedules: [RSDWeeklyScheduleObject]?
    
    public init(identifier: String) {
        self.identifier = identifier
        inputResults = []
        type = .collection
        startDate = Date()
        endDate = Date()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        
        try container.encode(identifier, forKey: AnyCodingKey(stringValue: CodingKeys.identifier.stringValue)!)
        try container.encodeIfPresent(type, forKey: AnyCodingKey(stringValue: CodingKeys.type.stringValue)!)
        try container.encodeIfPresent(startDate, forKey: AnyCodingKey(stringValue: CodingKeys.startDate.stringValue)!)
        try container.encodeIfPresent(endDate, forKey: AnyCodingKey(stringValue: CodingKeys.endDate.stringValue)!)
        try container.encodeIfPresent(dosage, forKey: AnyCodingKey(stringValue: CodingKeys.dosage.stringValue)!)
        try container.encodeIfPresent(schedules, forKey: AnyCodingKey(stringValue: CodingKeys.schedules.stringValue)!)
    }
}

/// The symptom table item is tracked using the result object.
open class SBATrackedWeeklyScheduleTableItem : RSDModalStepTableItem {
    
    public enum ResultIdentifier : String, CodingKey, Codable {
        case schedules
    }
    
    var result: RSDWeeklyScheduleObject
    
    /// The duration window describing how long the symptoms occurred.
    public var weekdays: [RSDWeekday]? {
        get {
            return Array(self.result.daysOfWeek)
        }
        set {
            self.result.daysOfWeek = Set(newValue ?? [])
        }
    }
    
    /// The time when the symptom started occuring.
    public var time: Date? {
        get {
            guard let tod = self.result.timeOfDayString,
             let date = RSDDateCoderObject.hourAndMinutesOnly.inputFormatter.date(from: tod) else {
                return nil
            }
            return date
        }
        set {
            if let newValueUnwrapped = newValue {
                self.result.timeOfDayString = RSDDateCoderObject.hourAndMinutesOnly.inputFormatter.string(from: newValueUnwrapped)
            } else {
                self.result.timeOfDayString = nil
            }
        }
    }
    
    /// Initialize a new RSDTableItem.
    /// - parameters:
    ///     - identifier: The cell identifier.
    ///     - rowIndex: The index of this item relative to all rows in the section in which this item resides.
    ///     - reuseIdentifier: The string to use as the reuse identifier.
    public init(identifier: String, rowIndex: Int, reuseIdentifier: String = SBATrackedWeeklyScheduleCell.reuseId) {
        var weekdays = Set<RSDWeekday>()
        weekdays.insert(.friday)
        let date = Calendar.current.date(bySetting: .hour, value: 7, of: Date().startOfDay())
        let timeOfDay = RSDDateCoderObject.hourAndMinutesOnly.inputFormatter.string(from: date!)
        self.result = RSDWeeklyScheduleObject(timeOfDayString: timeOfDay, daysOfWeek: weekdays)
        super.init(identifier: identifier, rowIndex: rowIndex, reuseIdentifier: reuseIdentifier)
    }
    
    /// Initialize a new RSDTableItem.
    /// - parameters:
    ///     - identifier: The cell identifier.
    ///     - rowIndex: The index of this item relative to all rows in the section in which this item resides.
    ///     - reuseIdentifier: The string to use as the reuse identifier.
    public init(identifier: String, rowIndex: Int, reuseIdentifier: String, schedule: RSDWeeklyScheduleObject) {
        self.result = schedule
        super.init(identifier: identifier, rowIndex: rowIndex, reuseIdentifier: reuseIdentifier)
    }
    
    private static func resultIdentifier(identifier: String, rowIndex: Int) -> String {
        return String(format: "%@%d", identifier, rowIndex)
    }
}

open class SBARemoveMedicationResultObject: RSDResult {
    public var identifier: String
    
    public var type: RSDResultType
    
    public var startDate: Date
    
    public var endDate: Date
    
    public init(identifier: String) {
        self.identifier = identifier
        type = .navigation
        startDate = Date()
        endDate = Date()
    }
}
