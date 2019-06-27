//
//  SBATrackedLoggingDataSource.swift
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

extension RSDFormUIHint {
    
    /// Display a cell appropriate to logging a timestamp.
    public static let logging: RSDFormUIHint = "logging"
}

extension RSDUIActionType {
    
    /// Add more selected items.
    public static let addMore: RSDUIActionType = "addMore"
}

/// `SBATrackedLoggingDataSource` is a concrete implementation of the `RSDTableDataSource` protocol
/// that is designed to be used with a `SBATrackedItemsStep` intended for logging of items that were
/// selected in a previous step.
open class SBATrackedLoggingDataSource : SBATrackingDataSource, RSDModalStepDataSource {

    /// Overridable class function for building the sections of the table.
    /// - parameters:
    ///     - step: The `SBATrackedItemsStep` for this data source.
    ///     - initialResult: The initial result (if any).
    /// - returns:
    ///     - sections: The built table sections.
    ///     - itemGroups: The associated item groups.
    override open class func buildSections(step: SBATrackedItemsStep, initialResult: SBATrackedItemsResult?) -> (sections: [RSDTableSection], itemGroups: [RSDTableItemGroup]) {
        guard let result = initialResult else {
            assertionFailure("A non-nil initial result is expected for logging items")
            return ([], [])
        }
        
        let logging = buildLoggingSections(step: step, result: result)
        var itemGroups = logging.itemGroups
        var sections = logging.sections
        
        let actionType: RSDUIActionType = .addMore
        if let uiStep = step as? RSDUIActionHandler, let action = uiStep.action(for: actionType, on: step) {
            let tableItem = SBAModalSelectionTableItem(identifier: actionType.stringValue, rowIndex: 0, reuseIdentifier: RSDFormUIHint.button.stringValue, action: action)
            itemGroups.append(RSDTableItemGroup(beginningRowIndex: 0, items: [tableItem]))
            sections.append(RSDTableSection(identifier: "addMore", sectionIndex: 1, tableItems: [tableItem]))
        }
        
        return (sections, itemGroups)
    }
    
    /// Build the logging sections of the table. This is called by `buildSections(step:initialResult)` to get
    /// the logging sections of the table. That method will then append an `.addMore` section if appropriate.
    open class func buildLoggingSections(step: SBATrackedItemsStep, result: SBATrackedItemsResult) -> (sections: [RSDTableSection], itemGroups: [RSDTableItemGroup]) {
        
        let inputField = RSDChoiceInputFieldObject(identifier: step.identifier, choices: result.selectedAnswers, dataType: .collection(.multipleChoice, .string), uiHint: .logging)
        let trackedItems = result.selectedAnswers.enumerated().map { (idx, item) -> RSDTableItem in
            let choice: RSDChoice = step.items.first(where: { $0.identifier == item.identifier }) ?? item
            return self.instantiateTableItem(at: idx, inputField: inputField, itemAnswer: item, choice: choice)
        }
        
        let itemGroups: [RSDTableItemGroup] = [RSDTableItemGroup(beginningRowIndex: 0, items: trackedItems)]
        let sections: [RSDTableSection] = [RSDTableSection(identifier: "logging", sectionIndex: 0, tableItems: trackedItems)]
        
        return (sections, itemGroups)
    }
    
    /// Instantiate an appropriate table item for the given row.
    /// - parameters:
    ///     - rowIndex: The row index for the table item.
    ///     - inputField: The input field associated with the table item.
    ///     - itemAnswer: The tracked item answer currently set for this row.
    ///     - choice: The choice for this row.
    /// - returns: New instance of a table item appropriate to this row.
    open class func instantiateTableItem(at rowIndex: Int, inputField: RSDInputField, itemAnswer: SBATrackedItemAnswer, choice: RSDChoice) -> RSDTableItem {
        let tableItem = SBATrackedLoggingTableItem(rowIndex: rowIndex, itemIdentifier: itemAnswer.identifier)
        tableItem.title = choice.text
        tableItem.detail = choice.detail
        return tableItem
    }
    
    /// Override to mark the item as logged.
    /// - parameter indexPath: The `IndexPath` that represents the `RSDTableItem` in the  table view.
    /// - returns:
    ///     - isSelected: The new selection state of the selected item.
    ///     - reloadSection: `true` if the section needs to be reloaded b/c other answers have changed,
    ///                      otherwise returns `false`.
    /// - throws: `RSDInputFieldError` if the selection is invalid.
    override open func selectAnswer(item: RSDTableItem, at indexPath: IndexPath) throws -> (isSelected: Bool, reloadSection: Bool) {
        guard let loggingItem = item as? SBATrackedLoggingTableItem else {
            return (false, false)
        }
        loggingItem.logTimestamp()
        return updateLoggingDetails(for: loggingItem, at: indexPath)
    }
    
    /// Mark the item as logged.
    @discardableResult open func updateLoggingDetails(for loggingItem: SBATrackedLoggingTableItem, at indexPath: IndexPath) -> (isSelected: Bool, reloadSection: Bool) {
        
        // Update the answers.
        let loggedResult = buildAnswer(for: loggingItem)
        var stepResult = self.trackingResult()
        stepResult.updateDetails(from: loggedResult)
        self.taskResult.appendStepHistory(with: stepResult)
        
        // Inform delegate that answers have changed.
        delegate?.tableDataSource(self, didChangeAnswersIn: indexPath.section)
        
        return (true, false)
    }
    
    /// Build the answer object appropriate to this tracked logging item.
    open func buildAnswer(for loggingItem: SBATrackedLoggingTableItem) -> RSDResult {
        var loggedResult = SBATrackedLoggingResultObject(identifier: loggingItem.identifier, text: loggingItem.title, detail: loggingItem.detail)
        loggedResult.itemIdentifier = loggingItem.itemIdentifier
        loggedResult.timingIdentifier = loggingItem.timingIdentifier
        loggedResult.loggedDate = loggingItem.loggedDate
        return loggedResult
    }
    
    /// Override to return valid if at least one answer is marked as logged.
    override open func allAnswersValid() -> Bool {
        return self.trackingResult().selectedAnswers.reduce(false, { $0 || $1.hasRequiredValues })
    }
    
    open func taskViewModel(for tableItem: RSDModalStepTableItem) -> RSDTaskViewModel? {
        guard let step = self.step(for: tableItem) else {
            assertionFailure("Unknown table item. Cannot show modal for \(tableItem)")
            return nil
        }

        var navigator = RSDConditionalStepNavigatorObject(with: [step])
        navigator.progressMarkers = []
        let task = RSDTaskObject(identifier: step.identifier, stepNavigator: navigator)
        let taskViewModel = SBAModalTaskViewModel(task: task, parentViewModel: self)
        if let previousResult = self.previousResult(for: tableItem, with: step) {
            taskViewModel.append(previousResult: previousResult)
        }
        return taskViewModel
    }
    
    open func step(for tableItem: RSDModalStepTableItem) -> RSDStep? {
        guard let _ = tableItem as? SBAModalSelectionTableItem,
            let task = self.parentTaskPath?.task,
            let navigator = task.stepNavigator as? SBATrackedItemsStepNavigator,
            let step = navigator.getSelectionStep() as? SBATrackedItemsStep
            else {
                return nil
        }
        step.result = self.trackingResult()
        return step
    }
    
    open func previousResult(for tableItem: RSDModalStepTableItem, with step: RSDStep) -> RSDResult? {
        return self.trackingResult().copy(with: step.identifier)
    }
    
    /// Save an answer for a specific IndexPath.
    open func saveAnswer(for tableItem: RSDModalStepTableItem, from taskViewModel: RSDTaskViewModel) {
        guard let result = taskViewModel.taskResult.stepHistory.first as? SBATrackedItemsResult
            else {
                return
        }
            
        // Let the delegate know that things are changing.
        self.delegate?.tableDataSourceWillBeginUpdate(self)
        
        // Update the result set for this source.
        var stepResult = self.trackingResult()
        stepResult.updateSelected(to: result.selectedIdentifiers, with: trackedStep.items)
        self.taskResult.appendStepHistory(with: stepResult)
        let changes = self.reloadDataSource(with: result)
        self.delegate?.tableDataSource(self, didAddRows: changes.addedRows, with: .none)
        self.delegate?.tableDataSource(self, didRemoveRows: changes.removedRows, with: .none)
        
        if let stepNavigator = self.parentTaskPath?.task?.stepNavigator as? SBATrackedItemsStepNavigator {
            stepNavigator.updateSelectedInMemoryResult(to: result.selectedIdentifiers, with: trackedStep.items)
        }
        
        // reload the table delegate.
        self.delegate?.tableDataSourceDidEndUpdate(self)
    }
}

/// Subclass the modal step table item to use casting as the type.
open class SBAModalSelectionTableItem : RSDModalStepTableItem {
}

/// Custom table group for handling marking items as selected with a timestamp.
open class SBATrackedLoggingTableItem : RSDTableItem, RSDScheduleTime {
    
    /// The identifier of the tracked item.
    public let itemIdentifier: String
    
    /// The timing identifier to map to a schedule.
    public let timingIdentifier: String
    
    /// The title of the tracked item.
    open var title : String?
    
    /// The time to display for the table item.
    open var timeText : String? {
        guard let time = self.displayDate else { return nil }
        return DateFormatter.localizedString(from: time, dateStyle: .none, timeStyle: .short)
    }
    
    /// The detail for the tracked item.
    open var detail : String?
    
    /// The date when the event was logged.
    open var loggedDate: Date?
    
    /// The index position of the item within its subgrouping (for schedules that are grouped).
    public let groupIndex: Int
    
    /// Used to create a read/write object that can be mutated.
    public let timeOfDayString : String?
    
    public init(rowIndex: Int, itemIdentifier: String, timingIdentifier: String? = nil, timeOfDayString: String? = nil, uiHint: RSDFormUIHint = .logging) {
        var identifier = itemIdentifier
        if let timingIdentifier = timingIdentifier {
            self.timingIdentifier = timingIdentifier
            identifier.append(":\(timingIdentifier)")
        }
        else {
            self.timingIdentifier = ""
        }
        self.itemIdentifier = itemIdentifier
        self.groupIndex = rowIndex
        self.timeOfDayString = timeOfDayString
        super.init(identifier: identifier, rowIndex: rowIndex, reuseIdentifier: uiHint.rawValue)
    }
    
    /// The display date (either the `loggedDate` or the date from the schedule's `timeComponents`).
    public var displayDate : Date? {
        return self.loggedDate ?? self.timeOfDay(on: Date())
    }
    
    /// Mark the logging timestamp.
    open func logTimestamp() {
        let newDate: Date = self.displayDate ?? Date()
        self.loggedDate = newDate
    }
    
    /// Undo marking the timestamp.
    open func undo() {
        self.loggedDate = nil
    }
}
