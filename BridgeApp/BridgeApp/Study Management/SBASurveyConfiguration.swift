//
//  SBASurveyConfiguration.swift
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

/// `SBASurveyConfiguration` is a survey wrapper that can extend the default implementation
/// of UI/UX handling for all the Bridge surveys used by a given app.
open class SBASurveyConfiguration {
    
    /// The shared singleton.
    public static var shared = SBASurveyConfiguration()
    
    public init() {
    }
    
    /// Allow customization of the step type for a given survey element.
    ///
    /// Default implementation will check the `stepTypeMap` for a guid and return that value if found.
    /// Otherwise it will return `.form` for `SBBSurveyQuestion` classes and return `.instruction` for
    /// all other classes.
    ///
    /// The step type is used within the UI to determine the default view controller to associate with
    /// a given step.
    ///
    /// - parameter step: The survey element to check.
    /// - returns: The appropriate step type for this element.
    open func stepType(for step: SBBSurveyElement) -> RSDStepType {
        if let stepType = stepTypeMap[step.guid] {
            return stepType
        } else if step is SBBSurveyQuestion {
            return .form
        } else {
            return .instruction
        }
    }
    
    /// Allows customization of the result instantiated for a given survey element.
    /// By default, this will return an instance of `RSDResultObject` for an instruction step
    /// and `RSDCollectionResultObject` for a form step.
    open func instantiateStepResult(for step: SBBSurveyElement) -> RSDResult? {
        return step is SBBSurveyInfoScreen ? RSDResultObject(identifier: step.identifier) : RSDCollectionResultObject(identifier: step.identifier)
    }
    
    /// Is the input field optional? Default = `true`.
    open func isOptional(for inputField: RSDInputField) -> Bool {
        return true
    }
    
    /// Default implementation is to use the default view theme.
    open func viewTheme(for surveyElement: SBBSurveyElement) -> RSDViewThemeElement? {
        return nil
    }
    
    // TODO: syoung 03/25/2019 Remove once confirmed that no one is using this.
    @available(*, deprecated)
    open func colorTheme(for surveyElement: SBBSurveyElement) -> RSDColorThemeElement? {
        return nil
    }
    
    /// Default implementation is to use the default color theme.
    open func colorMapping(for surveyElement: SBBSurveyElement) -> RSDColorMappingThemeElement? {
        return nil
    }
    
    /// Returns the progress markers for a given survey. Default = `nil`.
    open func progressMarkers(for survey: SBBSurvey) -> [String]? {
        return survey.surveyElements.map { $0.identifier }
    }
    
    /// The actions for this step. By default, returns `nil`. Can be called by both the survey and the step.
    open func action(for actionType: RSDUIActionType, on step: RSDStep, callingObject: Any? = nil) -> RSDUIAction? {
        return nil
    }
    
    /// The actions for this step. By default, returns `nil`. Can be called by both the survey and the step.
    open func shouldHideAction(for actionType: RSDUIActionType, on step: RSDStep, callingObject: Any? = nil) -> Bool? {
        return nil
    }
    
    // MARK: Survey management
    
    /// Mapping of the step type to the survey element. By default, this is set up when a survey is registered
    /// and includes mapping the last step as a `.completion` step type.
    open var stepTypeMap : [String : RSDStepType] = [:]
    
    /// Register a survey before running it. By default, the only customization is to inspect the last element
    /// and if that element is a `SBBSurveyInfoScreen` subclass, then set its `RSDStepType` in the `stepTypeMap`
    /// to `.completion`.
    ///
    /// - parameter survey: The survey to register.
    open func registerSurvey(_ survey: SBBSurvey) {
        /// add last element to the custom step type map.
        if let lastElement = survey.surveyElements.last, lastElement is SBBSurveyInfoScreen {
            stepTypeMap[lastElement.guid] = .completion
        }
    }
}
