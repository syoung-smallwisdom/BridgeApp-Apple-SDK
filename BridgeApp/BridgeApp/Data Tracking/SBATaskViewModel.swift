//
//  SBATaskViewModel.swift
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

extension RSDTaskPathComponent {
    
    @available(*, deprecated)
    func setupTracking() {
        guard let navigator = self.task?.stepNavigator as? SBATrackedItemsStepNavigator
            else {
                return
        }
        navigator.setupTracking(with: self)
    }
}


/// Subclass of the task view model that can manage view model customization specific to this framework.
@available(*, deprecated)
open class SBATaskViewModel : RSDTaskViewModel {
    
    public weak var reportManager: SBAReportManager? {
        didSet {
            setupTracking()
        }
    }
    
    override open func handleTaskLoaded() {
        setupTracking()
        super.handleTaskLoaded()
    }
    
    public init(task: RSDTask, reportManager: SBAReportManager? = nil) {
        super.init(task: task)
        self.reportManager = reportManager
        setupTracking()
    }
    
    public init(taskInfo: RSDTaskInfo, reportManager: SBAReportManager? = nil) {
        super.init(taskInfo: taskInfo)
        self.reportManager = reportManager
    }
    
    override open func instantiateTaskStepNode(for step: RSDStep) -> RSDNodePathComponent? {
        let node = super.instantiateTaskStepNode(for: step)
        guard let taskNode = node as? RSDTaskStepNode else { return node }
        let trackingNode = SBATaskStepNode(node: taskNode)
        trackingNode.setupTracking()
        return trackingNode
    }
}

/// Subclass of the task node that can manage view model customization specific to this framework.
@available(*, deprecated)
open class SBATaskStepNode : RSDTaskStepNode {
    
    override open func handleTaskLoaded() {
        setupTracking()
        super.handleTaskLoaded()
    }
}

open class SBAModalTaskViewModel : RSDTaskViewModel {
    
    public let parentViewModel: RSDModalStepDataSource
    
    public init(task: RSDTask, parentViewModel: RSDModalStepDataSource) {
        self.parentViewModel = parentViewModel
        super.init(task: task, parentPath: nil)
        self.dataManager = parentViewModel.rootPathComponent.dataManager
    }
}


