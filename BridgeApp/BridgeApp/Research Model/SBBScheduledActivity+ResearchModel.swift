//
//  SBBScheduledActivity+ResearchModel.swift
//  BridgeApp (iOS)
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

extension SBBScheduledActivity {
    
    /// Get the schema info associated with this scheduled activity.
    public var schemaInfo : RSDSchemaInfo? {
        guard let activityIdentifier = self.activityIdentifier else {
            return nil
        }
        return SBABridgeConfiguration.shared.schemaInfo(for: activityIdentifier)
    }
    
    /// Instantiate a new instance of a task path for this schedule.
    public func instantiateTaskPath() -> RSDTaskPath {
        if let task = self.activity.activityReference as? RSDTask {
            return RSDTaskPath(task: task)
        }
        else if let taskInfoStep = self.taskInfoStep() {
            return RSDTaskPath(taskInfo: taskInfoStep)
        }
        else {
            assertionFailure("Missing activity reference: \(self)")
            return RSDTaskPath.emptyPath()
        }
    }
    
    /// Get or instantiate a task info step for this schedule.
    public func taskInfoStep() -> RSDTaskInfoStep? {
        if let taskInfoStep = self.activity.activityReference as? RSDTaskInfoStep {
            return taskInfoStep
        }
        else if let transformer = self.activity.activityReference as? RSDTaskTransformer {
            return RSDTaskInfoStepObject(with: self.activity.activityReference!, taskTransformer: transformer)
        }
        else {
            assertionFailure("Missing activity reference: \(self)")
            return nil
        }
    }
}

extension RSDTaskPath {
    
    /// Create an empty task path.
    static func emptyPath() -> RSDTaskPath {
        return RSDTaskPath(task: RSDTaskObject(identifier: "NULL", stepNavigator: RSDConditionalStepNavigatorObject(with: [])))
    }
}
