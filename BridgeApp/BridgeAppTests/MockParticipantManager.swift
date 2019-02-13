//
//  MockParticipantManager.swift
//  BridgeAppTests
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

import UIKit

class MockParticipantManager: NSObject, SBBParticipantManagerProtocol {
    func getParticipantRecord(completion: SBBParticipantManagerGetRecordCompletionBlock? = nil) -> URLSessionTask? {
        assert(false, "getParticipantRecord(completion:) not implemented in mock")
        return nil
    }
    
    func updateParticipantRecord(withRecord participant: Any?, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        assert(false, "updateParticipantRecord(withRecord:, completion:) not implemented in mock")
        return nil
    }
    
    func setExternalIdentifier(_ externalID: String?, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        assert(false, "setExternalIdentifier(_, completion:) not implemented in mock")
        return nil
    }
    
    func setSharingScope(_ scope: SBBParticipantDataSharingScope, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        assert(false, "setSharingScope(_, completion:) not implemented in mock")
        return nil
    }
    
    func getDataGroups(completion: @escaping SBBParticipantManagerGetGroupsCompletionBlock) -> URLSessionTask? {
        assert(false, "getDataGroups(completion:) not implemented in mock")
        return nil
    }
    
    func updateDataGroups(withGroups dataGroups: Set<String>, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        assert(false, "updateDataGroups(withGroups:, completion:) not implemented in mock")
        return nil
    }
    
    func add(toDataGroups dataGroups: Set<String>, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        assert(false, "add(toDataGroups:, completion:) not implemented in mock")
        return nil
    }
    
    func remove(fromDataGroups dataGroups: Set<String>, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        assert(false, "remove(fromDataGroups:, completion:) not implemented in mock")
        return nil
    }
    
    func getReport(_ identifier: String, fromTimestamp: Date, toTimestamp: Date, completion: @escaping SBBParticipantManagerGetReportCompletionBlock) -> URLSessionTask? {
        assert(false, "getReport(_, fromTimestamp:, toTimestamp:, completion:) not implemented in mock")
        return nil
    }
    
    func getReport(_ identifier: String, fromDate: DateComponents, toDate: DateComponents, completion: @escaping SBBParticipantManagerGetReportCompletionBlock) -> URLSessionTask? {
        assert(false, "getReport(_, fromDate:, toDate:, completion:) not implemented in mock")
        return nil
    }
    
    func save(_ reportData: SBBReportData, forReport identifier: String, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        assert(false, "save(_, forReport:, completion:) not implemented in mock")
        return nil
    }
    
    func saveReportJSON(_ reportJSON: SBBJSONValue, withDateTime dateTime: Date, forReport identifier: String, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        assert(false, "saveReportJSON(_, withDateTime:, forReport:, completion:) not implemented in mock")
        return nil
    }
    
    func saveReportJSON(_ reportJSON: SBBJSONValue, withLocalDate dateComponents: DateComponents, forReport identifier: String, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        assert(false, "saveReportJSON(_, withLocalDate:, forReport:, completion:) not implemented in mock")
        return nil
    }
    
    func getLatestCachedData(forReport identifier: String) throws -> SBBReportData {
        assert(false, "getLatestCachedData(forReport:) not implemented in mock")
        return SBBReportData()
    }
    

}
