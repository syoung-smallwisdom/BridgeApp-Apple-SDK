//
//  SBAMedicationReminderTask.swift
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

public struct SBAMedicationReminderTask : RSDTask {
    
    init(mainTask: RSDTask) throws {
        guard let navigator = mainTask.stepNavigator as? SBAMedicationTrackingStepNavigator,
            let reminderStep = navigator.reminderStep
            else {
                throw RSDValidationError.invalidType("The navigator for the main task is not of the expected type.")
        }
        self.identifier = mainTask.identifier
        self.schemaInfo = mainTask.schemaInfo
        self.reminderStep = reminderStep.copy(with: reminderStep.identifier)
        self.medicationTracker = navigator
    }
    
    /// The reminder step used by this task.
    public let reminderStep: SBATrackedItemRemindersStepObject
    let medicationTracker: SBAMedicationTrackingStepNavigator
    
    // MARK: `RSDTask`
    
    public let identifier: String
    public let schemaInfo: RSDSchemaInfo?
}

extension SBAMedicationReminderTask : SBAMedicationFollowupTask {

    /// The tracking step is the reminder step.
    var trackingStep: RSDStep {
        return reminderStep
    }
    
    /// Only one step.
    public func hasStep(after step: RSDStep?, with result: RSDTaskResult) -> Bool {
        return step == nil
    }
    
    /// Hook up the result.
    func setupFollowupTask() {
        // TODO: syoung 10/16/2019 Hook up the reminder result.
    }
}
