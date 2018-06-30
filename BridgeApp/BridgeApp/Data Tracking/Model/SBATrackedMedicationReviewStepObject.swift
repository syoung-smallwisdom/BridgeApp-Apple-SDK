//
//  SBATrackedMedicationReviewStepObject.swift
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
open class SBATrackedMedicationReviewStepObject : SBATrackedItemsReviewStepObject, RSDStepViewControllerVendor {
    
    public var selectedDetailIdentifier: String?
    
    override open func nextStepIdentifier(with result: RSDTaskResult?, conditionalRule : RSDConditionalRule?, isPeeking: Bool) -> String? {
        if let detailsStepId = self.selectedDetailIdentifier {
            return detailsStepId
        }
        return super.nextStepIdentifier(with: result, conditionalRule: conditionalRule, isPeeking: isPeeking)
    }

    #if !os(watchOS)
    /// Override to return a medication tracking step view controller.
    open func instantiateViewController(with taskPath: RSDTaskPath) -> (UIViewController & RSDStepController)? {
        return SBATrackedMedicationReviewStepViewController(step: self)
    }
    #endif
    
    /// Override to return a `SBASymptomLoggingDataSource`.
    open override func instantiateDataSource(with taskPath: RSDTaskPath, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBATrackedMedicationReviewDataSource(step: self, taskPath: taskPath)
    }
}

/// A data source used to handle tracked medication review.
open class SBATrackedMedicationReviewDataSource : SBATrackingDataSource, RSDModalStepDataSource {

    fileprivate var mostRecentResult: SBAMedicationTrackingResult? {
        return self.trackingResult() as? SBAMedicationTrackingResult
    }
    
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
        
        let review = buildReviewSections(step: step, result: result)
        var itemGroups = review.itemGroups
        var sections = review.sections
        
        let actionType: RSDUIActionType = .addMore
        if let uiStep = step as? RSDUIActionHandler, let action = uiStep.action(for: actionType, on: step) {
            let tableItem = SBAModalSelectionTableItem(identifier: actionType.stringValue, rowIndex: 0, reuseIdentifier: RSDFormUIHint.modalButton.stringValue, action: action)
            itemGroups.append(RSDTableItemGroup(beginningRowIndex: 0, items: [tableItem]))
            sections.append(RSDTableSection(identifier: "addMore", sectionIndex: 1, tableItems: [tableItem]))
        }
        
        return (sections, itemGroups)
    }
    
    /// Build the review sections of the table. This is called by `buildSections(step:initialResult)` to get
    /// the review sections of the table. That method will then append an `.addMore` section if appropriate.
    open class func buildReviewSections(step: SBATrackedItemsStep, result: SBATrackedItemsResult) -> (sections: [RSDTableSection], itemGroups: [RSDTableItemGroup]) {
        
        let inputField = RSDChoiceInputFieldObject(identifier: step.identifier, choices: result.selectedAnswers, dataType: .collection(.multipleChoice, .string), uiHint: .logging)
        let trackedItems = result.selectedAnswers.enumerated().map { (idx, item) -> RSDTableItem in
            let choice: RSDChoice = step.items.first(where: { $0.identifier == item.identifier }) ?? item
            return self.instantiateTableItem(at: idx, inputField: inputField, itemAnswer: item, choice: choice)
        }
        
        let itemGroups: [RSDTableItemGroup] = [RSDTableItemGroup(beginningRowIndex: 0, items: trackedItems)]
        let sections: [RSDTableSection] = [RSDTableSection(identifier: "logging", sectionIndex: 0, tableItems: trackedItems)]
        
        return (sections, itemGroups)
    }
    
    /// Override the instantiation of the table item to return a medication review table item
    open class func instantiateTableItem(at rowIndex: Int, inputField: RSDInputField, itemAnswer: SBATrackedItemAnswer, choice: RSDChoice) -> RSDTableItem {

        guard let medAnswer = itemAnswer as? SBAMedicationAnswer else {
            return RSDTextTableItem(rowIndex: rowIndex, text: "Invalid SBATrackedItemAnswer format")
        }

        let reviewItem = SBATrackedMedicationReviewItem(medication: medAnswer, rowIndex: rowIndex, reuseIdentifier: SBATrackedMedicationReviewCell.reuseId)
        return reviewItem
    }
    
    /// Call when a review item is selected, this will add a details result to the step history
    /// That will be used to create the correct details step
    func reviewItemSelected(identifier: String) {
        if let currentResult = self.mostRecentResult,
            let existingDetailsResult = currentResult.medications.first(where: { $0.identifier == identifier }),
            let reviewStep = self.step as? SBATrackedMedicationReviewStepObject {
            reviewStep.selectedDetailIdentifier = existingDetailsResult.identifier
        }
    }
    
    func updateResults(with details: SBAMedicationDetailsResultObject) {
        guard var currentResult = self.mostRecentResult,
            let medResults = currentResult.selectedAnswers as? [SBAMedicationAnswer],
            var matchingResult = medResults.first(where: { $0.identifier == details.identifier }) else {
                return
        }
        matchingResult.dosage = details.dosage
        matchingResult.scheduleItems = Set(details.schedules ?? [])
        
        var newItems = self.trackingResult().selectedAnswers.filter({ $0.identifier != details.identifier })
        newItems.append(matchingResult)
        
        currentResult.updateDetails(to: matchingResult)
        taskPath.result.appendStepHistory(with: currentResult)
        
        // Inform delegate that answers have changed.
        _ = self.reloadDataSource(with: self.trackingResult())
        delegate?.tableDataSource(self, didChangeAnswersIn: 0)
    }
    
    func updateResults(byRemoving identifier: String) {
        if var currentResult = self.trackingResult() as? SBAMedicationTrackingResult {
            let newItemIdentifiers = self.trackingResult().selectedAnswers
                .map({ $0.identifier })
                .filter({ $0 != identifier })
            let newItems = self.trackingResult().selectedAnswers.filter({ $0.identifier != identifier })
            currentResult.updateSelected(to: newItemIdentifiers, with: newItems as! [SBATrackedItem])
            taskPath.result.appendStepHistory(with: currentResult)
            // Inform delegate that answers have changed.
            _ = self.reloadDataSource(with: currentResult)
            delegate?.tableDataSource(self, didChangeAnswersIn: 0)
        }
    }
    
    public func step(for tableItem: RSDModalStepTableItem) -> RSDStep {
        return RSDFormUIStep()
    }
    
    public func willPresent(_ stepController: RSDStepController, from tableItem: RSDModalStepTableItem) {
        let i = 0
    }
}

/// The medication review table item is tracked using the result object.
open class SBATrackedMedicationReviewItem : RSDModalStepTableItem {

    /// The result object associated with this table item.
    public var medication: SBAMedicationAnswer

    /// Initialize a new RSDTableItem.
    /// - parameters:
    ///     - identifier: The cell identifier.
    ///     - rowIndex: The index of this item relative to all rows in the section in which this item resides.
    ///     - reuseIdentifier: The string to use as the reuse identifier.
    public init(medication: SBAMedicationAnswer, rowIndex: Int, reuseIdentifier: String = RSDFormUIHint.logging.rawValue) {
        self.medication = medication
        super.init(identifier: medication.identifier, rowIndex: rowIndex, reuseIdentifier: reuseIdentifier)
    }
}
