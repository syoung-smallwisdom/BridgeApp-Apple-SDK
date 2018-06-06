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
open class SBATrackedLoggingDataSource : SBATrackingDataSource, RSDModalStepDataSource, RSDModalStepTaskControllerDelegate {

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
            let tableItem = SBAModalSelectionTableItem(identifier: actionType.stringValue, rowIndex: 0, reuseIdentifier: RSDFormUIHint.modalButton.stringValue, action: action)
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
        let timestamp = (choice as? SBATimestamp) ??
            SBATimestamp(identifier: itemAnswer.identifier, timeOfDayString: nil, loggedDate: nil, detail: nil)
        return SBATrackedLoggingTableItem(rowIndex: rowIndex, inputField: inputField, uiHint: .logging, choice: choice, timestamp: timestamp)
    }
    
    /// Override to mark the item as logged.
    /// - parameter indexPath: The `IndexPath` that represents the `RSDTableItem` in the  table view.
    /// - returns:
    ///     - isSelected: The new selection state of the selected item.
    ///     - reloadSection: `true` if the section needs to be reloaded b/c other answers have changed,
    ///                      otherwise returns `false`.
    /// - throws: `RSDInputFieldError` if the selection is invalid.
    override open func selectAnswer(item: RSDChoiceTableItem, at indexPath: IndexPath) throws -> (isSelected: Bool, reloadSection: Bool) {
        guard let loggingItem = item as? SBATrackedLoggingTableItem else {
            return (false, false)
        }
        loggingItem.logTimestamp()
        return updateLoggingDetails(for: loggingItem, at: indexPath)
    }
    
    /// Mark the item as logged.
    open func updateLoggingDetails(for loggingItem: SBATrackedLoggingTableItem, at indexPath: IndexPath) -> (isSelected: Bool, reloadSection: Bool) {
        
        // Update the answers
        let loggedResult = buildAnswer(for: loggingItem)
        var stepResult = self.trackingResult()
        stepResult.updateDetails(to: loggedResult)
        self.taskPath.appendStepHistory(with: stepResult)
        
        // inform delegate that answers have changed
        delegate?.tableDataSource(self, didChangeAnswersIn: indexPath.section)
        
        return (true, false)
    }
    
    /// Build the answer object appropriate to this tracked logging item.
    open func buildAnswer(for loggingItem: SBATrackedLoggingTableItem) -> SBATrackedItemAnswer {
        var loggedResult = SBATrackedLoggingResultObject(identifier: loggingItem.identifier, text: loggingItem.choice.text, detail: loggingItem.choice.detail)
        loggedResult.loggedDate = loggingItem.loggedDate
        return loggedResult
    }
    
    /// Override to return valid if at least one answer is marked as logged.
    override open func allAnswersValid() -> Bool {
        return self.trackingResult().selectedAnswers.reduce(false, { $0 || $1.hasRequiredValues })
    }
    
    // MARK: RSDModalStepDataSource
    
    /// Returns the selection step.
    open func step(for tableItem: RSDModalStepTableItem) -> RSDStep {
        guard let step = (self.taskPath.task?.stepNavigator as? SBATrackedItemsStepNavigator)?.getSelectionStep() as? SBATrackedItemsStep
            else {
                assertionFailure("Expecting the task navigator to be a tracked items navigator.")
            return RSDUIStepObject(identifier: tableItem.identifier)
        }
        step.result = self.trackingResult()
        return step
    }
    
    /// The calling table view controller will present a step view controller for the modal step. This method
    /// should set up the task controller for the step and handle any other task management required before
    /// presenting the step.
    ///
    /// - parameters:
    ///     - stepController: The step controller that was instantiated to run the step.
    ///     - tableItem: The table item that was selected.
    open func willPresent(_ stepController: RSDStepController, from tableItem: RSDModalStepTableItem) {
        guard let task = taskPath.task else {
            assertionFailure("Failed to set the task controller because the current task is nil.")
            return
        }
        
        // Set up the path and the task controller for the current step. For this case, we want a new task path that uses the task
        // from *this* taskPath as it's source, but which does not directly edit this task path.
        let path = RSDTaskPath(task: task)
        setupModal(stepController, path: path, tableItem: tableItem)
    }
    
    internal func setupModal(_ stepController: RSDStepController, path: RSDTaskPath, tableItem: RSDModalStepTableItem) {
        path.currentStep = stepController.step
        let taskController = RSDModalStepTaskController()
        _currentTaskController = taskController
        _currentTableItem = tableItem
        taskController.taskPath = path
        taskController.stepController = stepController
        taskController.delegate = self
        stepController.taskController = taskController
    }
    
    internal var _currentTaskController: RSDModalStepTaskController?
    internal var _currentTableItem: RSDModalStepTableItem?
    
    // MARK: RSDModalStepTaskControllerDelegate
    
    open func goForward(with taskController: RSDModalStepTaskController) {
        if let _ = _currentTableItem as? SBAModalSelectionTableItem,
            let result = taskController.taskPath.result.findResult(for: taskController.stepController.step) as? SBATrackedItemsResult {

            // Let the delegate know that things are changing.
            self.delegate?.tableDataSourceWillBeginUpdate(self)
            
            // Update the result set for this source.
            var stepResult = self.trackingResult()
            stepResult.updateSelected(to: result.selectedIdentifiers, with: trackedStep.items)
            self.taskPath.appendStepHistory(with: stepResult)
            let changes = self.reloadDataSource(with: result)

            // reload the table delegate.
            self.delegate?.tableDataSourceDidEndUpdate(self, addedRows: changes.addedRows, removedRows: changes.removedRows)
        }
        self.delegate?.tableDataSource(self, didFinishWith: taskController.stepController)
        _currentTaskController = nil
        _currentTableItem = nil
    }
    
    /// Default behavior is to dismiss the view controller without changes.
    open func goBack(with taskController: RSDModalStepTaskController) {
        self.delegate?.tableDataSource(self, didFinishWith: taskController.stepController)
        _currentTaskController = nil
        _currentTableItem = nil
    }
}

/// Subclass the modal step table item to use casting as the type.
open class SBAModalSelectionTableItem : RSDModalStepTableItem {
}

/// Custom table group for handling marking items as selected with a timestamp.
open class SBATrackedLoggingTableItem : RSDChoiceTableItem {
    
    /// The date when the event was logged.
    public var loggedDate: Date? {
        return timestamp.loggedDate
    }
    
    /// The timestamp object used to track the logged date.
    public internal(set) var timestamp: SBATimestamp

    /// Override the answer to return the timestamp.
    open override var answer: Any? {
        return loggedDate
    }
    
    /// Override the selected state to mark an item as selected using a timestamp.
    override open var selected : Bool {
        get {
            return loggedDate != nil
        }
        set {
            if !newValue {
                timestamp.loggedDate = nil
            } else {
                timestamp.logTimestamp()
            }
        }
    }
    
    public init(rowIndex: Int, inputField: RSDInputField, uiHint: RSDFormUIHint, choice: RSDChoice, timestamp: SBATimestamp) {
        self.timestamp = timestamp
        super.init(rowIndex: rowIndex, inputField: inputField, uiHint: uiHint, choice: choice)
    }
    
    /// Mark the logging timestamp.
    open func logTimestamp() {
        timestamp.logTimestamp()
    }
    
    /// Undo marking the timestamp.
    open func undo() {
        timestamp.loggedDate = nil
    }
    

}

public struct SBATimestamp : Codable, RSDSchedule {
    
    /// The identifier used to track the schedule or item associated with this timestamp.
    public let identifier : String
    
    /// The time of day string encodes the hour and minute for the time of day.
    public var timeOfDayString: String?
    
    /// The logged date.
    /// - note: This date might be different from the scheduled time.
    public var loggedDate : Date?
    
    /// The detail string (if any).
    public var detail: String?
    
    /// The marked timestamp date (either the `loggedDate` or the date from the schedule's `timeComponents`.
    var timestampDate : Date? {
        return self.loggedDate ?? self.timeOfDay
    }
    
    /// Mark the timestamp with a logged date.
    mutating func logTimestamp() {
        let newDate: Date = self.timestampDate ?? Date()
        self.loggedDate = newDate
        if self.timeOfDayString == nil {
            self.setTime(from: newDate)
        }
    }
    
    /// Notification triggers are ignored.
    public func notificationTriggers() -> [DateComponents] {
        return []
    }
}

extension SBATimestamp : RSDComparable {
    
    /// Returns `timeOfDayString`.
    public var matchingAnswer: Any? {
        return self.timeOfDayString
    }
}

extension SBATimestamp : RSDChoice {
    
    /// Returns `timeOfDayString`.
    public var answerValue: Codable? {
        return self.timeOfDayString
    }
    
    /// The text is the time string (or nil if undefined).
    public var text: String? {
        guard let time = self.timestampDate else {
            return nil
        }
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: time)
    }
    
    /// Returns `false`.
    public var isExclusive: Bool {
        return false
    }
    
    /// Returns `nil`.
    public var imageVendor: RSDImageVendor? {
        return nil
    }
}

extension SBATimestamp : SBATrackedItemAnswer {
    
    /// Returns `true` if the `loggedDate` is non-nil.
    public var hasRequiredValues: Bool {
        return loggedDate != nil
    }
}

