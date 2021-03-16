//
//  SurveyNavigationRuleTests.swift
//  BridgeAppTests
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
import JsonModel
import Research
@testable import BridgeApp

class SurveyNavigationRuleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNavigation_SBBSurveyInfoScreen_EndSurvey() {
        let rule = SBBSurveyRule()
        rule.endSurveyValue = true
        rule.operator = SBBOperatorType.always.stringValue
        
        let inputStep = SBBSurveyInfoScreen()
        inputStep.identifier = "abc123"
        inputStep.add(afterRulesObject: rule)
        let surveyStep = inputStep
        
        let nextStepIdentifier = surveyStep.nextStepIdentifier(with: nil, isPeeking: false)
        XCTAssertEqual(nextStepIdentifier, "nextSection")
    }
    
    // MARK: BooleanConstraints

    func testNavigation_BooleanConstraints() {
        
        let constraints = SBBBooleanConstraints()
        let inputStep = createQuestion(.checkbox, constraints)
        let surveyStep = inputStep
        
        let ruleYes = SBBSurveyRule()
        ruleYes.operator = SBBOperatorType.equal.stringValue
        ruleYes.value = NSNumber(value: true)
        ruleYes.skipTo = "keepGoing"
        constraints.addRulesObject(ruleYes)
        
        let ruleNo = SBBSurveyRule()
        ruleNo.operator = SBBOperatorType.equal.stringValue
        ruleNo.value = NSNumber(value: false)
        ruleNo.endSurveyValue = true
        constraints.addRulesObject(ruleNo)
        
        let answerResult = inputStep.instantiateAnswerResult()
        var taskResult = RSDTaskResultObject(identifier: "test")
        taskResult.appendStepHistory(with: answerResult)
        
        // Set the answer to "yes"
        answerResult.jsonValue = .boolean(true)
        
        let identifierYes = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertEqual(identifierYes, "keepGoing")
        
        // Set the answer to "no"
        answerResult.jsonValue = .boolean(false)
        
        let identifierNo = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertEqual(identifierNo, "nextSection")
        
        // Set the answer to "skip"
        answerResult.jsonValue = nil
        
        let identifierSkip = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertNil(identifierSkip)
        
        // Now, add a skip rule
        let ruleSkip = SBBSurveyRule()
        ruleSkip.operator = SBBOperatorType.skip.stringValue
        ruleSkip.skipTo = "skipToMaLoo"
        constraints.addRulesObject(ruleSkip)
        
        let identifierSkipWithRule = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertEqual(identifierSkipWithRule, "skipToMaLoo")
    }

    // MARK: MultiValueConstraints

    func testNavigation_MultiValueConstraints() {

        let inputStep = createMultipleChoiceQuestion(allowMultiple: false)
        let constraints = inputStep.constraints
        let surveyStep = inputStep
        
        let ruleYes = SBBSurveyRule()
        ruleYes.operator = SBBOperatorType.equal.stringValue
        ruleYes.value = "true"
        ruleYes.skipTo = "keepGoing"
        constraints.addRulesObject(ruleYes)
        
        let ruleNo = SBBSurveyRule()
        ruleNo.operator = SBBOperatorType.equal.stringValue
        ruleNo.value = "false"
        ruleNo.endSurveyValue = true
        constraints.addRulesObject(ruleNo)
        
        let answerResult = AnswerResultObject(identifier: inputStep.identifier, answerType: AnswerTypeString())
        var taskResult = RSDTaskResultObject(identifier: "test")
        taskResult.appendStepHistory(with: answerResult)
        
        // Set the answer to "yes"
        answerResult.jsonValue = .string("true")
        
        
        let identifierYes = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertEqual(identifierYes, "keepGoing")
        
        // Set the answer to "no"
        answerResult.jsonValue = .string("false")
        
        let identifierNo = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertEqual(identifierNo, "nextSection")
        
        // Set the answer to "maybe"
        answerResult.jsonValue = .string("maybe")
        
        let identifierMaybe = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertNil(identifierMaybe)
        
        // Set the answer to "skip"
        answerResult.jsonValue = nil
        
        let identifierSkip = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertNil(identifierSkip)
        
        // Now, add a skip rule
        let ruleSkip = SBBSurveyRule()
        ruleSkip.operator = SBBOperatorType.skip.stringValue
        ruleSkip.skipTo = "skipToMaLoo"
        constraints.addRulesObject(ruleSkip)
        
        let identifierSkipWithRule = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertEqual(identifierSkipWithRule, "skipToMaLoo")
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

    // MARK: IntegerConstraints

    func testNavigation_IntegerConstraints_Equal() {

        let constraints = SBBIntegerConstraints()
        let inputStep = createQuestion(.numberfield, constraints)

        let surveyStep = inputStep
        
        let rule = SBBSurveyRule()
        rule.operator = SBBOperatorType.equal.stringValue
        rule.skipTo = "correct"
        rule.value = NSNumber(value: 1)
        constraints.addRulesObject(rule)
        
        let answerResult = AnswerResultObject(identifier: inputStep.identifier, answerType: AnswerTypeInteger())
        var taskResult = RSDTaskResultObject(identifier: "test")
        taskResult.appendStepHistory(with: answerResult)
        
        // Set the answer to invalid
        answerResult.jsonValue = .integer(0)
        let identifier1 = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertNil(identifier1)
        
        // Set the answer to valid
        answerResult.jsonValue = .integer(1)
        let identifier2 = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertEqual(identifier2, "correct")
    }
    
    func testNavigation_IntegerConstraints_NotEqual() {
        
        let constraints = SBBIntegerConstraints()
        let inputStep = createQuestion(.numberfield, constraints)
        
        let surveyStep = inputStep
        
        let rule = SBBSurveyRule()
        rule.operator = SBBOperatorType.notEqual.stringValue
        rule.skipTo = "correct"
        rule.value = NSNumber(value: 1)
        constraints.addRulesObject(rule)
        
        let answerResult = AnswerResultObject(identifier: inputStep.identifier, answerType: AnswerTypeInteger())
        var taskResult = RSDTaskResultObject(identifier: "test")
        taskResult.appendStepHistory(with: answerResult)
        
        // Set the answer to invalid
        answerResult.jsonValue = .integer(1)
        
        let identifier1 = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertNil(identifier1)
        
        // Set the answer to valid
        answerResult.jsonValue = .integer(0)
        
        let identifier2 = surveyStep.nextStepIdentifier(with: taskResult, isPeeking: false)
        XCTAssertEqual(identifier2, "correct")
    }
    
    func testCohortRules() {
        let constraints = SBBIntegerConstraints()
        let inputStep = createQuestion(.numberfield, constraints)
        
        let beforeRule = SBBSurveyRule()
        beforeRule.operator = SBBOperatorType.all.stringValue
        beforeRule.skipTo = "alpha"
        beforeRule.dataGroups = ["a"]
        
        let rule = SBBSurveyRule()
        rule.operator = SBBOperatorType.notEqual.stringValue
        rule.skipTo = "correct"
        rule.value = NSNumber(value: 1)
        
        let afterRule = SBBSurveyRule()
        afterRule.operator = SBBOperatorType.any.stringValue
        afterRule.skipTo = "beta"
        afterRule.dataGroups = ["b", "c"]
        
        inputStep.add(beforeRulesObject: beforeRule)
        inputStep.add(afterRulesObject: rule)
        inputStep.add(afterRulesObject: afterRule)
        
        if let firstRule = inputStep.beforeCohortRules?.first, let lastRule = inputStep.beforeCohortRules?.last {
            XCTAssertEqual(firstRule.requiredCohorts, lastRule.requiredCohorts, "Expecting only one rule")
            XCTAssertEqual(firstRule.requiredCohorts, ["a"])
        } else {
            XCTFail("Expected non-nil cohort rules")
        }
        
        if let firstRule = inputStep.afterCohortRules?.first, let lastRule = inputStep.afterCohortRules?.last {
            XCTAssertEqual(firstRule.requiredCohorts, lastRule.requiredCohorts, "Expecting only one rule")
            XCTAssertEqual(firstRule.requiredCohorts, ["b", "c"])
        } else {
            XCTFail("Expected non-nil cohort rules")
        }
    }
    
    func testOperators() {
        
        // Rule operator
        
        XCTAssertNil(SBBOperatorType.all.ruleOperator)
        XCTAssertNil(SBBOperatorType.any.ruleOperator)
        
        XCTAssertEqual(SBBOperatorType.equal.ruleOperator, .equal)
        XCTAssertEqual(SBBOperatorType.notEqual.ruleOperator, .notEqual)
        XCTAssertEqual(SBBOperatorType.lessThan.ruleOperator, .lessThan)
        XCTAssertEqual(SBBOperatorType.lessThanEqual.ruleOperator, .lessThanEqual)
        XCTAssertEqual(SBBOperatorType.greaterThan.ruleOperator, .greaterThan)
        XCTAssertEqual(SBBOperatorType.greaterThanEqual.ruleOperator, .greaterThanEqual)
        XCTAssertEqual(SBBOperatorType.skip.ruleOperator, .skip)
        XCTAssertEqual(SBBOperatorType.always.ruleOperator, .always)
        
        // Cohort operator
        
        XCTAssertEqual(SBBOperatorType.all.cohortOperator, .all)
        XCTAssertEqual(SBBOperatorType.any.cohortOperator, .any)
        
        XCTAssertNil(SBBOperatorType.always.cohortOperator)
        XCTAssertNil(SBBOperatorType.equal.cohortOperator)
        XCTAssertNil(SBBOperatorType.notEqual.cohortOperator)
        XCTAssertNil(SBBOperatorType.lessThan.cohortOperator)
        XCTAssertNil(SBBOperatorType.lessThanEqual.cohortOperator)
        XCTAssertNil(SBBOperatorType.greaterThan.cohortOperator)
        XCTAssertNil(SBBOperatorType.greaterThanEqual.cohortOperator)
        XCTAssertNil(SBBOperatorType.skip.cohortOperator)
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
