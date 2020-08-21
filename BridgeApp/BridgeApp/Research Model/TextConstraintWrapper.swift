//
//  TextConstraintWrapper.swift
//  BridgeApp (iOS)
//
//  Created by Shannon Young on 8/20/20.
//  Copyright © 2020 Sage Bionetworks. All rights reserved.
//

import Foundation

class AbstractTextConstraintsWrapper {
    
    var answerType: AnswerType { question.answerType }
    
    var identifier: String? { nil }
    
    var inputUIHint: RSDFormUIHint { question.uiHintValue?.hint ?? .textfield }
    
    var fieldLabel: String? { nil }
    
    let placeholder: String?
    
    var isOptional: Bool { question.isOptional }
    
    var isExclusive: Bool { true }

    let question: SBBSurveyQuestion
    
    init(question: SBBSurveyQuestion) {
        self.question = question
        self.placeholder = (question.constraints as? sbb_PatternPlaceholder)?.patternPlaceholder
    }
}

class TextEntryConstraintsWrapper : AbstractTextConstraintsWrapper, KeyboardTextInputItem {
    
    let keyboardOptions: KeyboardOptions
    
    override init(question: SBBSurveyQuestion) {
        self.keyboardOptions = (question.constraints as? sbb_KeyboardOptionsBuilder)?.buildKeyboardOptions() ?? KeyboardOptionsObject()
        super.init(question: question)
    }
    
    func buildTextValidator() -> TextInputValidator {
        (question.constraints as? sbb_TextValidatorBuilder)?.buildTextValidator() ?? PassThruValidator()
    }
    
    func buildPickerSource() -> RSDPickerDataSource? {
        question.constraints as? RSDPickerDataSource
    }
}
 
class DateEntryConstraintsWrapper : AbstractTextConstraintsWrapper, KeyboardTextInputItem {
    
    var keyboardOptions: KeyboardOptions {
        KeyboardOptionsObject.dateTimeEntryOptions
    }
    
    func buildTextValidator() -> TextInputValidator {
        guard let pickerMode = (self.question.constraints as? RSDDatePickerDataSource)?.datePickerMode
            else {
                assertionFailure("Expected that the `DateEntryConstraintsWrapper` constraints will implement the `RSDDatePickerDataSource` protocol.")
                return PassThruValidator()
        }
        let formatOptions = self.question.constraints as? RSDDateRange
        return DateTimeValidator(pickerMode: pickerMode, range: formatOptions)
    }
    
    func buildPickerSource() -> RSDPickerDataSource? {
        self.question.constraints as? RSDDatePickerDataSource
    }
}
