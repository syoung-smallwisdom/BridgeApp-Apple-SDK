//
//  StepProtocolTests.swift
//  BridgeAppSDK
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

import XCTest
@testable import BridgeApp
@testable import Research

class StepProtocolTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        SBABridgeConfiguration.shared = SBABridgeConfiguration()
        SBASurveyConfiguration.shared = SBASurveyConfiguration()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUIHints() {
        XCTAssertNil(SBBUIHintType.bloodPressure.hint)
        XCTAssertNil(SBBUIHintType.height.hint)
        XCTAssertNil(SBBUIHintType.weight.hint)
        XCTAssertEqual(SBBUIHintType.checkbox.hint, .checkbox)
        XCTAssertEqual(SBBUIHintType.combobox.hint, .combobox)
        XCTAssertEqual(SBBUIHintType.datePicker.hint, .picker)
        XCTAssertEqual(SBBUIHintType.dateTimePicker.hint, .picker)
        XCTAssertEqual(SBBUIHintType.timePicker.hint, .picker)
        XCTAssertEqual(SBBUIHintType.textfield.hint, .textfield)
        XCTAssertEqual(SBBUIHintType.numberfield.hint, .textfield)
        XCTAssertEqual(SBBUIHintType.multilineText, .multilineText)
        XCTAssertEqual(SBBUIHintType.radioButton, .radioButton)
    }
    
    // MARK: SBASurveyConfiguration
    
    func testSurveyInfoScreen_Configuration_Default() {
        
        let inputStep = SBBSurveyInfoScreen()
        inputStep.identifier = "abc123"
        
        XCTAssertNil(inputStep.action(for: .navigation(.skip), on: inputStep))
        XCTAssertNil(inputStep.shouldHideAction(for: .navigation(.skip), on: inputStep))
        XCTAssertNil(inputStep.viewTheme)
        XCTAssertNil(inputStep.colorMapping)
        XCTAssertEqual(inputStep.stepType, .instruction)
        XCTAssertTrue(inputStep.instantiateStepResult() is RSDResultObject)
    }
    
    func testSurveyQuestion_Configuration_Default() {
        
        let inputStep = createQuestion(.checkbox, SBBBooleanConstraints())
        inputStep.identifier = "abc123"
        
        XCTAssertNil(inputStep.action(for: .navigation(.skip), on: inputStep))
        XCTAssertNil(inputStep.shouldHideAction(for: .navigation(.skip), on: inputStep))
        XCTAssertNil(inputStep.viewTheme)
        XCTAssertNil(inputStep.colorMapping)
        XCTAssertTrue(inputStep.instantiateStepResult() is AnswerResultObject)
        XCTAssertTrue(inputStep.isOptional)
    }
    
    func testSurveyInfoScreen_Configuration_Overrides() {
        
        let testConfig = TestSurveyConfiguration()
        SBASurveyConfiguration.shared = testConfig
        let inputStep = SBBSurveyInfoScreen()
        inputStep.identifier = "abc123"
        
        XCTAssertNotNil(inputStep.action(for: .navigation(.skip), on: inputStep))
        XCTAssertNotNil(inputStep.shouldHideAction(for: .navigation(.skip), on: inputStep))
        XCTAssertNotNil(inputStep.viewTheme)
        XCTAssertNotNil(inputStep.colorMapping)
        XCTAssertEqual(inputStep.stepType, testConfig.stepType)
        XCTAssertTrue(inputStep.instantiateStepResult() is TestResult)
    }
    
    func testSurveyQuestion_Configuration_Overrides() {
        
        let testConfig = TestSurveyConfiguration()
        SBASurveyConfiguration.shared = testConfig
        let inputStep = SBBSurveyQuestion()
        inputStep.identifier = "abc123"
        
        XCTAssertNotNil(inputStep.action(for: .navigation(.skip), on: inputStep))
        XCTAssertNotNil(inputStep.shouldHideAction(for: .navigation(.skip), on: inputStep))
        XCTAssertNotNil(inputStep.viewTheme)
        XCTAssertNotNil(inputStep.colorMapping)
        XCTAssertEqual(inputStep.stepType, testConfig.stepType)
        XCTAssertTrue(inputStep.instantiateStepResult() is TestResult)
        XCTAssertFalse(inputStep.isOptional)
    }
    
    func testSurveyQuestion_Required_TRUE() {
        
        let testConfig = TestSurveyConfiguration()
        SBASurveyConfiguration.shared = testConfig
        let constraints = SBBBooleanConstraints()
        constraints.required = NSNumber(value: true)
        let inputStep = createQuestion(.checkbox, constraints)
        
        XCTAssertFalse(inputStep.isOptional)
    }
    
    func testSurveyQuestion_Required_FALSE() {
        
        let testConfig = TestSurveyConfiguration()
        SBASurveyConfiguration.shared = testConfig
        let constraints = SBBBooleanConstraints()
        constraints.required = NSNumber(value: false)
        let inputStep = createQuestion(.checkbox, constraints)
        
        XCTAssertTrue(inputStep.isOptional)
    }
    
    // MARK: SBBSurveyInfoScreen
    
    func testStep_SBBSurveyInfoScreen() {
        let inputStep = SBBSurveyInfoScreen()
        inputStep.identifier = "abc123"
        inputStep.title = "Title"
        inputStep.prompt = "Text"
        inputStep.promptDetail = "Detail"
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertEqual(surveyStep.title, "Title")
        XCTAssertEqual(surveyStep.subtitle, "Text")
        XCTAssertEqual(surveyStep.detail, "Detail")
        
        let copy = inputStep.copy(with: "xyz")
        XCTAssertEqual(copy.identifier, "xyz")
        XCTAssertEqual(copy.title, "Title")
        XCTAssertEqual(copy.subtitle, "Text")
        XCTAssertEqual(copy.detail, "Detail")
    }
    
    // MARK: BooleanConstraints
    
    func testStep_BooleanConstraints_List_NoRules() {
        
        let inputStep = createQuestion(.list, SBBBooleanConstraints())
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        
        let answerType = inputStep.answerType
        XCTAssertTrue(answerType is AnswerTypeBoolean, "\(answerType)")
        
        let inputItems = inputStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 2)
        
        guard let yesItem = inputItems.first as? ChoiceItemWrapper,
            let noItem = inputItems.last as? ChoiceItemWrapper else {
            XCTFail("Failed to return expected items. \(inputItems)")
            return
        }
        
        XCTAssertEqual(yesItem.choice.matchingValue, .boolean(true))
        XCTAssertEqual(noItem.choice.matchingValue, .boolean(false))
        XCTAssertEqual(yesItem.inputUIHint, .list)
        XCTAssertEqual(noItem.inputUIHint, .list)
    }
    
    func testStep_BooleanConstraints_Checkbox_NoRules() {
        
        let inputStep = createQuestion(.checkbox, SBBBooleanConstraints())
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertNil(surveyStep.detail)
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        
        let answerType = inputStep.answerType
        XCTAssertTrue(answerType is AnswerTypeBoolean, "\(answerType)")
        
        let inputItems = inputStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let checkboxItem = inputItems.first as? CheckboxInputItem else {
            XCTFail("Failed to return expected items. \(inputItems)")
            return
        }
        
        XCTAssertEqual(checkboxItem.fieldLabel, "Question prompt detail")
    }
 
    // MARK: MultiValueConstraints
    
    func testStep_MultiValueConstraints_Single_NoRules() {
        
        let inputStep = createMultipleChoiceQuestion(allowMultiple: false)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
    }
    
    func testStep_MultiValueConstraints_Multiple_NoRules() {
        
        let inputStep = createMultipleChoiceQuestion(allowMultiple: true)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertFalse(surveyStep.isSingleAnswer)

    }
    
    func testStep_MultiValueConstraints_StringValue() {
        
        let inputStep = createMultipleChoiceQuestion(allowMultiple: false)
        
        let surveyStep = inputStep
        XCTAssertTrue(surveyStep.answerType is AnswerTypeString, "\(surveyStep.answerType)")

        let items = inputStep.buildInputItems()
        guard let choices = items as? [ChoiceItemWrapper] else {
            XCTFail("Input items not of expected type: \(items)")
            return
        }
        
        let expectedCount = 4
        if choices.count == expectedCount {
            XCTAssertEqual(choices[0].text, "Yes, I have done this")
            XCTAssertEqual(choices[0].choice.matchingValue, .string("true"))
            XCTAssertFalse(choices[0].isExclusive)
            XCTAssertEqual(choices[1].text, "No, I have never done this")
            XCTAssertEqual(choices[1].choice.matchingValue, .string("false"))
            XCTAssertFalse(choices[1].isExclusive)
            XCTAssertEqual(choices[2].text, "Maybe")
            XCTAssertEqual(choices[2].choice.matchingValue, .string("maybe"))
            XCTAssertFalse(choices[2].isExclusive)
            XCTAssertEqual(choices[3].text, "Prefer not to answer")
            XCTAssertEqual(choices[3].choice.matchingValue, .string("skip"))
            XCTAssertTrue(choices[3].isExclusive)
        } else {
            XCTAssertEqual(choices.count, expectedCount, "\(choices)")
        }
    }
    
    func testStep_MultiValueConstraints_NumberValue() {
        
        let constraints = SBBMultiValueConstraints()
        constraints.allowMultiple = NSNumber(value: false)
        constraints.dataType = "decimal"
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "Yes, I have done this",
                "value" : 0,
                "type" : "SurveyQuestionOption"
                ]))
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "No, I have never done this",
                "value" : 1,
                "type" : "SurveyQuestionOption"
                ]))
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "Maybe",
                "value" : 2,
                "type" : "SurveyQuestionOption"
                ]))
        
        let inputStep = createQuestion(.list, constraints)
        
        let surveyStep = inputStep
        XCTAssertTrue(surveyStep.answerType is AnswerTypeNumber, "\(surveyStep.answerType)")

        let items = inputStep.buildInputItems()
        guard let choices = items as? [ChoiceItemWrapper] else {
            XCTFail("Input items not of expected type: \(items)")
            return
        }
        
        let expectedCount = 3
        if choices.count == expectedCount {
            XCTAssertEqual(choices[0].text, "Yes, I have done this")
            XCTAssertEqual(choices[0].choice.matchingValue, .number(0))
            XCTAssertFalse(choices[0].isExclusive)
            XCTAssertEqual(choices[1].text, "No, I have never done this")
            XCTAssertEqual(choices[1].choice.matchingValue, .number(1))
            XCTAssertFalse(choices[1].isExclusive)
            XCTAssertEqual(choices[2].text, "Maybe")
            XCTAssertEqual(choices[2].choice.matchingValue, .number(2))
            XCTAssertFalse(choices[2].isExclusive)
        } else {
            XCTAssertEqual(choices.count, expectedCount, "\(choices)")
        }
    }
    
    func testStep_MultiValueConstraints_IntegerValue() {
        
        let constraints = SBBMultiValueConstraints()
        constraints.allowMultiple = NSNumber(value: false)
        constraints.dataType = "integer"
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "Yes, I have done this",
                "value" : 0,
                "type" : "SurveyQuestionOption"
                ]))
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "No, I have never done this",
                "value" : 1,
                "type" : "SurveyQuestionOption"
                ]))
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "Maybe",
                "value" : 2,
                "type" : "SurveyQuestionOption"
                ]))
        
        let inputStep = createQuestion(.list, constraints)
        
        let surveyStep = inputStep
        XCTAssertTrue(surveyStep.answerType is AnswerTypeInteger, "\(surveyStep.answerType)")

        let items = inputStep.buildInputItems()
        guard let choices = items as? [ChoiceItemWrapper] else {
            XCTFail("Input items not of expected type: \(items)")
            return
        }
        
        let expectedCount = 3
        if choices.count == expectedCount {
            XCTAssertEqual(choices[0].text, "Yes, I have done this")
            XCTAssertEqual(choices[0].choice.matchingValue, .integer(0))
            XCTAssertFalse(choices[0].isExclusive)
            XCTAssertEqual(choices[1].text, "No, I have never done this")
            XCTAssertEqual(choices[1].choice.matchingValue, .integer(1))
            XCTAssertFalse(choices[1].isExclusive)
            XCTAssertEqual(choices[2].text, "Maybe")
            XCTAssertEqual(choices[2].choice.matchingValue, .integer(2))
            XCTAssertFalse(choices[2].isExclusive)
        } else {
            XCTAssertEqual(choices.count, expectedCount, "\(choices)")
        }
    }
    
    func createMultipleChoiceQuestion(allowMultiple: Bool) -> SBBSurveyQuestion {
        
        let constraints = SBBMultiValueConstraints()
        constraints.allowMultiple = NSNumber(value: allowMultiple as Bool)
        constraints.dataType = "string"
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "Yes, I have done this",
                "value" : "true",
                "type" : "SurveyQuestionOption"
                ]))
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "No, I have never done this",
                "value" : "false",
                "type" : "SurveyQuestionOption"
                ]))
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "Maybe",
                "value" : "maybe",
                "type" : "SurveyQuestionOption"
                ]))
        constraints.addEnumerationObject(
            SBBSurveyQuestionOption(dictionaryRepresentation:[
                "label" : "Prefer not to answer",
                "value" : "skip",
                "type" : "SurveyQuestionOption",
                "exclusive" : true
                ]))
        
        return createQuestion(allowMultiple ? .list : .radioButton, constraints)
    }
  
    // MARK: StringConstraints

    func testStep_TextAnswer_NoRules() {

        let inputStep = createQuestion(.textfield, SBBStringConstraints())

        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        XCTAssertTrue(surveyStep.answerType is AnswerTypeString, "\(surveyStep.answerType) is not AnswerTypeString")
    }
    

    func testStep_TextAnswer_ValidationRegEx() {

        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.pattern = "^[0-9A-F]+$"
        constraints.patternErrorMessage = "Should be hexidecimal"
        
        let inputStep = createQuestion(.textfield, constraints)
        
        let inputItems = inputStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        let textValidator = item.buildTextValidator()
        if let regexValidator = textValidator as? RegExValidator {
            XCTAssertEqual(regexValidator.invalidMessage, "Should be hexidecimal")
            XCTAssertEqual(regexValidator.pattern.pattern, "^[0-9A-F]+$")
        }
        else {
            XCTFail("\(textValidator) not of expected type `RegExValidator`")
        }
        
        XCTAssertNil(item.buildPickerSource())
        XCTAssertEqual(item.keyboardOptions as? KeyboardOptionsObject, KeyboardOptionsObject())
    }

    func testStep_TextAnswer_MinAndMaxLength() {

        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.minLength = NSNumber(value: 4)
        constraints.maxLength = NSNumber(value: 8)
        
        let inputStep = createQuestion(.textfield, constraints)
        
        let inputItems = inputStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        let textValidator = item.buildTextValidator()
        if let regexValidator = textValidator as? RegExValidator {
            XCTAssertEqual(regexValidator.invalidMessage, "Must be at least 4 characters and less than or equal to 8 characters.")
            XCTAssertEqual(regexValidator.pattern.pattern, "^.{4,8}$")
        }
        else {
            XCTFail("\(textValidator) not of expected type `RegExValidator`")
        }
        
        XCTAssertNil(item.buildPickerSource())
        XCTAssertEqual(item.keyboardOptions as? KeyboardOptionsObject, KeyboardOptionsObject())
    }

    func testStep_TextAnswer_MinLengthOnly() {

        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.minLength = NSNumber(value: 4)

        let inputStep = createQuestion(.textfield, constraints)
        
        let inputItems = inputStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        let textValidator = item.buildTextValidator()
        if let regexValidator = textValidator as? RegExValidator {
            XCTAssertEqual(regexValidator.invalidMessage, "Must be at least 4 characters.")
            XCTAssertEqual(regexValidator.pattern.pattern, "^.{4,}$")
        }
        else {
            XCTFail("\(textValidator) not of expected type `RegExValidator`")
        }
        
        XCTAssertNil(item.buildPickerSource())
        XCTAssertEqual(item.keyboardOptions as? KeyboardOptionsObject, KeyboardOptionsObject())
    }
    
    func testStep_TextAnswer_MaxLength_Only() {

        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.maxLength = NSNumber(value: 8)
        
        let inputStep = createQuestion(.textfield, constraints)
        
        let inputItems = inputStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        let textValidator = item.buildTextValidator()
        if let regexValidator = textValidator as? RegExValidator {
            XCTAssertEqual(regexValidator.invalidMessage, "Must be less than or equal to 8 characters.")
            XCTAssertEqual(regexValidator.pattern.pattern, "^.{0,8}$")
        }
        else {
            XCTFail("\(textValidator) not of expected type `RegExValidator`")
        }
        
        XCTAssertNil(item.buildPickerSource())
        XCTAssertEqual(item.keyboardOptions as? KeyboardOptionsObject, KeyboardOptionsObject())
    }
    
    func testStep_TextAnswer_MinAndMaxLength_Same() {

        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.minLength = NSNumber(value: 4)
        constraints.maxLength = NSNumber(value: 4)
        
        let inputStep = createQuestion(.textfield, constraints)
        
        let inputItems = inputStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        let textValidator = item.buildTextValidator()
        if let regexValidator = textValidator as? RegExValidator {
            XCTAssertEqual(regexValidator.invalidMessage, "Must be 4 characters.")
            XCTAssertEqual(regexValidator.pattern.pattern, "^.{4,4}$")
        }
        else {
            XCTFail("\(textValidator) not of expected type `RegExValidator`")
        }
        
        XCTAssertNil(item.buildPickerSource())
        XCTAssertEqual(item.keyboardOptions as? KeyboardOptionsObject, KeyboardOptionsObject())
    }

    // MARK: DateTimeConstraints
    
    func testStep_DateTimeConstraints_NoRules() {
        
        let constraints = SBBDateTimeConstraints()
        constraints.allowFutureValue = false
        
        let inputStep = createQuestion(.dateTimePicker, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        if let answerType = surveyStep.answerType as? AnswerTypeDateTime {
            XCTAssertEqual(answerType.codingFormat, "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")
        }
        else {
            XCTFail("\(surveyStep.answerType) is not AnswerTypeDateTime")
        }
        
        let inputItems = inputStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        let textValidator = item.buildTextValidator()
        if let dateValidator = textValidator as? DateTimeValidator {
            XCTAssertEqual(dateValidator.pickerMode, .dateAndTime)
            XCTAssertNotNil(dateValidator.range)
        }
        else {
            XCTFail("\(textValidator) not of expected type `DateTimeValidator`")
        }
        
        XCTAssertEqual(item.keyboardOptions as? KeyboardOptionsObject, KeyboardOptionsObject.dateTimeEntryOptions)
        
        let picker = item.buildPickerSource()
        XCTAssertTrue(picker is RSDDatePickerDataSource, "\(String(describing: picker)) is not `RSDDatePickerDataSource`")
    }
    
    func testStep_DateTimeConstraints_MinMaxDate() {
        
        let constraints = SBBDateTimeConstraints()
        let minDate = Date().addingTimeInterval(-5 * 24 * 3600)
        let maxDate = Date().addingTimeInterval(5 * 24 * 3600)
        constraints.earliestValue = minDate
        constraints.latestValue = maxDate
        
        let dateRange = constraints
        XCTAssertNil(dateRange.shouldAllowFuture)
        XCTAssertEqual(dateRange.minDate, minDate)
        XCTAssertEqual(dateRange.maxDate, maxDate)
        XCTAssertEqual(dateRange.dateCoder as? RSDDateCoderObject, .timestamp)
    }
    
    // MARK: SBBDateConstraints
    
    func testStep_DateConstraints_NoRules() {
        
        let constraints = SBBDateConstraints()
        constraints.allowFutureValue = false
        
        let inputStep = createQuestion(.dateTimePicker, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        if let answerType = surveyStep.answerType as? AnswerTypeDateTime {
            XCTAssertEqual(answerType.codingFormat, "yyyy-MM-dd")
        }
        else {
            XCTFail("\(surveyStep.answerType) is not AnswerTypeDateTime")
        }
        
        let inputItems = inputStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        let textValidator = item.buildTextValidator()
        if let dateValidator = textValidator as? DateTimeValidator {
            XCTAssertEqual(dateValidator.pickerMode, .date)
            XCTAssertNotNil(dateValidator.range)
        }
        else {
            XCTFail("\(textValidator) not of expected type `DateTimeValidator`")
        }
        
        XCTAssertEqual(item.keyboardOptions as? KeyboardOptionsObject, KeyboardOptionsObject.dateTimeEntryOptions)
        
        let picker = item.buildPickerSource()
        XCTAssertTrue(picker is RSDDatePickerDataSource, "\(String(describing: picker)) is not `RSDDatePickerDataSource`")
    }
    
    func testStep_DateConstraints_MinMaxDate() {
        
        let constraints = SBBDateConstraints()
        let minDate = Date().addingTimeInterval(-5 * 24 * 3600)
        let maxDate = Date().addingTimeInterval(5 * 24 * 3600)
        constraints.earliestValue = minDate
        constraints.latestValue = maxDate
        
        let dateRange = constraints
        XCTAssertNil(dateRange.shouldAllowFuture)
        XCTAssertEqual(dateRange.minDate, minDate)
        XCTAssertEqual(dateRange.maxDate, maxDate)
        XCTAssertEqual(dateRange.dateCoder as? RSDDateCoderObject, .dateOnly)
    }
    
    func testStep_DateConstraints_AllowFuture_False() {
        let constraints = SBBDateConstraints()
        constraints.allowFuture = NSNumber(value: false)
        
        let dateRange = constraints
        XCTAssertFalse(dateRange.shouldAllowFuture ?? true)
        XCTAssertNil(dateRange.shouldAllowPast)
        XCTAssertNil(dateRange.minDate)
        XCTAssertNil(dateRange.maxDate)
        XCTAssertEqual(dateRange.dateCoder as? RSDDateCoderObject, .dateOnly)
    }
    
    func testStep_DateConstraints_AllowPast_True() {
        let constraints = SBBDateConstraints()
        constraints.allowPast = NSNumber(value: true)
        
        let dateRange = constraints
        XCTAssertNil(dateRange.shouldAllowFuture)
        XCTAssertTrue(dateRange.shouldAllowPast ?? false)
        XCTAssertNil(dateRange.minDate)
        XCTAssertNil(dateRange.maxDate)
        XCTAssertEqual(dateRange.dateCoder as? RSDDateCoderObject, .dateOnly)
    }

    
    // MARK: TimeConstraints
    
    func testStep_TimeConstraints_NoRules() {
        
        let inputStep = createQuestion(.timePicker, SBBTimeConstraints())
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        if let answerType = surveyStep.answerType as? AnswerTypeDateTime {
            XCTAssertEqual(answerType.codingFormat, "HH:mm:ss")
        }
        else {
            XCTFail("\(surveyStep.answerType) is not AnswerTypeDateTime")
        }
        
        let inputItems = inputStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        let textValidator = item.buildTextValidator()
        if let dateValidator = textValidator as? DateTimeValidator {
            XCTAssertEqual(dateValidator.pickerMode, .time)
            XCTAssertNotNil(dateValidator.range)
        }
        else {
            XCTFail("\(textValidator) not of expected type `DateTimeValidator`")
        }
        
        XCTAssertEqual(item.keyboardOptions as? KeyboardOptionsObject, KeyboardOptionsObject.dateTimeEntryOptions)
        
        let picker = item.buildPickerSource()
        XCTAssertTrue(picker is RSDDatePickerDataSource, "\(String(describing: picker)) is not `RSDDatePickerDataSource`")
    }

    
    // MARK: IntegerConstraints
    
    func testStep_IntegerConstraints_NoRules() {
        
        let constraints = SBBIntegerConstraints()
        constraints.minValue = NSNumber(value: -3);
        constraints.maxValue = NSNumber(value: 5);
        constraints.unit = "pie";
        constraints.step = NSNumber(value: 2)
        
        let inputStep = createQuestion(.numberfield, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        XCTAssertTrue(surveyStep.answerType is AnswerTypeInteger, "\(surveyStep.answerType) is not AnswerTypeInteger")

        let inputItems = surveyStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        XCTAssertEqual(item.placeholder, "pie")
        
        let textValidator = item.buildTextValidator()
        if let range = textValidator as? IntegerFormatOptions {
            XCTAssertEqual(range.minimumValue, -3)
            XCTAssertEqual(range.maximumValue, 5)
            XCTAssertEqual(range.stepInterval, 2)
        }
        else {
            XCTFail("\(textValidator) not of expected type `DateTimeValidator`")
        }
    }
   
    // MARK: DecimalConstraints
    
    func testStep_DecimalConstraints_NoRules() {
        
        let constraints = SBBDecimalConstraints()
        constraints.minValue = NSNumber(value: -3.5);
        constraints.maxValue = NSNumber(value: 5.5);
        constraints.unit = "pie";
        constraints.step = NSNumber(value: 0.5)
        
        let inputStep = createQuestion(.numberfield, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        XCTAssertTrue(surveyStep.answerType is AnswerTypeNumber, "\(surveyStep.answerType) is not AnswerTypeNumber")

        let inputItems = surveyStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        XCTAssertEqual(item.placeholder, "pie")
        
        let textValidator = item.buildTextValidator()
        if let range = textValidator as? DoubleFormatOptions {
            XCTAssertEqual(range.minimumValue, -3.5)
            XCTAssertEqual(range.maximumValue, 5.5)
            XCTAssertEqual(range.stepInterval, 0.5)
        }
        else {
            XCTFail("\(textValidator) not of expected type `DateTimeValidator`")
        }
    }
    
 
    // MARK: SBBHeightConstraints
    
    func testStep_HeightConstraints_Infant() {
        
        let constraints = SBBHeightConstraints()
        constraints.forInfantValue = true
        
        let inputStep = createQuestion(.height, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        if let answerType = surveyStep.answerType as? AnswerTypeMeasurement {
            XCTAssertEqual(answerType.unit, "cm")
        }
        else {
            XCTFail("\(surveyStep.answerType) is not AnswerTypeMeasurement")
        }
        
        let inputItems = surveyStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? HeightInputItemObject else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        XCTAssertTrue(item.lengthFormatter.isForChildHeightUse)
    }
    
    func testStep_HeightConstraints_Adult() {
        let constraints = SBBHeightConstraints()
        let inputStep = createQuestion(.height, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        if let answerType = surveyStep.answerType as? AnswerTypeMeasurement {
            XCTAssertEqual(answerType.unit, "cm")
        }
        else {
            XCTFail("\(surveyStep.answerType) is not AnswerTypeMeasurement")
        }
        
        let inputItems = surveyStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? HeightInputItemObject else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        XCTAssertFalse(item.lengthFormatter.isForChildHeightUse)
    }
    
    
    // MARK: SBBWeightConstraints
    
    func testStep_WeightConstraints_Infant() {
        
        let constraints = SBBWeightConstraints()
        constraints.forInfantValue = true
        
        let inputStep = createQuestion(.weight, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        if let answerType = surveyStep.answerType as? AnswerTypeMeasurement {
            XCTAssertEqual(answerType.unit, "kg")
        }
        else {
            XCTFail("\(surveyStep.answerType) is not AnswerTypeMeasurement")
        }
        
        let inputItems = surveyStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? WeightInputItemObject else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        XCTAssertTrue(item.massFormatter.isForInfantMassUse)
    }
    
    func testStep_WeightConstraints_Adult() {
        let constraints = SBBWeightConstraints()
        let inputStep = createQuestion(.weight, constraints)

        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        if let answerType = surveyStep.answerType as? AnswerTypeMeasurement {
            XCTAssertEqual(answerType.unit, "kg")
        }
        else {
            XCTFail("\(surveyStep.answerType) is not AnswerTypeMeasurement")
        }
        
        let inputItems = surveyStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? WeightInputItemObject else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
        
        XCTAssertFalse(item.massFormatter.isForInfantMassUse)
    }
    
        
    // MARK: SBBYearConstraints
    
    func testStep_YearConstraints_NoRules() {
        
        let constraints = SBBYearConstraints()
        
        let inputStep = createQuestion(.textfield, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        XCTAssertTrue(surveyStep.answerType is AnswerTypeInteger, "\(surveyStep.answerType) is not AnswerTypeInteger")

        let inputItems = surveyStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
                
        let textValidator = item.buildTextValidator()
        if let dateRange = textValidator as? YearFormatOptions {
            XCTAssertNil(dateRange.allowFuture)
            XCTAssertNil(dateRange.allowPast)
            XCTAssertNil(dateRange.minimumYear)
            XCTAssertNil(dateRange.maximumYear)
        }
        else {
            XCTFail("\(textValidator) not of expected type `DateTimeValidator`")
        }
    }
    
    func testStep_YearConstraints_MinFutureDate() {
        
        let constraints = SBBYearConstraints()
        let minDate = Date().addingNumberOfYears(-24)
        constraints.earliestValue = minDate
        constraints.allowFuture = NSNumber(booleanLiteral: false)
        
        let inputStep = createQuestion(.textfield, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        XCTAssertTrue(surveyStep.answerType is AnswerTypeInteger, "\(surveyStep.answerType) is not AnswerTypeInteger")

        let inputItems = surveyStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
                
        let textValidator = item.buildTextValidator()
        if let dateRange = textValidator as? YearFormatOptions {
            XCTAssertNotNil(dateRange.allowFuture)
            XCTAssertNil(dateRange.allowPast)
            XCTAssertNotNil(dateRange.minimumYear)
            XCTAssertNil(dateRange.maximumYear)
        }
        else {
            XCTFail("\(textValidator) not of expected type `DateTimeValidator`")
        }
    }
    
    func testStep_YearConstraints_MaxPastDate() {
        
        let constraints = SBBYearConstraints()
        let maxDate = Date().addingNumberOfYears(24)
        constraints.latestValue = maxDate
        constraints.allowPast = NSNumber(booleanLiteral: false)
        
        let inputStep = createQuestion(.textfield, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.subtitle, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        XCTAssertTrue(surveyStep.isOptional)
        XCTAssertTrue(surveyStep.isSingleAnswer)
        XCTAssertTrue(surveyStep.answerType is AnswerTypeInteger, "\(surveyStep.answerType) is not AnswerTypeInteger")

        let inputItems = surveyStep.buildInputItems()
        XCTAssertEqual(inputItems.count, 1)
        
        guard let item = inputItems.first as? KeyboardTextInputItem else {
            XCTFail("\(inputItems) not of expected type `KeyboardTextInputItem`")
            return
        }
                
        let textValidator = item.buildTextValidator()
        if let dateRange = textValidator as? YearFormatOptions {
            XCTAssertNil(dateRange.allowFuture)
            XCTAssertNotNil(dateRange.allowPast)
            XCTAssertNil(dateRange.minimumYear)
            XCTAssertNotNil(dateRange.maximumYear)
        }
        else {
            XCTFail("\(textValidator) not of expected type `DateTimeValidator`")
        }
    }

    
    // MARK: Helper methods
    
    func createQuestion(_ uiHint: SBBUIHintType, _ constraints: SBBSurveyConstraints) -> SBBSurveyQuestion {
        let inputStep:SBBSurveyQuestion = SBBSurveyQuestion()
        inputStep.uiHint = uiHint.rawValue.lowercased()
        inputStep.identifier = "abc123"
        inputStep.guid = "c564984a-0951-48b5-a490-43d07aa04886"
        inputStep.prompt = "Question prompt"
        inputStep.promptDetail = "Question prompt detail"
        inputStep.constraints = constraints
        return inputStep
    }
}

// MARK: Test structs

struct TestResult : RSDResult {
    
    let identifier: String
    var type: RSDResultType = .base
    var startDate: Date = Date()
    var endDate: Date = Date()
    
    init(identifier: String) {
        self.identifier = identifier
    }
}

struct TestAsyncActionConfiguration : RSDAsyncActionConfiguration {
    var permissionTypes: [RSDPermissionType] = []
    var identifier: String = "foo"
    var startStepIdentifier: String?
    var permissions: [RSDPermissionType] = []
    func validate() throws {
    }
    init() {
    }
}

class TestSurveyConfiguration : SBASurveyConfiguration {
    
    var stepType: RSDStepType = "foo"
    override func stepType(for step: SBBSurveyElement) -> RSDStepType {
        return stepType
    }
    
    override func instantiateStepResult(for step: SBBSurveyElement) -> RSDResult? {
        return TestResult(identifier: step.identifier)
    }
    
    override func isOptional(for inputField: SBBSurveyQuestion) -> Bool {
        return false
    }
    
    override func viewTheme(for surveyElement: SBBSurveyElement) -> RSDViewThemeElement? {
        return RSDViewThemeElementObject(viewIdentifier: "foo")
    }
    
    override func colorMapping(for surveyElement: SBBSurveyElement) -> RSDColorMappingThemeElement? {
        return RSDSingleColorThemeElementObject(colorStyle: .accent)
    }
    
    override func progressMarkers(for survey: SBBSurvey) -> [String]? {
        return ["a", "b", "c"]
    }
    
    override func action(for actionType: RSDUIActionType, on step: RSDStep, callingObject: Any? = nil) -> RSDUIAction? {
        return RSDUIActionObject(iconName: "foo")
    }
    
    override func shouldHideAction(for actionType: RSDUIActionType, on step: RSDStep, callingObject: Any? = nil) -> Bool? {
        return true
    }
}
