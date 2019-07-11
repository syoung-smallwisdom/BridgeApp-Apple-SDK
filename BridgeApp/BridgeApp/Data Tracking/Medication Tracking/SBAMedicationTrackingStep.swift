//
//  SBAMedicationTrackingStep.swift
//  BridgeApp (iOS)
//
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
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

public struct SBAMedicationTrackingStep : RSDSubtaskStep {
    public let stepType: RSDStepType = .medicationTracking
    public let task: RSDTask
    
    public init(mainTask: RSDTask) throws {
        self.task = try SBAMedicationLoggingTask(mainTask: mainTask)
    }
}

struct SBAMedicationLoggingTask : RSDTask, RSDStepNavigator, RSDTrackingTask {

    init(mainTask: RSDTask) throws {
        guard let navigator = mainTask.stepNavigator as? SBAMedicationTrackingStepNavigator,
            let loggingStep = navigator.loggingStep as? SBAMedicationLoggingStepObject
            else {
                throw RSDValidationError.invalidType("The navigator for the main task is not of the expected type.")
        }
        self.identifier = mainTask.identifier
        self.schemaInfo = mainTask.schemaInfo
        self.loggingStep = loggingStep
        self.loggingStep.shouldIncludeAll = false
    }
    
    public let loggingStep: SBAMedicationLoggingStepObject
    
    
    // MARK: `RSDTask`
    
    public let identifier: String
    public let schemaInfo: RSDSchemaInfo?
    
    public var stepNavigator: RSDStepNavigator {
        return self
    }
    
    public func instantiateTaskResult() -> RSDTaskResult {
        return RSDTaskResultObject(identifier: self.identifier)
    }
    
    public var copyright: String? {
        return nil
    }
    
    public var asyncActions: [RSDAsyncActionConfiguration]? { return nil }
    
    public func validate() throws {
    }
    
    
    // MARK: RSDStepNavigator
    
    func step(with identifier: String) -> RSDStep? {
        guard identifier == loggingStep.identifier else { return nil }
        return loggingStep
    }
    
    /// Never exit after answering meds.
    func shouldExit(after step: RSDStep?, with result: RSDTaskResult) -> Bool {
        return false
    }
    
    func hasStep(after step: RSDStep?, with result: RSDTaskResult) -> Bool {
        return _step(after: step) != nil
    }
    
    /// Only one step.
    func hasStep(before step: RSDStep, with result: RSDTaskResult) -> Bool {
        return false
    }
    
    /// Return the logging step.
    func step(after step: RSDStep?, with result: inout RSDTaskResult) -> (step: RSDStep?, direction: RSDStepDirection) {
        return (_step(after: step), .forward)
    }
    
    func _step(after step: RSDStep?) -> RSDStep? {
        guard step == nil,
            loggingStep.medicationTimings().count > 0
            else {
                return nil
        }
        return loggingStep
    }
    
    /// Only one step.
    func step(before step: RSDStep, with result: inout RSDTaskResult) -> RSDStep? {
        return nil
    }
    
    /// Progress is not used.
    func progress(for step: RSDStep, with result: RSDTaskResult?) -> (current: Int, total: Int, isEstimated: Bool)? {
        return nil
    }
    
    
    // MARK: `RSDTrackingTask`
    
    /// Build the task data for this task.
    func taskData(for taskResult: RSDTaskResult) -> RSDTaskData? {
        guard let loggingResult = taskResult.findResult(for: self.loggingStep) as? SBAMedicationTrackingResult
            else {
                return nil
        }
        do {
            guard let dataScore = try loggingResult.dataScore() else {
                return nil
            }
            return SBAReport(identifier: taskResult.identifier, date: taskResult.endDate, json: dataScore)
        }
        catch let err {
            assertionFailure("Failed to get data score from the logging result: \(err)")
            return nil
        }
    }
    
    /// Set up the previous client data.
    func setupTask(with data: RSDTaskData?, for path: RSDTaskPathComponent) {
        var medsResult = SBAMedicationTrackingResult(identifier: loggingStep.identifier)
        if let previousClientData = data?.json.toClientData() {
            try? medsResult.updateSelected(from: previousClientData, with: self.loggingStep.items)
        }
        self.loggingStep.result = medsResult
    }
    
    /// Not used. Always return `false`.
    func shouldSkipStep(_ step: RSDStep) -> (shouldSkip: Bool, stepResult: RSDResult?) {
        return (false, nil)
    }
}
