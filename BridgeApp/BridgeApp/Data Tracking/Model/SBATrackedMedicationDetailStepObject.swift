//
//  SBATrackedMedicationLoggingStepObject.swift
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

/// A step used for logging symptoms.
open class SBATrackedMedicationLoggingStepObject : SBATrackedItemsLoggingStepObject {
    
    #if !os(watchOS)
    /// Override to return a symptom logging step view controller.
    override open func instantiateViewController(with taskPath: RSDTaskPath) -> (UIViewController & RSDStepController)? {
        return SBASymptomLoggingStepViewController(step: self)
    }
    #endif
    
    /// Override to return a `SBASymptomLoggingDataSource`.
    open override func instantiateDataSource(with taskPath: RSDTaskPath, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBASymptomLoggingDataSource(step: self, taskPath: taskPath)
    }
}

/// A step used for logging symptoms.
open class SBATrackedMedicationDetailStepObject : RSDTableStep {
    public var hasImageChoices: Bool
    
    public var title: String?
    
    public var text: String?
    
    public var detail: String?
    
    public var footnote: String?
    
    public var identifier: String
    
    public var stepType: RSDStepType
    
    public init (id: String) {
        identifier = id
        stepType = .form
        hasImageChoices = false
    }
    
    public func instantiateStepResult() -> RSDResult {
        return SBATrackedMedicationResultObject(identifier: identifier)
    }
    
    public func validate() throws {
        
    }
    
    public func action(for actionType: RSDUIActionType, on step: RSDStep) -> RSDUIAction? {
        return nil
    }
    
    public func shouldHideAction(for actionType: RSDUIActionType, on step: RSDStep) -> Bool? {
        return false
    }
    
    
    /// Override to return a `SBASymptomLoggingDataSource`.
    open func instantiateDataSource(with taskPath: RSDTaskPath, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBATrackedWeeklyScheduleDataSource.init(identifier: identifier, theStep: self, theTaskPath: taskPath)
    }
}

/// A data source used to handle symptom logging.
open class SBATrackedWeeklyScheduleDataSource : RSDTableDataSource {
    
    fileprivate enum FieldIdentifiers : String, CodingKey {
        case dosage, schedules
    }
    
    public var delegate: RSDTableDataSourceDelegate?
    
    public var step: RSDStep
    
    public var taskPath: RSDTaskPath!
    
    public var sections: [RSDTableSection]
    
    public init (identifier: String, theStep: RSDStep, theTaskPath: RSDTaskPath) {
        
        step = theStep
        taskPath = theTaskPath
        
        let inputField = RSDInputFieldObject(identifier: FieldIdentifiers.dosage.stringValue, dataType: .base(.string), uiHint: .textfield, prompt: Localization.localizedString("MEDICATION_DOSAGE_PROMPT"))
        inputField.placeholder = Localization.localizedString("MEDICATION_DOSAGE_PLACEHOLDER")
        let dosageTableItem = RSDTextInputTableItem(rowIndex: 0, inputField: inputField, uiHint: .textfield)
        let dosageSection = RSDTableSection(identifier: "dosage", sectionIndex: 0, tableItems: [dosageTableItem])
        
        let scheduleTableItem = SBATrackedWeeklyScheduleTableItem(identifier:
            String(format: "%@%d", SBATrackedWeeklyScheduleCell.reuseId, 0), rowIndex: 0, reuseIdentifier: SBATrackedWeeklyScheduleCell.reuseId)
        let scheduleSections = RSDTableSection(identifier: "schedules", sectionIndex: 1, tableItems: [scheduleTableItem])
        
        sections = [dosageSection, scheduleSections]
    }
    
    public func itemGroup(at indexPath: IndexPath) -> RSDTableItemGroup? {
        return nil
    }
    
    public func allAnswersValid() -> Bool {
        return true
    }
    
    public func saveAnswer(_ answer: Any, at indexPath: IndexPath) throws {
        
    }
    
    public func selectAnswer(item: RSDChoiceTableItem, at indexPath: IndexPath) throws -> (isSelected: Bool, reloadSection: Bool) {
        return (false, false)
    }
}

/// The symptom table item is tracked using the result object.
open class SBATrackedWeeklyScheduleTableItem : RSDModalStepTableItem {
    
    public enum ResultIdentifier : String, CodingKey, Codable {
        case schedules
    }
    
    /// The result object associated with this table item.
    public var schedules: [RSDWeeklyScheduleObject]
    
    /// Initialize a new RSDTableItem.
    /// - parameters:
    ///     - identifier: The cell identifier.
    ///     - rowIndex: The index of this item relative to all rows in the section in which this item resides.
    ///     - reuseIdentifier: The string to use as the reuse identifier.
    public init(identifier: String, rowIndex: Int, reuseIdentifier: String = SBATrackedWeeklyScheduleCell.reuseId) {
        self.schedules = [RSDWeeklyScheduleObject]()
        super.init(identifier: identifier, rowIndex: rowIndex, reuseIdentifier: reuseIdentifier)
    }
}
