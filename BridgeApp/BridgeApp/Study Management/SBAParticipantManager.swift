//
//  SBAParticipantManager.swift
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

/// The participant manager is used to wrap the study participant to ensure that the participant in
/// memory is up-to-date with what has been sent to the server.
open class SBAParticipantManager : NSObject {
    
    /// A singleton instance of the manager.
    static public var shared = SBAParticipantManager()
    
    /// The study participant.
    public private(set) var studyParticipant: SBBStudyParticipant?
    
    /// The "first" day that the participant performed an activity for the study.
    open var dayOne: Date?
    
    /// The date when the user started the study. By default, this will check the `dayOne` value and use
    /// `today` if that is not set.
    open var startStudy: Date {
        return Calendar.current.startOfDay(for: dayOne ?? studyParticipant?.createdOn ?? Date())
    }
    
    public override init() {
        super.init()
        
        // Add an observer for changes to the study participant.
        self.observer = NotificationCenter.default.addObserver(forName: .sbbUserSessionUpdated, object: nil, queue: .main) { (notification) in
            guard let info = notification.userInfo?[kSBBUserSessionInfoKey] as? SBBUserSessionInfo else {
                self._fetchParticipant()
                return
            }
            self.isFetching = false
            self.studyParticipant = info.studyParticipant
        }
    }
    
    private var observer: AnyObject!
    private var isFetching: Bool = false
    
    /// Fetch the study participant if needed.
    public final func fetchParticipantIfNeeded() {
        guard self.studyParticipant == nil else { return }
        DispatchQueue.main.async {
            self._fetchParticipant()
        }
    }
    
    private func _fetchParticipant() {
        guard !isFetching else { return }
        isFetching = true
        
        BridgeSDK.participantManager.getParticipantRecord { (record, error) in
            guard self.isFetching else { return }
            DispatchQueue.main.async {
                self.isFetching = false
                if let err = error {
                    debugPrint("Failed to get the study participant: \(err)")
                }
                else if let participant = record as? SBBStudyParticipant {
                    self.studyParticipant = participant
                }
            }
        }
    }
}
