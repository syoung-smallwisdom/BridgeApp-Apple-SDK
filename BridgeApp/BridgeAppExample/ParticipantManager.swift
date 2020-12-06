//
//  ParticipantManager.swift
//  BridgeAppExample
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

import BridgeApp
import BridgeSDK_Test
import Research

public struct StudySetup {
    let email: String = "fake.address@fake.domain.tld"
    let number: String = "206-555-1234"
    let firstName: String = "Fürst"
    let finishedTasks: [RSDIdentifier]
    
    func createParticipant() -> SBBStudyParticipant {
        return SBBStudyParticipant(dictionaryRepresentation: [
            "firstName" : self.firstName,
            "phoneVerified" : NSNumber(value: true),
            "phone": [
                "number": self.number
            ],
            "email": self.email,
            ])!
    }
}

extension RSDIdentifier {
    static let allDay: RSDIdentifier = "All Day"
    static let evening: RSDIdentifier = "Evening"
    static let morning: RSDIdentifier = "Morning"
    static let allTasks: [RSDIdentifier] = [.morning, .evening, .allDay]
}

extension StudySetup {
    static let allDone = StudySetup(finishedTasks: RSDIdentifier.allTasks)
    static let morningCompleted = StudySetup(finishedTasks: [.morning])
    static let noneCompleted = StudySetup(finishedTasks: [])
}

class ParticipantManager: NSObject, SBBParticipantManagerProtocol {
    var timestampedReports: [String: [SBBReportData]] = [:]
    var datestampedReports: [String: [SBBReportData]] = [:]
    
    var testHarness: SBBBridgeTestHarness? {
        return (UIApplication.shared.delegate as? AppDelegate)?.testHarness
    }
    
    var mockParticipant: SBBStudyParticipant
    
    init(studySetup: StudySetup) {
        self.mockParticipant = studySetup.createParticipant()
        super.init()
    }
    
    func setupParticipant() {
        self.testHarness?.post(self.mockParticipant)
    }
    
    func getParticipantRecord(completion: SBBParticipantManagerGetRecordCompletionBlock? = nil) -> URLSessionTask? {
        guard let completion = completion else { return nil }
        completion(self.mockParticipant, nil)
        return nil
    }
    
    func updateParticipantRecord(withRecord participant: Any?, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        self.mockParticipant = participant as! SBBStudyParticipant
        self.testHarness?.post(self.mockParticipant)
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
        var reports = self.timestampedReports[identifier] ?? []
        reports.append(reportData)
        self.timestampedReports[identifier] = reports
        guard let completion = completion else { return nil }
        completion(["message": "fake 200 response JSON"], nil)
        return nil
    }
    
    func saveReportJSON(_ reportJSON: SBBJSONValue, withDateTime dateTime: Date, forReport identifier: String, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        let reportData = SBBReportData()
        reportData.data = reportJSON
        reportData.date = dateTime
        var reports = self.timestampedReports[identifier] ?? []
        reports.append(reportData)
        self.timestampedReports[identifier] = reports
        guard let completion = completion else { return nil }
        completion(["message": "fake 200 response JSON"], nil)
        return nil
    }
    
    func saveReportJSON(_ reportJSON: SBBJSONValue, withLocalDate dateComponents: DateComponents, forReport identifier: String, completion: SBBParticipantManagerCompletionBlock? = nil) -> URLSessionTask? {
        let reportData = SBBReportData()
        reportData.data = reportJSON
        reportData.setDateComponents(dateComponents)
        var reports = self.timestampedReports[identifier] ?? []
        reports.append(reportData)
        self.timestampedReports[identifier] = reports
        guard let completion = completion else { return nil }
        completion(["message": "fake 200 response JSON"], nil)
        return nil
    }
    
    func getLatestCachedData(forReport identifier: String) throws -> SBBReportData {
        guard let reports = self.timestampedReports[identifier] ?? self.datestampedReports[identifier],
            reports.count > 0
            else {
                throw NSError(domain: SBB_ERROR_DOMAIN, code: 0, userInfo: ["description": "No cached data found for report \(identifier)"])
        }
        
        return reports.sorted(by: {
            return $0.date!.compare($1.date!) == ComparisonResult.orderedDescending
        }).first!
    }
    
    
}
