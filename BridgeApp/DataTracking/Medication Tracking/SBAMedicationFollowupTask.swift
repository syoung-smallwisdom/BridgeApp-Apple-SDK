//
//  SBAMedicationFollowupTask.swift
//  DataTracking (iOS)
//
//  Created by Shannon Young on 10/16/19.
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
//

import Foundation

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
