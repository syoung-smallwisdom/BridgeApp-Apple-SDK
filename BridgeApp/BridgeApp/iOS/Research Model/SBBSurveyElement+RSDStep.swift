//
//  SBBSurveyElement+RSDStep.swift
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
import JsonModel

extension SBBBridgeObject {
    
    /// Do nothing. Validation is handled by the server for all bridge objects.
    public func validate() throws {
    }
    
    /// All bridge objects call through to the shared `SBASurveyConfiguration`.
    public func action(for actionType: RSDUIActionType, on step: RSDStep) -> RSDUIAction? {
        return SBASurveyConfiguration.shared.action(for: actionType, on:step, callingObject: self)
    }
    
    /// All bridge objects call through to the shared `SBASurveyConfiguration`.
    public func shouldHideAction(for actionType: RSDUIActionType, on step: RSDStep) -> Bool? {
        return SBASurveyConfiguration.shared.shouldHideAction(for: actionType, on: step, callingObject: self)
    }
}

extension SBBSurveyElement {
    public var viewTheme: RSDViewThemeElement? {
        return SBASurveyConfiguration.shared.viewTheme(for: self)
    }
    
    public var colorMapping: RSDColorMappingThemeElement? {
        return SBASurveyConfiguration.shared.colorMapping(for: self)
    }
}

extension SBBSurveyElement : RSDUIStep {
    
    public var subtitle: String? {
        self.prompt.sba_parseNewLine()
    }
    
    public var detail: String? {
        // For a boolean, the prompt detail is set on the input item. Need to special-case it.
        if let question = self as? SBBSurveyQuestion,
            let boolConstraints = question.constraints as? SBBBooleanConstraints,
            boolConstraints.isToggle(for: question) {
            return nil
        }
        else {
            return self.promptDetail?.sba_parseNewLine()
        }
    }
    
    public var footnote: String? {
        nil
    }

    public var stepType: RSDStepType {
        SBASurveyConfiguration.shared.stepType(for: self)
    }
    
    public func instantiateStepResult() -> RSDResult {
        SBASurveyConfiguration.shared.instantiateStepResult(for: self) ?? RSDResultObject(identifier: self.identifier)
    }
    
    fileprivate func parseNewLine(_ string: String?) -> String? {
        string?.replacingOccurrences(of: "\\n", with: "\n")
    }
}

extension String {
    fileprivate func sba_parseNewLine() -> String? {
        return self.replacingOccurrences(of: "\\n", with: "\n")
    }
}

extension SBBSurveyInfoScreen : RSDDesignableUIStep {
    public var imageTheme: RSDImageThemeElement? {
        return self.image
    }
}

extension SBBSurveyInfoScreen : sbb_BridgeImageOwner {
}

extension SBBSurveyQuestion : RSDDesignableUIStep {
    public var imageTheme: RSDImageThemeElement? {
        return nil
    }
}

extension SBBSurveyQuestion : QuestionStep {
    
    public var isOptional: Bool {
        if let required = self.constraints.required {
            return !required.boolValue
        }
        else {
            return SBASurveyConfiguration.shared.isOptional(for: self)
        }
    }
    
    public var isSingleAnswer: Bool {
        (self.constraints as? SBBMultiValueConstraints)?.allowMultipleValue != true
    }
    
    public var answerType: AnswerType {
        guard let answerType = (self.constraints as? sbb_InputItemBuilder)?.answerType
            else {
                assertionFailure("\(self.constraints.classForCoder) does not implement `sbb_InputItemBuilder`")
                return AnswerTypeString()
        }
        return answerType
    }

    public func buildInputItems() -> [InputItem] {
        guard let builder = self.constraints as? sbb_InputItemBuilder
            else {
                assertionFailure("\(self.constraints.classForCoder) does not implement `sbb_InputItemBuilder`")
                return [TextEntryConstraintsWrapper(question: self)]
        }
        return builder.buildInputItems(with: self)
    }
    
    var questionData : JsonElement {
        .object([
            kConstraintsType : self.constraints.type,
            kConstraintsDataType : self.constraints.dataTypeValue.rawValue
        ])
    }
}

let kConstraintsType = "constraints.type"
let kConstraintsDataType = "constraints.dataType"

extension SBBUIHintType {
    public var hint: RSDFormUIHint? {
        switch self {
        case .checkbox:
            return .checkbox
        case .combobox:
            return .combobox
        case .datePicker, .dateTimePicker, .timePicker:
            return .picker
        case .list:
            return .list
        case .multilineText:
            return .multipleLine
        case .numberfield, .textfield:
            return .textfield
        case .radioButton:
            return .radioButton
        case .slider:
            return .slider
        case .toggle:
            return .toggle
        default:
            return nil
        }
    }
}

protocol sbb_InputItemBuilder {
    var answerType: AnswerType { get }
    func buildInputItems(with question: SBBSurveyQuestion) -> [InputItem]
}

protocol sbb_KeyboardOptionsBuilder {
    func buildKeyboardOptions() -> KeyboardOptions
}

protocol sbb_PatternPlaceholder {
    var patternPlaceholder : String? { get }
}

protocol sbb_TextValidatorBuilder {
    func buildTextValidator() -> TextInputValidator?
}

protocol sbb_TextEntry : sbb_InputItemBuilder {
}
extension sbb_TextEntry {
    func buildInputItems(with question: SBBSurveyQuestion) -> [InputItem] {
        [TextEntryConstraintsWrapper(question: question)]
    }
}

extension SBBStringConstraints : sbb_TextEntry, sbb_PatternPlaceholder, sbb_TextValidatorBuilder {
    
    var answerType: AnswerType {
        AnswerTypeString()
    }
    
    func buildTextValidator() -> TextInputValidator? {
        if let pattern = self.pattern, let message = self.patternErrorMessage {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                return RegExValidator(pattern: regex, invalidMessage: message)
            }
            catch let err {
                assertionFailure("Failed to create RegEx. \(err)")
                return nil
            }
        }
        else if self.minLengthValue > 0 || self.maxLength != nil {
            assert(self.pattern == nil, "Factory does not currently support items with both a min length and a regex pattern.")
            let max = (self.maxLengthValue > 0) ? "\(self.maxLengthValue)" : ""
            let regex = try! NSRegularExpression(pattern: "^.{\(self.minLengthValue),\(max)}$", options: [])
            let message: String = {
                if let minLen = self.minLength {
                    if let maxLen = self.maxLength {
                        if minLen.intValue == maxLen.intValue {
                            return String(format: Localization.localizedString("INVALID_TEXT_LENGTH_SAME"), maxLen)
                        }
                        else {
                            return String(format: Localization.localizedString("INVALID_TEXT_LENGTH_MIN_MAX"), minLen, maxLen)
                        }
                    }
                    else {
                        return String(format: Localization.localizedString("INVALID_TEXT_LENGTH_MIN_%@"), minLen)
                    }
                }
                else {
                    let maxLen = self.maxLength!
                    return String(format: Localization.localizedString("INVALID_TEXT_LENGTH_MAX_%@"), maxLen)
                }
            }()
            return RegExValidator(pattern: regex, invalidMessage: message)
        }
        else {
            return nil
        }
    }
}

// -- Number Constraints

protocol sbb_UnitPlaceholder : sbb_PatternPlaceholder {
    var unit: String? { get }
}
extension sbb_UnitPlaceholder {
    
    var patternPlaceholder: String? {
        self.unit
    }
}

extension SBBIntegerConstraints : sbb_TextEntry, sbb_TextValidatorBuilder, sbb_UnitPlaceholder, sbb_KeyboardOptionsBuilder {
    
    var answerType: AnswerType {
        AnswerTypeInteger()
    }

    func buildKeyboardOptions() -> KeyboardOptions {
        KeyboardOptionsObject.integerEntryOptions
    }
    
    func buildTextValidator() -> TextInputValidator? {
        var validator = IntegerFormatOptions()
        validator.minimumValue = self.minValue?.intValue
        validator.maximumValue = self.maxValue?.intValue
        validator.stepInterval = self.step?.intValue
        return validator
    }
}

extension SBBDecimalConstraints : sbb_TextEntry, sbb_TextValidatorBuilder, sbb_UnitPlaceholder, sbb_KeyboardOptionsBuilder {
    
    var answerType: AnswerType {
        AnswerTypeNumber()
    }
    
    func buildKeyboardOptions() -> KeyboardOptions {
        KeyboardOptionsObject.decimalEntryOptions
    }
    
    func buildTextValidator() -> TextInputValidator? {
        var validator = DoubleFormatOptions()
        validator.minimumValue = self.minValue?.doubleValue
        validator.maximumValue = self.maxValue?.doubleValue
        validator.stepInterval = self.step?.doubleValue
        return validator
    }
}

extension SBBYearConstraints : sbb_TextEntry, sbb_TextValidatorBuilder, sbb_KeyboardOptionsBuilder {
    
    var answerType: AnswerType {
        AnswerTypeInteger()
    }

    func buildKeyboardOptions() -> KeyboardOptions {
        KeyboardOptionsObject.integerEntryOptions
    }
    
    func buildTextValidator() -> TextInputValidator? {
        var validator = YearFormatOptions()
        validator.allowFuture = self.allowFuture?.boolValue
        validator.allowPast = self.allowPast?.boolValue
        if let minDate = self.earliestValue {
            validator.minimumYear = Calendar(identifier: .gregorian).component(.year, from: minDate)
        }
        if let maxDate = self.latestValue {
            validator.maximumYear = Calendar(identifier: .gregorian).component(.year, from: maxDate)
        }
        return validator
    }
}

// -- Measurement Constraints

extension SBBHeightConstraints: sbb_InputItemBuilder {
    
    var answerType: AnswerType {
        AnswerTypeMeasurement(unit: self.unit ?? "cm")
    }
    
    func buildInputItems(with question: SBBSurveyQuestion) -> [InputItem] {
        let range: HumanMeasurementRange = self.isInfantValue ? .infant : .adult
        let item = HeightInputItemObject(measurementRange: range,
                                         identifier: nil,
                                         fieldLabel: nil,
                                         isOptional: question.isOptional,
                                         placeholder: nil)
        return [item]
    }
}

extension SBBWeightConstraints: sbb_InputItemBuilder {
    
    var answerType: AnswerType {
        AnswerTypeMeasurement(unit: self.unit ?? "kg")
    }

    func buildInputItems(with question: SBBSurveyQuestion) -> [InputItem] {
        let range: HumanMeasurementRange = self.isInfantValue ? .infant : .adult
        let item = WeightInputItemObject(measurementRange: range,
                                         identifier: nil,
                                         fieldLabel: nil,
                                         isOptional: question.isOptional,
                                         placeholder: nil)
        return [item]
    }
}

// -- Date Constraints

protocol sbb_DateTime : sbb_InputItemBuilder, RSDDatePickerDataSource, RSDDateRange  {
}
extension sbb_DateTime {
    var answerType: AnswerType {
        AnswerTypeDateTime(codingFormat: self.dateFormatter.dateFormat)
    }
    
    func buildInputItems(with question: SBBSurveyQuestion) -> [InputItem] {
        [DateEntryConstraintsWrapper(question: question)]
    }
}

protocol sbb_DateRange : RSDDateRange {
    var allowFuture: NSNumber? { get }
    var allowPast: NSNumber? { get }
    var earliestValue: Date? { get }
    var latestValue: Date? { get }
}

extension sbb_DateRange {
    
    public var minDate: Date? {
        return self.earliestValue
    }
    
    public var maxDate: Date? {
        return self.latestValue
    }
    
    public var shouldAllowFuture: Bool? {
        return self.allowFuture?.boolValue
    }
    
    public var shouldAllowPast: Bool? {
        return self.allowPast?.boolValue
    }
    
    public var minuteInterval: Int? {
        return nil
    }
}


extension SBBDateConstraints : sbb_DateTime, sbb_DateRange {
    
    public var defaultDate: Date? {
        return nil
    }
    
    public var dateCoder: RSDDateCoder? {
        return RSDDateCoderObject.dateOnly
    }
    
    public var datePickerMode: RSDDatePickerMode {
        return .date
    }
    
    public var dateFormatter: DateFormatter {
        return RSDDateCoderObject.dateOnly.inputFormatter
    }
}

extension SBBDateTimeConstraints : sbb_DateTime, sbb_DateRange {
    
    public var defaultDate: Date? {
        return nil
    }
    
    public var dateCoder: RSDDateCoder? {
        return RSDDateCoderObject.timestamp
    }
    
    public var datePickerMode: RSDDatePickerMode {
        return .dateAndTime
    }
    
    public var dateFormatter: DateFormatter {
        return RSDDateCoderObject.timestamp.inputFormatter
    }
}

extension SBBTimeConstraints : sbb_DateTime {
    
    public var defaultDate: Date? {
        return nil
    }
    
    public var minDate: Date? {
        return nil
    }
    
    public var maxDate: Date? {
        return nil
    }
    
    public var shouldAllowFuture: Bool? {
        return nil
    }
    
    public var shouldAllowPast: Bool? {
        return nil
    }
    
    public var minuteInterval: Int? {
        return nil
    }
    
    public var dateCoder: RSDDateCoder? {
        return RSDDateCoderObject.timeOfDay
    }
    
    public var datePickerMode: RSDDatePickerMode {
        return .time
    }
    
    public var dateFormatter: DateFormatter {
        return RSDDateCoderObject.timeOfDay.inputFormatter
    }
}

// -- Multiple Choice Constraits

extension SBBBooleanConstraints : sbb_InputItemBuilder {
    
    var answerType: AnswerType {
        AnswerTypeBoolean()
    }
    
    func isToggle(for question: SBBSurveyQuestion) -> Bool {
        if question.promptDetail != nil,
            let hint = question.uiHintValue, hint == .checkbox || hint == .radioButton {
            return true
        }
        else {
            return false
        }
    }
    
    func buildInputItems(with question: SBBSurveyQuestion) -> [InputItem] {
        if isToggle(for: question) {
            let fieldLabel = question.promptDetail?.sba_parseNewLine() ?? Localization.buttonYes()
            return [CheckboxInputItemObject(fieldLabel: fieldLabel)]
        }
        else {
            let yesItem = ChoiceItemWrapper(choice: JsonChoiceObject(matchingValue: .boolean(true),
                                                                     text: Localization.buttonYes()),
                                            answerType: AnswerTypeBoolean(),
                                            isSingleAnswer: true,
                                            uiHint: .list)
            let noItem = ChoiceItemWrapper(choice: JsonChoiceObject(matchingValue: .boolean(false),
                                                                     text: Localization.buttonNo()),
                                            answerType: AnswerTypeBoolean(),
                                            isSingleAnswer: true,
                                            uiHint: .list)
            return [yesItem, noItem]
        }
    }
}

extension SBBMultiValueConstraints : sbb_InputItemBuilder {

    var answerType: AnswerType {
        allowMultipleValue ? multipleAnswerType : singleAnswerType
    }

    var baseType : JsonType {
        switch self.dataTypeValue {
        case .boolean:
            return .boolean
        case .decimal:
            return .number
        case .integer:
            return .integer
        default:
            return .string
        }
    }

    var multipleAnswerType : AnswerType {
        AnswerTypeArray(baseType: self.baseType, sequenceSeparator: nil)
    }

    var singleAnswerType : AnswerType {
        switch self.dataTypeValue {
        case .boolean:
            return AnswerTypeBoolean()
        case .decimal:
            return AnswerTypeNumber()
        case .integer:
            return AnswerTypeInteger()
        default:
            return AnswerTypeString()
        }
    }
    
    func buildInputItems(with question: SBBSurveyQuestion) -> [InputItem] {
        let options = self.enumeration as? [SBBSurveyQuestionOption] ?? []
        let answerType = self.answerType
        let singleAnswer = !self.allowMultipleValue
        let hint = question.uiHintValue?.hint ?? .list
        let dataTypeValue = self.dataTypeValue
        return options.map {
            ChoiceItemWrapper(choice: SurveyQuestionOptionWrapper(option: $0, dataTypeValue: dataTypeValue),
                              answerType: answerType,
                              isSingleAnswer: singleAnswer,
                              uiHint: hint)
        }
    }
}

extension SBBSurveyQuestionOption : sbb_BridgeImageOwner {
}

struct SurveyQuestionOptionWrapper : JsonChoice {
    let option: SBBSurveyQuestionOption
    let dataTypeValue : SBBDataType
    
    var text: String? {
        option.label
    }
    
    var detail: String? {
        option.detail
    }
    
    var isExclusive: Bool {
        option.exclusive?.boolValue ?? false
    }
    
    var imageData: RSDImageData? {
        option.imageData
    }
    
    var matchingValue: JsonElement? {
        guard let value = option.value else { return nil }
        if let num = value as? NSNumber {
            switch self.dataTypeValue {
            case .boolean:
                return .boolean(num.boolValue)
            case .decimal:
                return .number(num.doubleValue)
            case .integer:
                return .integer(num.intValue)
            default:
                return .string(num.stringValue)
            }
        }
        else {
            return .string("\(value)")
        }
    }
}

// --- TODO: syoung 08/21/2020 Include support including unit tests for these if there is a need.
// The following constraints are not used in the mPower App, which is the only legacy app that we
// will need to revise in the future.

//extension SBBYearMonthConstraints : sbb_InputItemBuilder {
//   var answerType: AnswerType {
//       AnswerTypeDateTime(codingFormat: "yyyy-MM")
//    }
//}
//
//extension SBBBloodPressureConstraints : sbb_InputItemBuilder {
//    var answerType: AnswerType {
//        AnswerTypeString()
//    }
//}
//
//extension SBBPostalCodeConstraints : sbb_InputItemBuilder {
//    var answerType: AnswerType {
//        AnswerTypeString()
//    }
//}
//
//extension SBBDurationConstraints : sbb_InputItemBuilder {
//    var answerType: AnswerType {
//        AnswerTypeNumber()
//    }
//}
