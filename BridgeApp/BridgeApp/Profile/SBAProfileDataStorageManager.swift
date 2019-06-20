//
//  SBAProfileDataStorageManager.swift
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

open class SBAProfileDataStorageManager: NSObject, RSDDataStorageManager {
    
    struct TaskData : RSDTaskData {
        let identifier: String
        let timestampDate: Date?
        let json: RSDJSONSerializable
        
        public init(identifier: String, timestampDate: Date?, json: RSDJSONSerializable) {
            self.identifier = identifier
            self.timestampDate = timestampDate
            self.json = json
        }
    }

    private var profileItem: SBAProfileItem
    
    public init(with profileKey: String, in profileManagerIdentifier: String) throws {
        let profileManager = SBABridgeConfiguration.shared.profileManager(for: profileManagerIdentifier)
        guard let items = profileManager?.profileItems(),
                let item = items[profileKey]
            else {
                throw RSDValidationError.identifierNotFound(profileManagerIdentifier, profileKey, "Profile item not found for key '\(profileKey)' in profile manager '\(profileManagerIdentifier)")
        }
        self.profileItem = item
    }
    
    open func previousTaskData(for taskIdentifier: RSDIdentifier) -> RSDTaskData? {
        guard let json = self.profileItem.jsonValue else { return nil }
        return TaskData(identifier: self.profileItem.demographicKey, timestampDate: nil, json: json)
    }
    
    open func saveTaskData(_ data: RSDTaskData, from taskResult: RSDTaskResult?) {
        self.profileItem.jsonValue = data.json
    }
}
