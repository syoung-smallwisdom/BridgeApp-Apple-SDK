//
//  TextConstraintWrapper.swift
//  BridgeApp (iOS)
//
//  Copyright © 2020 Sage Bionetworks. All rights reserved.
//
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
import BridgeSDK
import JsonModel
import Research

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
