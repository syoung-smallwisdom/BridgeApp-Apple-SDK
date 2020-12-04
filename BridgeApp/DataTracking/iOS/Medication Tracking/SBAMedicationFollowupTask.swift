//
//  SBAMedicationFollowupTask.swift
//  DataTracking (iOS)
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
import Research

/// A wrapper for displaying a single step of the medication tracking.
protocol SBAMedicationFollowupTask : RSDTask, RSDStepNavigator, RSDTrackingTask {
    
    /// The single step to display.
    var trackingStep: RSDStep { get }
    
    /// The medication tracker that holds the pointer to the result.
    var medicationTracker: SBAMedicationTrackingStepNavigator { get }
    
    /// Set up the follow up task. Called in `setupTask()` after setting up the medication
    /// tracker.
    func setupFollowupTask()
}

extension SBAMedicationFollowupTask {
    
    // MARK: `RSDTask`
    
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
    
    public func step(with identifier: String) -> RSDStep? {
        guard identifier == trackingStep.identifier else { return nil }
        return trackingStep
    }
    
    /// Never exit after answering meds.
    public func shouldExit(after step: RSDStep?, with result: RSDTaskResult) -> Bool {
        return false
    }
    
    /// Only one step.
    public func hasStep(before step: RSDStep, with result: RSDTaskResult) -> Bool {
        return false
    }
    
    /// Return the logging step.
    public func step(after step: RSDStep?, with result: inout RSDTaskResult) -> (step: RSDStep?, direction: RSDStepDirection) {

        // Update the tracker
        medicationTracker.updateInMemoryResult(from: &result, using: step)

        // Check if there is a step after the input step. That value is *always* the tracking
        // step (if anything should be shown).
        guard self.hasStep(after: step, with: result) else {
            return (nil, .forward)
        }
        return (self.trackingStep, .forward)
    }

    /// Only one step.
    public func step(before step: RSDStep, with result: inout RSDTaskResult) -> RSDStep? {
        return nil
    }
    
    /// Progress is not used.
    public func progress(for step: RSDStep, with result: RSDTaskResult?) -> (current: Int, total: Int, isEstimated: Bool)? {
        return nil
    }
    
    
    // MARK: `RSDTrackingTask`
    
    /// Build the task data for this task.
    public func taskData(for taskResult: RSDTaskResult) -> RSDTaskData? {
        return self.medicationTracker.taskData(for: taskResult)
    }
    
    /// Set up the previous client data.
    public func setupTask(with data: RSDTaskData?, for path: RSDTaskPathComponent) {
        self.medicationTracker.setupTask(with: data, for: path)
        setupFollowupTask()
    }
    
    /// Not used. Always return `false`.
    public func shouldSkipStep(_ step: RSDStep) -> (shouldSkip: Bool, stepResult: RSDResult?) {
        return (false, nil)
    }
}
