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
    
    func testDataTypes() {
        XCTAssertEqual(SBBDataType.bloodPressure.dataType, .measurement(.bloodPressure, .adult))
        XCTAssertEqual(SBBDataType.height.dataType, .measurement(.height, .adult))
        XCTAssertEqual(SBBDataType.weight.dataType, .measurement(.weight, .adult))
        XCTAssertEqual(SBBDataType.boolean.dataType, .base(.boolean))
        XCTAssertEqual(SBBDataType.date.dataType, .base(.date))
        XCTAssertEqual(SBBDataType.dateTime.dataType, .base(.date))
        XCTAssertEqual(SBBDataType.time.dataType, .base(.date))
        XCTAssertEqual(SBBDataType.integer.dataType, .base(.integer))
        XCTAssertEqual(SBBDataType.decimal.dataType, .base(.decimal))
        XCTAssertEqual(SBBDataType.duration.dataType, .base(.duration))
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
        
        let inputStep = SBBSurveyQuestion()
        inputStep.identifier = "abc123"
        
        XCTAssertNil(inputStep.action(for: .navigation(.skip), on: inputStep))
        XCTAssertNil(inputStep.shouldHideAction(for: .navigation(.skip), on: inputStep))
        XCTAssertNil(inputStep.viewTheme)
        XCTAssertNil(inputStep.colorMapping)
        XCTAssertEqual(inputStep.stepType, .form)
        XCTAssertTrue(inputStep.instantiateStepResult() is RSDCollectionResultObject)
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
        XCTAssertEqual(surveyStep.text, "Text")
        XCTAssertEqual(surveyStep.detail, "Detail")
        
        let copy = inputStep.copy(with: "xyz")
        XCTAssertEqual(copy.identifier, "xyz")
        XCTAssertEqual(copy.title, "Title")
        XCTAssertEqual(copy.text, "Text")
        XCTAssertEqual(copy.detail, "Detail")
    }
    
    // MARK: BooleanConstraints
    
    func testStep_BooleanConstraints_NoRules() {
        
        let inputStep = createQuestion(.checkbox, SBBBooleanConstraints())
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .base(.boolean))
        XCTAssertEqual(inputField.inputUIHint, .checkbox)
    }
 
    // MARK: MultiValueConstraints
    
    func testStep_MultiValueConstraints_Single_NoRules() {
        
        let inputStep = createMultipleChoiceQuestion(allowMultiple: false)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .collection(.singleChoice, .string))
        XCTAssertEqual(inputField.inputUIHint, .radioButton)

    }
    
    func testStep_MultiValueConstraints_StringValue() {
        
        let inputStep = createMultipleChoiceQuestion(allowMultiple: false)
        let inputField = inputStep
        XCTAssertEqual(inputField.dataType, .collection(.singleChoice, .string))
        
        if let picker = inputField.pickerSource as? RSDChoiceOptions {
            let choices = picker.choices
            let expectedCount = 3
            if choices.count == expectedCount {
                XCTAssertEqual(choices[0].text, "Yes, I have done this")
                XCTAssertEqual(choices[0].answerValue as? String, "true")
                XCTAssertEqual(choices[1].text, "No, I have never done this")
                XCTAssertEqual(choices[1].answerValue as? String, "false")
                XCTAssertEqual(choices[2].text, "Maybe")
                XCTAssertEqual(choices[2].answerValue as? String, "maybe")
            } else {
                XCTAssertEqual(choices.count, expectedCount, "\(choices)")
            }
        } else {
            XCTFail("Picker not expected type: \(String(describing: inputField.pickerSource))")
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

        let inputField = inputStep
        XCTAssertEqual(inputField.dataType, .collection(.singleChoice, .decimal))
        
        if let picker = inputField.pickerSource as? RSDChoiceOptions {
            let choices = picker.choices
            let expectedCount = 3
            if choices.count == expectedCount {
                XCTAssertEqual(choices[0].text, "Yes, I have done this")
                XCTAssertEqual(choices[0].answerValue as? Double, 0)
                XCTAssertEqual(choices[1].text, "No, I have never done this")
                XCTAssertEqual(choices[1].answerValue as? Double, 1)
                XCTAssertEqual(choices[2].text, "Maybe")
                XCTAssertEqual(choices[2].answerValue as? Double, 2)
            } else {
                XCTAssertEqual(choices.count, expectedCount, "\(choices)")
            }
        } else {
            XCTFail("Picker not expected type: \(String(describing: inputField.pickerSource))")
        }
    }
    
    func testStep_MultiValueConstraints_Multiple_NoRules() {
        
        let inputStep = createMultipleChoiceQuestion(allowMultiple: true)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .collection(.multipleChoice, .string))
        XCTAssertEqual(inputField.inputUIHint, .list)

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
        
        return createQuestion(allowMultiple ? .list : .radioButton, constraints)
    }
  
    // MARK: StringConstraints

    func testStep_TextAnswer_NoRules() {

        let inputStep = createQuestion(.textfield, SBBStringConstraints())

        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .base(.string))
        XCTAssertEqual(inputField.inputUIHint, .textfield)
    }
    

    func testStep_TextAnswer_ValidationRegEx() {

        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.pattern = "^[0-9A-F]+$"
        constraints.patternErrorMessage = "Should be hexidecimal"
        
        let inputStep = createQuestion(.textfield, constraints)
        XCTAssertNotNil(inputStep.textFieldOptions)
        guard let textOptions = inputStep.textFieldOptions else {
            XCTFail("Expected non-nil value")
            return
        }
        
        XCTAssertEqual(textOptions.invalidMessage, "Should be hexidecimal")
        XCTAssertNotNil(textOptions.textValidator)
        if let validator = textOptions.textValidator as? RSDCodableRegExMatchValidator {
            XCTAssertEqual(validator.regExPattern, "^[0-9A-F]+$")
        } else {
            XCTFail("Validator not expected type: \(String(describing: textOptions.textValidator))")
        }
    }

    func testStep_TextAnswer_MinAndMaxLength() {

        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.minLength = NSNumber(value: 4)
        constraints.maxLength = NSNumber(value: 8)
        
        let inputStep = createQuestion(.textfield, constraints)
        XCTAssertNotNil(inputStep.textFieldOptions)
        guard let textOptions = inputStep.textFieldOptions else {
            XCTFail("Expected non-nil value")
            return
        }
        
        XCTAssertEqual(textOptions.maximumLength, 8)
        XCTAssertNotNil(textOptions.textValidator)
        if let validator = textOptions.textValidator as? RSDCodableRegExMatchValidator {
            XCTAssertEqual(validator.regExPattern, "^.{4,}$")
        } else {
            XCTFail("Validator not expected type: \(String(describing: textOptions.textValidator))")
        }
    }

    func testStep_TextAnswer_MinLengthOnly() {

        // pattern, maxLength and minLength are currently unsupported
        let constraints = SBBStringConstraints()
        constraints.minLength = NSNumber(value: 4)

        let inputStep = createQuestion(.textfield, constraints)
        XCTAssertNotNil(inputStep.textFieldOptions)
        guard let textOptions = inputStep.textFieldOptions else {
            XCTFail("Expected non-nil value")
            return
        }
        
        XCTAssertNotNil(textOptions.textValidator)
        if let validator = textOptions.textValidator as? RSDCodableRegExMatchValidator {
            XCTAssertEqual(validator.regExPattern, "^.{4,}$")
        } else {
            XCTFail("Validator not expected type: \(String(describing: textOptions.textValidator))")
        }
    }

    // MARK: DateTimeConstraints
    
    func testStep_DateTimeConstraints_NoRules() {
        
        let constraints = SBBDateTimeConstraints()
        constraints.allowFutureValue = false
        
        let inputStep = createQuestion(.dateTimePicker, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .base(.date))
        XCTAssertEqual(inputField.inputUIHint, .picker)
        
        if let dateRange = inputField.range as? RSDDateRange {
            XCTAssertEqual(dateRange.shouldAllowFuture, false)
            XCTAssertNil(dateRange.minDate)
            XCTAssertNil(dateRange.maxDate)
            XCTAssertEqual(dateRange.dateCoder as? RSDDateCoderObject, .timestamp)
        } else {
            XCTFail("Range not expected type: \(String(describing: inputField.range))")
        }
    }
    
    func testStep_DateTimeConstraints_MinMaxDate() {
        
        let constraints = SBBDateTimeConstraints()
        let minDate = Date().addingTimeInterval(-5 * 24 * 3600)
        let maxDate = Date().addingTimeInterval(5 * 24 * 3600)
        constraints.earliestValue = minDate
        constraints.latestValue = maxDate
        
        let inputStep = createQuestion(.dateTimePicker, constraints)
        let inputField = inputStep
        
        if let dateRange = inputField.range as? RSDDateRange {
            XCTAssertNil(dateRange.shouldAllowFuture)
            XCTAssertEqual(dateRange.minDate, minDate)
            XCTAssertEqual(dateRange.maxDate, maxDate)
            XCTAssertEqual(dateRange.dateCoder as? RSDDateCoderObject, .timestamp)
        } else {
            XCTFail("Range not expected type: \(String(describing: inputField.range))")
        }
    }

    
    // MARK: SBBDateConstraints
    
    func testStep_DateConstraints_NoRules() {
        
        let constraints = SBBDateConstraints()
        constraints.allowFutureValue = false
        
        let inputStep = createQuestion(.datePicker, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .base(.date))
        XCTAssertEqual(inputField.inputUIHint, .picker)

        if let dateRange = inputField.range as? RSDDateRange {
            XCTAssertEqual(dateRange.shouldAllowFuture, false)
            XCTAssertNil(dateRange.minDate)
            XCTAssertNil(dateRange.maxDate)
            XCTAssertEqual(dateRange.dateCoder as? RSDDateCoderObject, .dateOnly)
        } else {
            XCTFail("Range not expected type: \(String(describing: inputField.range))")
        }
    }
    
    func testStep_DateConstraints_MinMaxDate() {
        
        let constraints = SBBDateConstraints()
        let minDate = Date().addingTimeInterval(-5 * 24 * 3600)
        let maxDate = Date().addingTimeInterval(5 * 24 * 3600)
        constraints.earliestValue = minDate
        constraints.latestValue = maxDate
        
        let inputStep = createQuestion(.datePicker, constraints)
        let inputField = inputStep
        
        if let dateRange = inputField.range as? RSDDateRange {
            XCTAssertNil(dateRange.shouldAllowFuture)
            XCTAssertEqual(dateRange.minDate, minDate)
            XCTAssertEqual(dateRange.maxDate, maxDate)
            XCTAssertEqual(dateRange.dateCoder as? RSDDateCoderObject, .dateOnly)
        } else {
            XCTFail("Range not expected type: \(String(describing: inputField.range))")
        }
    }

    
    // MARK: TimeConstraints
    
    func testStep_TimeConstraints_NoRules() {
        
        let inputStep = createQuestion(.timePicker, SBBTimeConstraints())
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .base(.date))
        XCTAssertEqual(inputField.inputUIHint, .picker)
        
        if let dateRange = inputField.range as? RSDDateRange {
            XCTAssertNil(dateRange.shouldAllowFuture)
            XCTAssertNil(dateRange.minDate)
            XCTAssertNil(dateRange.maxDate)
            XCTAssertEqual(dateRange.dateCoder as? RSDDateCoderObject, .timeOfDay)
        } else {
            XCTFail("Range not expected type: \(String(describing: inputField.range))")
        }
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
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .base(.integer))
        XCTAssertEqual(inputField.inputUIHint, .textfield)
        
        if let range = inputField.range as? RSDNumberRange {
            XCTAssertEqual(range.minimumValue, -3)
            XCTAssertEqual(range.maximumValue, 5)
            XCTAssertEqual(range.stepInterval, 2)
            XCTAssertEqual(range.unit, "pie")
        } else {
            XCTFail("Range not expected type: \(String(describing: inputField.range))")
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
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .base(.decimal))
        XCTAssertEqual(inputField.inputUIHint, .textfield)
        
        if let range = inputField.range as? RSDNumberRange {
            XCTAssertEqual(range.minimumValue, -3.5)
            XCTAssertEqual(range.maximumValue, 5.5)
            XCTAssertEqual(range.stepInterval, 0.5)
            XCTAssertEqual(range.unit, "pie")
        } else {
            XCTFail("Range not expected type: \(String(describing: inputField.range))")
        }
    }
    
 
    // MARK: SBBHeightConstraints
    
    func testStep_HeightConstraints_Infant() {
        
        let constraints = SBBHeightConstraints()
        constraints.unit = "in"
        constraints.isInfantValue = true
        
        let inputStep = createQuestion(.height, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .measurement(.height, .infant))
        XCTAssertNil(inputField.inputUIHint)
        
        if let range = inputField.range as? RSDNumberRange {
            XCTAssertNil(range.minimumValue)
            XCTAssertNil(range.maximumValue)
            XCTAssertNil(range.stepInterval)
            XCTAssertEqual(range.unit, "in")
        } else {
            XCTFail("Range not expected type: \(String(describing: inputField.range))")
        }
    }
    
    func testStep_HeightConstraints_Adult() {
        let constraints = SBBHeightConstraints()
        let inputStep = createQuestion(.height, constraints)
        let inputField = inputStep
        XCTAssertEqual(inputField.dataType, .measurement(.height, .adult))
    }
    
    
    // MARK: SBBWeightConstraints
    
    func testStep_WeightConstraints_Infant() {
        
        let constraints = SBBWeightConstraints()
        constraints.unit = "lb"
        constraints.isInfantValue = true
        
        let inputStep = createQuestion(.weight, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .measurement(.weight, .infant))
        XCTAssertNil(inputField.inputUIHint)
        
        if let range = inputField.range as? RSDNumberRange {
            XCTAssertNil(range.minimumValue)
            XCTAssertNil(range.maximumValue)
            XCTAssertNil(range.stepInterval)
            XCTAssertEqual(range.unit, "lb")
        } else {
            XCTFail("Range not expected type: \(String(describing: inputField.range))")
        }
    }
    
    func testStep_WeightConstraints_Adult() {
        let constraints = SBBWeightConstraints()
        let inputStep = createQuestion(.weight, constraints)
        let inputField = inputStep
        XCTAssertEqual(inputField.dataType, .measurement(.weight, .adult))
    }
    
    // MARK: SBBBloodPressureConstraints
    
    func testStep_BloodPressureConstraints_Infant() {
        
        let constraints = SBBBloodPressureConstraints()
        let inputStep = createQuestion(.bloodPressure, constraints)
        
        let surveyStep = inputStep
        XCTAssertEqual(surveyStep.identifier, "abc123")
        XCTAssertNil(surveyStep.title)
        XCTAssertEqual(surveyStep.text, "Question prompt")
        XCTAssertEqual(surveyStep.detail, "Question prompt detail")
        
        let inputField = inputStep
        XCTAssertNil(inputField.inputPrompt)
        XCTAssertNil(inputField.placeholder)
        XCTAssertTrue(inputField.isOptional)
        XCTAssertEqual(inputField.dataType, .measurement(.bloodPressure, .adult))
        XCTAssertNil(inputField.inputUIHint)
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
    
    override func isOptional(for inputField: RSDInputField) -> Bool {
        return false
    }
    
    override func viewTheme(for surveyElement: SBBSurveyElement) -> RSDViewThemeElement? {
        return RSDViewThemeElementObject(viewIdentifier: "foo")
    }
    
    override func colorMapping(for surveyElement: SBBSurveyElement) -> RSDColorMappingThemeElement? {
        return RSDColorMappingThemeElementObject(colorStyle: .accent, colorMapping: nil)
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
