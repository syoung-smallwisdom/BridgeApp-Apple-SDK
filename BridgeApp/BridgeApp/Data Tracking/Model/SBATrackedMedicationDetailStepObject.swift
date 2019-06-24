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
        return false
    }
    
    /// Default initializer.
    /// - parameter identifier: The step identifier.
    public override init(identifier: String) {
        super.init(identifier: identifier)
        _commonInit()
    }
    
    /// Initializer required for copying the step.
    public required init(identifier: String, type: RSDStepType?) {
        super.init(identifier: identifier, type: type)
        _commonInit()
    }
    
    /// Initializer required for decoding the step.
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        _commonInit()
    }
    
    #if !os(watchOS)
    open func instantiateViewController(with parent: RSDPathComponent?) -> (UIViewController & RSDStepController)? {
        return SBATrackedMedicationDetailStepViewController(step: self, parent: parent)
    }
    #endif
    
    /// Override to return a `SBATrackedWeeklyScheduleDataSource`.
    open override func instantiateDataSource(with parent: RSDPathComponent?, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBATrackedMedicationDetailsDataSource(step: self, parent: parent)
    }
    
    private func _commonInit() {
        // Set the default color theme.
        if self.colorMapping == nil {
            let placement: [RSDColorPlacement : RSDColorRules.Style] = [
                .header: .primary,
                .body: .primary,
                .footer: .white
            ]
            self.colorMapping = RSDColorPlacementThemeElementObject(placement: placement.mapKeys { $0.stringValue } )
        }
        if self.actions?[.navigation(.cancel)] == nil {
            var actions = self.actions ?? [:]
            actions[.navigation(.cancel)] = RSDUIActionObject(iconName: "backArrowHeader",
                                                              bundle: Bundle(identifier: "org.sagebionetworks.ResearchUI-iOS"))
            self.actions = actions
        }
    }
}

/// A data source used to the weekly schedule for a medication
open class SBATrackedMedicationDetailsDataSource : RSDStepViewModel, RSDTableDataSource {
    
    enum FieldIdentifiers : String {
        case dosage, schedules, addSchedule
        
        func sectionIndex() -> Int {
            switch self {
                case .dosage:       return 0
                case .schedules:    return 1
                case .addSchedule:  return 2
            }
        }
    }
    
    public var delegate: RSDTableDataSourceDelegate?
    
    public var sections: [RSDTableSection]
    
    public var schedulesSection: RSDTableSection {
        return self.sections[FieldIdentifiers.schedules.sectionIndex()]
    }
    
    override open var isForwardEnabled: Bool {
        return super.isForwardEnabled && allAnswersValid()
    }
    
    open var dosageTableItem: RSDTextInputTableItem? {
        return self.sections[FieldIdentifiers.dosage.sectionIndex()].tableItems.first as? RSDTextInputTableItem
    }
    
    override public init(step: RSDStep, parent: RSDPathComponent?) {
        self.sections = []
        
        super.init(step: step, parent: parent)

        let previousAnswer = (step as? SBATrackedMedicationDetailStepObject)?.previousAnswer as? SBAMedicationAnswer

        sections.append(createDosageSection(with: previousAnswer))
        sections.append(createSchedulesSection(with: previousAnswer))
        if shouldCreateAddScheduleSection(with: previousAnswer) {
            sections.append(createAddScheduleSection())
        }
    }
    
//    fileprivate func createDosageSection(with previousAnswer: SBAMedicationAnswer?) -> RSDTableSection {
//        let inputField = RSDInputFieldObject(identifier: FieldIdentifiers.dosage.stringValue, dataType: .base(.string), uiHint: .textfield, prompt: Localization.localizedString("MEDICATION_DOSAGE_PROMPT"))
//        inputField.placeholder = Localization.localizedString("MEDICATION_DOSAGE_PLACEHOLDER")
//        let dosageTableItem = RSDTextInputTableItem(rowIndex: 0, inputField: inputField, uiHint: .textfield)
//        if let previousAnswerUnwrapped = previousAnswer {
//            try? dosageTableItem.setAnswer(previousAnswerUnwrapped.dosage)
//        }
//        let dosageSection = RSDTableSection(identifier: FieldIdentifiers.dosage.stringValue, sectionIndex: FieldIdentifiers.dosage.sectionIndex(), tableItems: [dosageTableItem])
//        return dosageSection
//    }
//
//    fileprivate func createSchedulesSection(with previousAnswer: SBAMedicationAnswer?) -> RSDTableSection {
//        var scheduleTableItems = [SBATrackedWeeklyScheduleTableItem]()
//        if let previousAnswerUnwrapped = previousAnswer,
//            let scheduleItemsUnwrapped = previousAnswerUnwrapped.scheduleItems {
//            for schedule in scheduleItemsUnwrapped.sorted() {
//                let scheduleItem = SBATrackedWeeklyScheduleTableItem(identifier:
//                    String(format: "%@%d", SBATrackedWeeklyScheduleCell.reuseId, 0), rowIndex: 0, reuseIdentifier: SBATrackedWeeklyScheduleCell.reuseId, schedule: schedule)
//
//                scheduleTableItems.append(scheduleItem)
//            }
//        } else {
//            let scheduleItem = SBATrackedWeeklyScheduleTableItem(identifier:
//                String(format: "%@%d", SBATrackedWeeklyScheduleCell.reuseId, 0), rowIndex: 0, reuseIdentifier: SBATrackedWeeklyScheduleCell.reuseId)
//            scheduleTableItems.append(scheduleItem)
//        }
//        let scheduleSections = RSDTableSection(identifier: FieldIdentifiers.schedules.stringValue, sectionIndex: FieldIdentifiers.schedules.sectionIndex(), tableItems: scheduleTableItems)
//        return scheduleSections
//    }
//
//    fileprivate func shouldCreateAddScheduleSection(with previousAnswer: SBAMedicationAnswer?) -> Bool {
//        if let previousAnswerUnwrapped = previousAnswer {
//            for schedule in previousAnswerUnwrapped.scheduleItems ?? [] {
//                if schedule.timeOfDayString == nil {
//                    return false
//                }
//            }
//        }
//        return true
//    }
//
//    fileprivate func createAddScheduleSection() -> RSDTableSection {
//        let addScheduleTableItem = RSDTableItem(identifier: FieldIdentifiers.addSchedule.stringValue, rowIndex: 0, reuseIdentifier: FieldIdentifiers.addSchedule.stringValue)
//        let addScheduleSection = RSDTableSection(identifier: FieldIdentifiers.addSchedule.stringValue, sectionIndex: FieldIdentifiers.addSchedule.sectionIndex(), tableItems: [addScheduleTableItem])
//        return addScheduleSection
//    }
    
//    /// Adds a schedule item to the schedules section.
//    /// While not strictly enforced, this should not be called if any existing
//    /// schedule items are set to schedule at anytime.
//    /// - returns: The index path of the section that was added.
//    @discardableResult public func addScheduleItem() -> IndexPath? {
//        guard let schedulesSection = sections.filter({ $0.identifier == FieldIdentifiers.schedules.stringValue }).first else {
//            return nil
//        }
//        let newIndex = schedulesSection.tableItems.count
//        let scheduleTableItem = SBATrackedWeeklyScheduleTableItem(identifier:
//            String(format: "%@%d", SBATrackedWeeklyScheduleCell.reuseId, newIndex), rowIndex: newIndex, reuseIdentifier: SBATrackedWeeklyScheduleCell.reuseId)
//        var newTableItems = schedulesSection.tableItems
//        newTableItems.append(scheduleTableItem)
//        let newSchedulesSection = RSDTableSection(identifier: FieldIdentifiers.schedules.stringValue, sectionIndex: FieldIdentifiers.schedules.sectionIndex(), tableItems: newTableItems)
//        sections[FieldIdentifiers.schedules.sectionIndex()] = newSchedulesSection
//        return IndexPath(item: newIndex, section: FieldIdentifiers.schedules.sectionIndex())
//    }
    
    
    /// Call this method when the user has selected that they schedule this at anytime.
    /// This will reduce the schedule section to 1 element.
    /// - returns:
    ///        - itemsRemoved: The index paths of the items that were removed.
    ///        - sectionAdded: `true` if the "add schedule" section was added; `false` if it was removed.
    @discardableResult public func scheduleAtAnytimeChanged(selected: Bool) -> (itemsRemoved: [IndexPath], sectionAdded: Bool)? {
        guard let schedulesSection = sections.first(where: {$0.identifier == FieldIdentifiers.schedules.stringValue}),
            let scheduleItem = schedulesSection.tableItems.last as? SBATrackedWeeklyScheduleTableItem else {
                return nil
        }
        if (selected) {
            scheduleItem.time = nil
            scheduleItem.weekdays = Array(RSDWeekday.all)
        } else {
            scheduleItem.time = Calendar.current.date(bySetting: .hour, value: 7, of: Date().startOfDay())
            scheduleItem.weekdays = Array(RSDWeekday.all)
        }
        
        let schedulesSectionIndex = FieldIdentifiers.schedules.sectionIndex()
        let newSchedulesSection = RSDTableSection(identifier: FieldIdentifiers.schedules.stringValue, sectionIndex: schedulesSectionIndex, tableItems: [scheduleItem])
        sections[schedulesSectionIndex] = newSchedulesSection
        
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
        
        var itemsRemoved = [IndexPath]()
        let lastIndex = schedulesSection.tableItems.count - 1
        if selected && lastIndex >= 1 {
            let schedulesIndex = FieldIdentifiers.schedules.sectionIndex()
            for i in 1...lastIndex {
                itemsRemoved.append(IndexPath(item: i, section: schedulesIndex))
            }
        }
        
        return (itemsRemoved, !selected)
    }
    
    public func appendRemoveMedicationToTaskResult() {
        var stepResult = SBARemoveTrackedItemsResultObject(identifier: self.step.identifier)
        stepResult.items = [RSDIdentifier(rawValue: self.step.identifier)]
        self.taskResult.appendStepHistory(with: stepResult)
    }
    
    public func appendStepResultToTaskResultAndFinish(with stepViewController: RSDStepViewController) {
        var stepResult = SBAMedicationDetailsResultObject(identifier: step.identifier)
        stepResult.dosage = self.dosageTableItem?.answerText
        var scheduleResults = [RSDWeeklyScheduleObject]()
        for tableItem in self.schedulesSection.tableItems {
            if let scheduleItem = (tableItem as? SBATrackedWeeklyScheduleTableItem) {
                scheduleResults.append(scheduleItem.result)
            }
        }
        stepResult.schedules = scheduleResults
        
        self.taskResult.appendStepHistory(with: stepResult)
    }
    
    /// Returns the weekday choice step.
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
        assertionFailure("Method implementation is not defined.")
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

/// The weekly schedule table item is tracked using the result object.
open class SBATrackedWeeklyScheduleTableItem : RSDModalStepTableItem {
    
    public enum ResultIdentifier : String, CodingKey, Codable {
        case schedules
    }
    
    var result: RSDWeeklyScheduleObject
    
    /// The weekdays that the user has their medication scheduled
    public var weekdays: [RSDWeekday]? {
        get {
            return Array(self.result.daysOfWeek)
        }
        set {
            self.result.daysOfWeek = Set(newValue ?? [])
        }
    }
    
    /// The time at which the user should be taking their medication.
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
    
    /// Initialize a new SBATrackedWeeklyScheduleTableItem.
    /// - parameters:
    ///     - identifier: The cell identifier.
    ///     - rowIndex: The index of this item relative to all rows in the section in which this item resides.
    ///     - reuseIdentifier: The string to use as the reuse identifier.
    public init(identifier: String, rowIndex: Int, reuseIdentifier: String = SBATrackedWeeklyScheduleCell.reuseId) {
        let date = Calendar.current.date(bySetting: .hour, value: 7, of: Date().startOfDay())
        let timeOfDay = RSDDateCoderObject.hourAndMinutesOnly.inputFormatter.string(from: date!)
        self.result = RSDWeeklyScheduleObject(timeOfDayString: timeOfDay, daysOfWeek: RSDWeekday.all)
        super.init(identifier: identifier, rowIndex: rowIndex, reuseIdentifier: reuseIdentifier)
    }
    
    /// Initialize a new SBATrackedWeeklyScheduleTableItem.
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
