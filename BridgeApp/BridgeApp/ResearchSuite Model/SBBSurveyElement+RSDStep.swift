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

extension SBBSurveyElement {
    
    public var text: String? {
        return self.prompt
    }
    
    public var detail: String? {
        return self.promptDetail
    }
    
    public var footnote: String? {
        return nil
    }
    
    public func validate() throws {
        // No validation required
    }
    
    public func action(for actionType: RSDUIActionType, on step: RSDStep) -> RSDUIAction? {
        return SBASurveyConfiguration.shared.action(for: actionType, on:step)
    }
    
    public func shouldHideAction(for actionType: RSDUIActionType, on step: RSDStep) -> Bool? {
        return SBASurveyConfiguration.shared.shouldHideAction(for: actionType, on: step)
    }
}

extension SBBSurveyInfoScreen : RSDUIStep {
    
    public var stepType: RSDStepType {
        return SBASurveyConfiguration.shared.stepType(for: self) ?? .instruction
    }
    
    public func instantiateStepResult() -> RSDResult {
        return SBASurveyConfiguration.shared.instantiateStepResult(for: self) ?? RSDResultObject(identifier: self.identifier)
    }
}

extension SBBSurveyQuestion : RSDUIStep {
    
    public var stepType: RSDStepType {
        return SBASurveyConfiguration.shared.stepType(for: self) ?? .form
    }
    
    public func instantiateStepResult() -> RSDResult {
        return SBASurveyConfiguration.shared.instantiateStepResult(for: self) ?? RSDCollectionResultObject(identifier: self.identifier)
    }
}

/// Use a protocol so that this can easily be extended to either `SBBSurveyQuestion` or
/// `SBBSurveyConstraints` (if the ui hint is ever refactored to attach to the constraints)
/// This will also allow for fairly easy refactor to support multiple input fields in a single
/// question step.
protocol sbb_InputField : RSDSurveyInputField {
    var uiHintValue : SBBUIHintType? { get }
    var constraints : SBBSurveyConstraints { get }
}

extension SBBSurveyQuestion : RSDFormUIStep {
    
    /// `SBBSurveyQuestion` only supports a single input field per step.
    public var inputFields: [RSDInputField] {
        return [self]
    }
}

extension SBBSurveyQuestion : sbb_InputField {
}

extension sbb_InputField {

    /// The input prompt is not supported.
    public var inputPrompt: String? {
        return nil
    }
    
    public var placeholder: String? {
        guard let constraint = self.constraints as? SBBStringConstraints else { return nil }
        return constraint.patternPlaceholder
    }
    
    public var isOptional: Bool {
        return SBASurveyConfiguration.shared.isOptional(for: self)
    }
    
    public var dataType: RSDFormDataType {
        if let constraint = self.constraints as? SBBMultiValueConstraints {
            let dateType = self.constraints.dataTypeValue.dataType
            let collectionType: RSDFormDataType.CollectionType = constraint.allowMultipleValue ? .multipleChoice : .singleChoice
            return .collection(collectionType, dateType.baseType)
        } else if let constraint = self.constraints as? SBBHeightConstraints {
            return .measurement(.height, constraint.isInfantValue ? .infant : .adult)
        }  else if let constraint = self.constraints as? SBBWeightConstraints {
            return .measurement(.weight, constraint.isInfantValue ? .infant : .adult)
        } else {
            return self.constraints.dataTypeValue.dataType
        }
    }
    
    public var inputUIHint: RSDFormUIHint? {
        return self.uiHintValue?.hint
    }
    
    public var textFieldOptions: RSDTextFieldOptions? {
        return self.constraints as? RSDTextFieldOptions
    }
    
    public var range: RSDRange? {
        return self.constraints as? RSDRange
    }
    
    /// The formatter is not supported.
    public var formatter: Formatter? {
        return nil
    }
    
    /// Optional picker source for a picker or multiple selection input field.
    public var pickerSource: RSDPickerDataSource? {
        return self.constraints as? RSDPickerDataSource
    }
}

extension SBBDataType {
    public var dataType: RSDFormDataType {
        switch self {
            
        case .boolean:
            return .base(.boolean)
        case .date, .dateTime, .time:
            return .base(.date)
        case .decimal:
            return .base(.decimal)
        case .duration:
            return .base(.duration)
        case .integer:
            return .base(.integer)
        case .string:
            return .base(.string)
            
        case .bloodPressure:
            return .measurement(.bloodPressure, .adult)
        case .height:
            return .measurement(.height, .adult)
        case .weight:
            return .measurement(.weight, .adult)
            
        default:
            return .custom(self.rawValue, .string)
        }
    }
}

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

extension SBBStringConstraints: RSDTextFieldOptions, RSDCodableRegExMatchValidator {

    public var textValidator: RSDTextValidator? {
        return (_validationRegex != nil) ? self : nil
    }
    
    public var invalidMessage: String? {
        return self.patternErrorMessage
    }
    
    public var maximumLength: Int {
        return Int(self.maxLengthValue)
    }
    
    public var isSecureTextEntry: Bool {
        return false
    }
    
    public var autocapitalizationType: RSDTextAutocapitalizationType {
        return .none
    }
    
    public var autocorrectionType: RSDTextAutocorrectionType {
        return .default
    }
    
    public var spellCheckingType: RSDTextSpellCheckingType {
        return .no
    }
    
    public var keyboardType: RSDKeyboardType {
        return .default
    }
    
    public var regExPattern: String {
        return _validationRegex ?? ""
    }
    
    private var _validationRegex: String? {
        if self.pattern != nil {
            return self.pattern
        }
        else if self.minLengthValue > 0 {
            assert(self.pattern == nil, "Factory does not currently support items with both a min length and a regex pattern.")
            return "^.{\(self.minLengthValue),}$"
        }
        else {
            return nil
        }
    }
}

extension SBBMultiValueConstraints : RSDChoiceOptions {
    
    public var choices: [RSDChoice] {
        return self.enumeration as? [SBBSurveyQuestionOption] ?? []
    }
    
    public var isOptional: Bool {
        return true
    }
    
    public var defaultAnswer: Any? {
        return nil
    }
}

extension SBBSurveyQuestionOption : RSDChoice, RSDComparable {
    
    public var matchingAnswer: Any? {
        return self.value
    }
    
    public var answerValue: Codable? {
        return self.value as Codable
    }
    
    public var text: String? {
        return self.label
    }
    
    public var isExclusive: Bool {
        return false
    }
    
    public var hasIcon: Bool {
        return self.image != nil
    }
    
    public func fetchIcon(for size: CGSize, callback: @escaping ((UIImage?) -> Void)) {
        self.image?.fetchIcon(for: size, callback: callback)
    }
}

extension SBBImage {
    
    public var size: CGSize {
        return CGSize(width: self.widthValue, height: self.heightValue)
    }
    
    public func fetchIcon(for size: CGSize, callback: @escaping ((UIImage?) -> Void)) {
        DispatchQueue.main.async {
            let img = UIImage(named: self.source)
            callback(img)
        }
    }
}

protocol sbb_NumberRange: RSDNumberRange {
    var maxValue: NSNumber? { get }
    var minValue: NSNumber? { get }
    var step: NSNumber? { get }
    var unit: String? { get }
}

extension SBBIntegerConstraints: sbb_NumberRange {
}

extension SBBDecimalConstraints: sbb_NumberRange {
}

extension SBBHeightConstraints: sbb_NumberRange {
    public var maxValue: NSNumber? { return nil }
    public var minValue: NSNumber? { return nil }
    public var step: NSNumber? { return nil }
}

extension SBBWeightConstraints: sbb_NumberRange {
    public var maxValue: NSNumber? { return nil }
    public var minValue: NSNumber? { return nil }
    public var step: NSNumber? { return nil }
}

extension sbb_NumberRange {
    
    public var minimumValue: Decimal? {
        return self.minValue?.decimalValue
    }
    
    public var maximumValue: Decimal? {
        return self.maxValue?.decimalValue
    }
    
    public var stepInterval: Decimal? {
        return self.step?.decimalValue
    }
}

extension SBBDurationConstraints: RSDDurationRange {
    
    public var minimumDuration: Measurement<UnitDuration> {
        return Measurement(value: 0, unit: _baseUnit)
    }
    
    public var maximumDuration: Measurement<UnitDuration>? {
        return nil
    }
    
    public var stepInterval: Int? {
        return nil
    }
    
    public var durationUnits: Set<UnitDuration> {
        return _baseUnit.defaultUnits()
    }
    
    private var _baseUnit: UnitDuration {
        return self.unit?.unitDuration() ?? .seconds
    }
}

extension String {
    fileprivate func unitDuration() -> UnitDuration? {
        return UnitDuration(fromSymbol: self)
    }
}

protocol sbb_DateRange : RSDDateRange {
    var allowFuture: NSNumber? { get }
    var earliestValue: Date? { get }
    var latestValue: Date? { get }
}

extension SBBDateConstraints : sbb_DateRange {
    public var dateCoder: RSDDateCoder? {
        return RSDDateCoderObject.dateOnly
    }
}

extension SBBDateTimeConstraints : sbb_DateRange {
    public var dateCoder: RSDDateCoder? {
        return RSDDateCoderObject.timestamp
    }
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
        return nil
    }
    
    public var minuteInterval: Int? {
        return nil
    }
}

extension SBBTimeConstraints : RSDDateRange {
    
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
}
