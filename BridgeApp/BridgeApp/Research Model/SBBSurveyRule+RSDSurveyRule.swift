//
//  SBBSurveyRule+RSDSurveyRule.swift
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

// TODO: syoung 02/13/2018 Implement rules for data groups.

extension SBBSurveyElement {
    
    /// Look at the `afterRules` set for a navigation rule that always applies.
    public var nextStepIdentifier : String? {
        guard let rule = self.afterRules?.first as? SBBSurveyRule, rule.operatorType == .always
            else {
                return nil
        }
        return rule.skipToIdentifier
    }
}

extension SBBSurveyElement : RSDCohortNavigationStep {
    
    private var _beforeRules: [SBBSurveyRule]? {
        return self.beforeRules as? [SBBSurveyRule]
    }
    
    private var _afterRules: [SBBSurveyRule]? {
        return self.afterRules as? [SBBSurveyRule]
    }
    
    public var beforeCohortRules: [RSDCohortNavigationRule]? {
        return self._beforeRules?.filter { $0.requiredCohorts.count > 0 }
    }
    
    public var afterCohortRules: [RSDCohortNavigationRule]? {
        return self._afterRules?.filter { $0.requiredCohorts.count > 0 }
    }
}

extension SBBSurveyInfoScreen : RSDNavigationRule {
    
    /// Only applicable rule for a survey info screen is direct navigation.
    public func nextStepIdentifier(with result: RSDTaskResult?, conditionalRule: RSDConditionalRule?, isPeeking: Bool) -> String? {
        return self.nextStepIdentifier
    }
}

extension SBBSurveyQuestion : RSDSurveyNavigationStep {
    
    /// Look at the after rules for a skip rule and return the `skipToIdentifier` for that rule.
    public var skipToIfNil: String? {
        guard let rule = (self.afterRules as? [SBBSurveyRule])?.filter({ $0.operatorType == .skip }).first
            else {
                return nil
        }
        return rule.skipToIdentifier
    }
    
    /// Look for a `nextStepIdentifier` and if nil, evaluate the remaining survey rules
    public func nextStepIdentifier(with result: RSDTaskResult?, conditionalRule: RSDConditionalRule?, isPeeking: Bool) -> String? {
        return self.nextStepIdentifier ?? self.evaluateSurveyRules(with: result, isPeeking: isPeeking)
    }
}

extension SBBSurveyQuestion : RSDCohortAssignmentStep {
    
    public func cohortsToApply(with result: RSDTaskResult) -> (add: Set<String>, remove: Set<String>)? {
        return self.evaluateCohortsToApply(with: result)
    }
}

extension sbb_InputField {
    
    /// Only return the rules that are valid comparable rules
    public var surveyRules: [RSDSurveyRule]? {
        guard let rules = self.constraints.rules as? [SBBSurveyRule] else { return nil }
        return rules.filter { $0.isValidComparableRule }
    }
}

extension SBBSurveyRule : RSDComparableSurveyRule {

    /// Is this rule a navigation rule
    var isValidComparableRule : Bool {
        return self.ruleOperator != nil
    }
    
    public var skipToIdentifier: String? {
        return self.endSurveyValue ? RSDIdentifier.exit.stringValue : self.skipTo
    }
    
    public var ruleOperator: RSDSurveyRuleOperator? {
        return self.operatorType.ruleOperator
    }
    
    public var matchingAnswer: Any? {
        return self.value
    }
    
    public var cohort: String? {
        return self.assignDataGroup
    }
}

extension SBBSurveyRule : RSDCohortNavigationRule {
    
    public var requiredCohorts: Set<String> {
        return self.dataGroups ?? []
    }
    
    public var cohortOperator: RSDCohortRuleOperator? {
        return self.operatorType.cohortOperator
    }
}

extension SBBOperatorType {
    
    public var ruleOperator: RSDSurveyRuleOperator? {
        return RSDSurveyRuleOperator(rawValue: self.rawValue)
    }
    
    public var cohortOperator: RSDCohortRuleOperator? {
        return RSDCohortRuleOperator(rawValue: self.rawValue)
    }
}
