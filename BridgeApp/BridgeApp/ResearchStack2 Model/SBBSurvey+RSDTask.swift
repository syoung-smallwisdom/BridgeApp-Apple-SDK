//
//  SBBSurvey+RSDTask.swift
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

open class SBASurveyLoader: RSDTaskTransformer {
    
    /// The pointer to the survey reference.
    public let surveyReference: SBBSurveyReference
    
    /// Estimate that fetching the survey will take about 5 seconds.
    public var estimatedFetchTime: TimeInterval {
        return 5
    }
    
    public init(surveyReference: SBBSurveyReference) {
        self.surveyReference = surveyReference
    }
    
    private var urlSessionTask: URLSessionTask?
    
    public func fetchTask(with factory: RSDFactory, taskIdentifier: String, schemaInfo: RSDSchemaInfo?, callback: @escaping RSDTaskFetchCompletionHandler) {
        self.urlSessionTask = SBBSurveyManager.default().getSurveyByRef(surveyReference.href) { [weak self] (response, error) in
            self?.urlSessionTask = nil
            let survey = self?.instantiateSurveyWrapper(for: response as? SBBSurvey)
            DispatchQueue.main.async {
                callback(taskIdentifier, survey, error)
            }
        }
    }
    
    /// Instantiate an appropriate wrapper for the survey.
    open func instantiateSurveyWrapper(for survey: SBBSurvey?) -> SBASurveyWrapper? {
        guard survey != nil else { return nil }
        SBASurveyConfiguration.shared.registerSurvey(survey!)
        return SBASurveyWrapper(survey: survey!)
    }
}

/// `SBASurveyWrapper` is a wrapper for the survey that can allow customization of
/// the returned results.
open class SBASurveyWrapper : RSDTask {

    public let survey : SBBSurvey
    
    public init(survey : SBBSurvey) {
        self.survey = survey
    }
    
    public var identifier: String {
        return self.survey.identifier
    }
    
    public var schemaInfo: RSDSchemaInfo? {
        return self.survey
    }
    
    public var copyright: String? {
        return self.survey.copyrightNotice
    }
    
    open var stepNavigator: RSDStepNavigator {
        return self.survey
    }
    
    open var asyncActions: [RSDAsyncActionConfiguration]?
    
    open func instantiateTaskResult() -> RSDTaskResult {
        return RSDTaskResultObject(identifier: self.identifier, schemaInfo: self.survey)
    }
    
    open func validate() throws {
        try survey.validate()
    }
    
    open func action(for actionType: RSDUIActionType, on step: RSDStep) -> RSDUIAction? {
        return survey.action(for: actionType, on: step)
    }
    
    open func shouldHideAction(for actionType: RSDUIActionType, on step: RSDStep) -> Bool? {
        return survey.shouldHideAction(for: actionType, on: step)
    }
}

extension SBBSurvey {
    
    public var surveyElements: [SBBSurveyElement] {
        return self.elements as? [SBBSurveyElement] ?? []
    }
}

extension SBBSurvey : RSDSchemaInfo {
    
    public var schemaIdentifier: String? {
        return self.identifier
    }
    
    public var schemaVersion: Int {
        return self.schemaRevision?.intValue ?? 1
    }
}

extension SBBSurvey : RSDConditionalStepNavigator {
    
    public var steps: [RSDStep] {
        return self.surveyElements
    }
    
    public var conditionalRule: RSDConditionalRule? {
        return SBASurveyConfiguration.shared.conditionalRule(for: self)
    }
    
    public var progressMarkers: [String]? {
        return SBASurveyConfiguration.shared.progressMarkers(for: self)
    }
}
