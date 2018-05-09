//
//  SBASymptomLoggingStepObject.swift
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
open class SBASymptomLoggingStepObject : SBATrackedItemsLoggingStepObject {
    
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

/// A data source used to handle symptom logging.
open class SBASymptomLoggingDataSource : SBATrackedLoggingDataSource {
    
    /// Override the instantiation of the table item to return a symptom table item.
    override open class func instantiateTableItem(at rowIndex: Int, inputField: RSDInputField, itemAnswer: SBATrackedItemAnswer, choice: RSDChoice) -> RSDTableItem {
        
        let loggedResult: SBATrackedLoggingResultObject = {
            if let result = itemAnswer as? SBATrackedLoggingResultObject {
                return result
            }
            else {
                var result = SBATrackedLoggingResultObject(identifier: itemAnswer.identifier, text: choice.text, detail: choice.detail)
                result.type = .symptom
                result.loggedDate = Date()
                return result
            }
        }()
        
        return SBASymptomTableItem(loggedResult: loggedResult, rowIndex: rowIndex)
    }
    
    /// Returns the selection step.
    override open func step(for tableItem: RSDModalStepTableItem) -> RSDStep {
        guard let symptomItem = tableItem as? SBASymptomTableItem else {
            return super.step(for: tableItem)
        }
        
        let formStep = SBASymptomDurationLevel.formStep(at: symptomItem.time)
        return formStep
    }
    
    override open func willPresent(_ stepController: RSDStepController, from tableItem: RSDModalStepTableItem) {
        guard let symptomItem = tableItem as? SBASymptomTableItem else {
            super.willPresent(stepController, from: tableItem)
            return
        }

        // Need to append the step history twice to put the result in both the **current** and previous results.
        // TODO: syoung 05/08/2018 Refactor to a less obfuscated way of getting results.
        let step = stepController.step!
        var navigator = RSDConditionalStepNavigatorObject(with: [step])
        navigator.progressMarkers = []
        let task = RSDTaskObject(identifier: step.identifier, stepNavigator: navigator)
        let path = RSDTaskPath(task: task)
        if let previousResult = symptomItem.loggedResult.findResult(with: step.identifier) {
            path.appendStepHistory(with: previousResult)
            path.appendStepHistory(with: previousResult)
        }
        path.currentStep = stepController.step
        setupModal(stepController, path: path, tableItem: symptomItem)
    }
    
    override open func goForward(with taskController: RSDModalStepTaskController) {
        if let symptomItem = _currentTableItem as? SBASymptomTableItem,
            let result = taskController.taskPath.result.findAnswerResult(with: SBASymptomTableItem.ResultIdentifier.duration.stringValue) {
            
            // Let the delegate know that things are changing.
            self.delegate?.tableDataSourceWillBeginUpdate(self)
            
            // Update the result set for this source.
            symptomItem.duration = SBASymptomDurationLevel(result: result)
            updateResults(with: symptomItem)
            
            // reload the table delegate.
            self.delegate?.tableDataSourceDidEndUpdate(self, addedRows: [symptomItem.indexPath], removedRows: [symptomItem.indexPath])
        }
        super.goForward(with: taskController)
    }
    
    /// Update the logged result with the new input result.
    func updateResults(with tableItem: SBASymptomTableItem) {
        
        var stepResult = self.trackingResult()
        stepResult.updateDetails(to: tableItem.loggedResult)
        self.taskPath.appendStepHistory(with: stepResult)
        
        // inform delegate that answers have changed
        delegate?.tableDataSource(self, didChangeAnswersIn: tableItem.indexPath.section)
    }
}

/// The severity level of the symptom being logged.
public enum SBASymptomSeverityLevel : Int, Codable {
    case none = 0, mild, moderate, severe
}

/// The medication timing for the symptom being logged.
public enum SBASymptomMedicationTiming : String, Codable {
    case preMedication = "pre-medication"
    case postMedication = "post-medication"

    public var intValue: Int {
        return SBASymptomMedicationTiming.sortOrder.index(of: self)!
    }
    
    public init?(intValue: Int) {
        guard intValue < SBASymptomMedicationTiming.sortOrder.count, intValue >= 0 else { return nil }
        self = SBASymptomMedicationTiming.sortOrder[intValue]
    }
    
    private static let sortOrder: [SBASymptomMedicationTiming] = [.preMedication, .postMedication]
}

/// The symptom duration as a "level" of duration length.
public enum SBASymptomDurationLevel : Int, Codable {
    
    case now, shortPeriod, littleWhile, morning, afternoon, evening, halfDay, halfNight, allDay, allNight
    
    private static let choiceKeys = [
        "DURATION_CHOICE_NOW",
        "DURATION_CHOICE_SHORT_PERIOD",
        "DURATION_CHOICE_A_WHILE",
        "DURATION_CHOICE_MORNING",
        "DURATION_CHOICE_AFTERNOON",
        "DURATION_CHOICE_EVENING",
        "DURATION_CHOICE_HALF_DAY",
        "DURATION_CHOICE_HALF_NIGHT",
        "DURATION_CHOICE_ALL_DAY",
        "DURATION_CHOICE_ALL_NIGHT"
    ]
    
    public init?(result: RSDResult) {
        guard let answerResult = result as? RSDAnswerResult else { return nil }
        if let value = answerResult.value as? SBASymptomDurationLevel {
            self = value
        }
        else if let number = answerResult.value as? NSNumber {
            self.init(rawValue: number.intValue)
        }
        else if let rawValue = answerResult.value as? Int {
            self.init(rawValue: rawValue)
        }
        else if let stringValue = answerResult.value as? String {
            self.init(stringValue: stringValue)
        }
        else {
            return nil
        }
    }
    
    public init?(stringValue: String) {
        guard let rawValue = SBASymptomDurationLevel.choiceKeys.index(of: stringValue) else { return nil }
        self.init(rawValue: rawValue)
    }
    
    public var stringValue : String {
        return SBASymptomDurationLevel.choiceKeys[self.rawValue]
    }
    
    public var level : Int {
        switch self {
        case .now, .shortPeriod, .littleWhile:
            return rawValue
        case .morning, .afternoon, .evening:
            return SBASymptomDurationLevel.morning.rawValue
        case .halfDay, .halfNight:
            return SBASymptomDurationLevel.morning.level + 1
        case .allDay, .allNight:
            return SBASymptomDurationLevel.halfDay.level + 1
        }
    }
    
    public static func durationChoices(at time: Date) -> [SBASymptomDurationLevel] {
        switch time.timeRange() {
        case .morning:
            return [.now, .shortPeriod, .littleWhile, .morning, .halfDay, .allDay]
        case .afternoon:
            return [.now, .shortPeriod, .littleWhile, .afternoon, .halfDay, .allDay]
        case .evening:
            return [.now, .shortPeriod, .littleWhile, .evening, .halfDay, .allDay]
        case .night:
            return [.now, .shortPeriod, .littleWhile, .halfNight, .allNight]
        }
    }
    
    public static func formStep(at time: Date) ->  RSDFormUIStep {
        let identifier = SBASymptomTableItem.ResultIdentifier.duration.stringValue
        let choices = durationChoices(at: time)
        let inputField = RSDChoiceInputFieldObject(identifier: identifier, choices: choices, dataType: dataType)
        let formStep = RSDFormUIStepObject(identifier: identifier, inputFields: [inputField])
        formStep.title = Localization.localizedString("DURATION_SELECTION_TITLE")
        formStep.detail = Localization.localizedString("DURATION_SELECTION_DETAIL")
        formStep.actions = [.navigation(.goForward) : RSDUIActionObject(buttonTitle: Localization.localizedString("BUTTON_SAVE"))]
        return formStep
    }
    
    public static var dataType : RSDFormDataType {
        return .collection(.singleChoice, .string)
    }
    
    public static var answerType : RSDAnswerResultType {
        return .string
    }
}

extension SBASymptomDurationLevel : RSDChoice {
    
    public var answerValue: Codable? {
        return self.stringValue
    }
    
    public var text: String? {
        let key = SBASymptomDurationLevel.choiceKeys[self.rawValue]
        return Localization.localizedString(key)
    }
    
    public var detail: String? {
        return nil
    }
    
    public var isExclusive: Bool {
        return true
    }
    
    public var imageVendor: RSDImageVendor? {
        return nil
    }
    
    public func isEqualToResult(_ result: RSDResult?) -> Bool {
        guard let aResult = result, let level = SBASymptomDurationLevel(result: aResult) else { return false }
        return level == self
    }
}

/// The symptom table item is tracked using the result object.
open class SBASymptomTableItem : RSDModalStepTableItem {
    
    public enum ResultIdentifier : String, CodingKey, Codable {
        case severity, duration, medicationTiming, notes
    }
    
    /// The result object associated with this table item.
    public var loggedResult: SBATrackedLoggingResultObject
    
    /// The severity level of the symptom.
    public var severity : SBASymptomSeverityLevel? {
        get {
            guard let rawValue = loggedResult.findAnswerResult(with: ResultIdentifier.severity.rawValue)?.value as? Int
                else {
                    return nil
            }
            return SBASymptomSeverityLevel(rawValue: rawValue)
        }
        set {
            var answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.severity.rawValue, answerType: .integer)
            answerResult.value = newValue?.rawValue
            _appendResults(answerResult)
        }
    }
    
    /// The time when the symptom started occuring.
    public var time: Date {
        get {
            return loggedResult.loggedDate ?? Date()
        }
        set {
            loggedResult.loggedDate = newValue
        }
    }
    
    /// The duration window describing how long the symptoms occurred.
    public var duration: SBASymptomDurationLevel? {
        get {
            guard let result = loggedResult.findAnswerResult(with: ResultIdentifier.duration.rawValue) else { return nil }
            return SBASymptomDurationLevel(result: result)
        }
        set {
            var answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.duration.rawValue, answerType: SBASymptomDurationLevel.answerType)
            answerResult.value = newValue?.answerValue
            _appendResults(answerResult)
        }
    }
    
    /// The medication timing for when the symptom occurred.
    public var medicationTiming: SBASymptomMedicationTiming? {
        get {
            guard let rawValue = loggedResult.findAnswerResult(with: ResultIdentifier.medicationTiming.rawValue)?.value as? String
                else {
                    return nil
            }
            return SBASymptomMedicationTiming(rawValue: rawValue)        }
        set {
            var answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.medicationTiming.rawValue, answerType: .string)
            answerResult.value = newValue?.rawValue
            _appendResults(answerResult)
        }
    }
    
    /// Notes added by the participant.
    public var notes: String? {
        get {
            return loggedResult.findAnswerResult(with: ResultIdentifier.notes.rawValue)?.value as? String
        }
        set {
            var answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.notes.rawValue, answerType: .string)
            answerResult.value = newValue
            _appendResults(answerResult)
        }
    }
    
    private func _appendResults(_ answerResult: RSDAnswerResultObject) {
        loggedResult.appendInputResults(with: answerResult)
        if loggedResult.loggedDate == nil {
            loggedResult.loggedDate = Date()
        }
    }
    
    /// Initialize a new RSDTableItem.
    /// - parameters:
    ///     - identifier: The cell identifier.
    ///     - rowIndex: The index of this item relative to all rows in the section in which this item resides.
    ///     - reuseIdentifier: The string to use as the reuse identifier.
    public init(loggedResult: SBATrackedLoggingResultObject, rowIndex: Int, reuseIdentifier: String = RSDFormUIHint.logging.rawValue) {
        self.loggedResult = loggedResult
        super.init(identifier: loggedResult.identifier, rowIndex: rowIndex, reuseIdentifier: reuseIdentifier)
    }
}
