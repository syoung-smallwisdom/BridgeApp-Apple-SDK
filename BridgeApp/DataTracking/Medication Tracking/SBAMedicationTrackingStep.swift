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

/// The medication tracking step is a step that can be displayed prior to an active task to query
/// the user about whether or not they have taken their medications that were scheduled for some
/// point prior to "now" but have not been marked as taken.
///
/// Note: Currently, there is no model for marking a participant's response where they have
/// explicitly said that they have *not* taken the medication.
///
/// This step is run as a subtask for two reasons:
/// 1. Simplifies the upload of changes by using the same model and identifier as the main task.
/// 2. At some point the UI/UX might change to include additional steps and/or structure.
///
public struct SBAMedicationTrackingStep : RSDSubtaskStep {
    public let stepType: RSDStepType = .medicationTracking
    public let task: RSDTask
    
    /// A logging subtask step is built from the main medication tracking task and is used to
    /// *only* show the medications that are currently *not* marked as taken at the time when the
    /// step is displayed.
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
        self.medicationTracker = navigator
        
        // The logging step is a class so make a copy of it.
        let copy = loggingStep.copy(with: RSDIdentifier.trackedItemsResult.stringValue)
        copy.shouldIncludeAll = false
        self.loggingStep = copy
    }
    
    // MARK: `RSDTask`
    
    public let identifier: String
    public let schemaInfo: RSDSchemaInfo?
    
    // MARK: `SBAMedicationFollowupTask`
    
    let loggingStep: SBAMedicationLoggingStepObject
    let medicationTracker: SBAMedicationTrackingStepNavigator
}

extension SBAMedicationLoggingTask : SBAMedicationFollowupTask {

    /// The tracking step is the reminder step.
    var trackingStep: RSDStep {
        return loggingStep
    }
    
    /// Only one step.
    public func hasStep(after step: RSDStep?, with result: RSDTaskResult) -> Bool {
        return step == nil && loggingStep.medicationTimings().count > 0
    }
    
    /// Hook up the result.
    func setupFollowupTask() {
        self.loggingStep.result = medicationTracker.medicationResult?.copy(with: self.loggingStep.identifier)
    }
}
