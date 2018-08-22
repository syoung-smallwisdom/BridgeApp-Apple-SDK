//
//  SBAReportManager.swift
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

extension Notification.Name {
    
    /// Notification name posted by the `SBAReportManager` when the reports have been updated.
    public static let SBAUpdatedReports = Notification.Name(rawValue: "SBAUpdatedReports")
    
    /// Notification name posted by the `SBAReportManager` when a report will be save to the server.
    public static let SBAWillSaveReports = Notification.Name(rawValue: "SBAWillSentReport")
}

/// The category for a given report. This is used to determine whether the `dateTime` or `localDate`
/// properties on `SBBReportData` are used to group the reports.
public enum SBAReportCategory : String, Codable {
    case singleton, groupByDay, timestamp
}

/// Convert the `SBBReportData` and `ReportQuery` into a single struct that can be sorted and filtered.
public struct SBAReport : Hashable {

    /// The identifier for the report.
    public let identifier: RSDIdentifier

    /// The date for the report.
    public let date: Date
    
    /// The client data blob associated with this report.
    public let clientData: SBBJSONValue
    
    public var hashValue: Int {
        return self.identifier.hashValue ^ RSDObjectHash(self.date)
    }
    
    public static func == (lhs: SBAReport, rhs: SBAReport) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.date == rhs.date
    }
}

/// The `localDate` used as the reference date for a singleton date object. The user's enrollment date is not
/// used for this so that the report can be found even if the enrollment date is changed.
public let SBAReportSingletonDate: Date = Date(timeIntervalSinceReferenceDate: 0)

/// Default data source handler for reports. This manager is used to get and store `SBBReportData` objects.
///
open class SBAReportManager: NSObject {
    
    /// List of keys used in the notifications sent by this manager.
    public enum NotificationKey : String {
        case newReports
    }
    
    /// Pointer to the shared configuration to use.
    public var configuration: SBABridgeConfiguration {
        return SBABridgeConfiguration.shared
    }
    
    /// Pointer to the shared participant to use.
    public var participant: SBBStudyParticipant? {
        return SBAParticipantManager.shared.studyParticipant
    }
    
    /// Pointer to the shared participant manager.
    public var participantManager: SBBParticipantManagerProtocol {
        return BridgeSDK.participantManager
    }
    
    /// This is an internal function that can be used in testing instead of using `Date()` directly. It can
    /// then be overridden by a test subclass of this manager in order to return a known date.
    func now() -> Date {
        return Date()
    }
    
    public override init() {
        super.init()
        
        NotificationCenter.default.addObserver(forName: .SBAWillSaveReports, object: nil, queue: .main) { (notification) in
            guard let newReports = notification.userInfo?[SBAReportManager.NotificationKey.newReports] as? [SBAReport]
                else {
                    return
            }
            self.addReports(with: newReports)
        }
        
        self.loadReports()
    }
    
    public var reports = Set<SBAReport>()
    
    /// The report query is used to describe the type of report being requested.
    public struct ReportQuery : Codable, Hashable {
        
        /// The identifier for the report.
        public let identifier: RSDIdentifier
        
        /// The type of query.
        public let queryType: QueryType
        
        /// The type of report being requested.
        public enum QueryType : String, Codable {
            case mostRecent, all, today, dateRange
        }
        
        /// For `QueryType.dateRange`, the date range of the query.
        public var dateRange: (start: Date, end: Date)? {
            guard let start = self.startRange, let end = self.endRange else { return nil }
            return (start, end)
        }
        private let startRange: Date?
        private let endRange: Date?
        
        /// The report identifier as a string for use in requesting reports from Bridge.
        public var reportIdentifier: String {
            return identifier.stringValue
        }
        
        public init(identifier: RSDIdentifier, queryType: QueryType = .mostRecent, dateRange: (start: Date, end: Date)? = nil) {
            self.identifier = identifier
            self.queryType = queryType
            self.startRange = dateRange?.start
            self.endRange = dateRange?.end
        }
        
        public var hashValue: Int {
            return self.identifier.hashValue ^ self.queryType.hashValue
        }
    }
    
    /// A serial queue used to manage data crunching.
    static let offMainQueue = DispatchQueue(label: "org.sagebionetworks.BridgeApp.SBAReportManager.shared")
    
    /// The reports with which this manager is concerned. Default returns an empty array.
    open func reportQueries() -> [ReportQuery] {
        return []
    }
    
    /// Reload the data by fetching changes to the reports.
    open func reloadData() {
        loadReports()
    }
    
    /// State management for whether or not the schedules are reloading.
    public var isReloading: Bool {
        return _reloadingReports.count > 0
    }
    private var _reloadingReports = Set<ReportQuery>()
    
    /// Load the scheduled activities from cache using the `fetchRequests()` for this schedule manager.
    public final func loadReports() {
        DispatchQueue.main.async {
            if self.isReloading { return }
            let queries = self.reportQueries()
            self._reloadingReports.formUnion(queries)
            
            // If there aren't any reports to fetch then exit early.
            guard queries.count > 0 else {
                self.didFinishFetchingReports()
                return
            }
            
            SBAReportManager.offMainQueue.async {
                let dayOne = self.participant?.createdOn ?? self.now().startOfDay()
                queries.forEach { (query) in
                    let category = self.reportCategory(for: query.reportIdentifier)
                    do {
                        switch query.queryType {
                        case .mostRecent:
                            let report: SBBReportData? = try self.participantManager.getLatestCachedData(forReport: query.reportIdentifier)
                            if report != nil {
                                self.didFetchReports(for: query, category: category, reports: [report!])
                            }
                            else {
                                self.fetchReport(for: query, category: category, startDate: dayOne, endDate: self.now())
                            }
                            
                        case .all:
                            self.fetchReport(for: query, category: category, startDate: dayOne, endDate: self.now())
                            
                        case .today:
                            let end = self.now()
                            let start = end.startOfDay()
                            self.fetchReport(for: query, category: category, startDate: start, endDate: end)
                            
                        case .dateRange:
                            guard let dateRange = query.dateRange else {
                                throw RSDValidationError.unexpectedNullObject("For a `QueryType.dateRange` report query, the `dateRange` property should be non-nil.")
                            }
                            self.fetchReport(for: query, category: category, startDate: dateRange.start, endDate: dateRange.end)
                            
                        }
                    }
                    catch let error {
                        self.didFetchReports(for: query, category: category, reports: nil, error: error)
                    }
                }
            }
        }
    }
    
    // MARK: Data handling

    /// Called on the main thread if updating the scheduled activities fails.
    open func updateFailed(_ error: Error) {
        debugPrint("WARNING: Failed to fetch cached objects: \(error)")
    }
    
    /// Find the most recent client data for this activity identifier.
    ///
    /// - parameter activityIdentifier: The activity identifier for the client data associated with this task.
    /// - returns: The client data JSON (if any) associated with this activity identifier.
    open func clientData(with activityIdentifier: String) -> SBBJSONValue? {
        let reportIdentifier = self.reportIdentifier(for: activityIdentifier)
        let report = reports.sorted { (lhs, rhs) -> Bool in
            return lhs.date < rhs.date
            }.rsd_last { $0.identifier == reportIdentifier }
        return report?.clientData
    }
    
    /// Find the client data within the given date range for this activity identifier.
    ///
    /// - parameter activityIdentifier: The activity identifier for the client data associated with this task.
    /// - returns: The client data JSON (if any) associated with this activity identifier.
    open func allClientData(with activityIdentifier: String, from fromDate: Date = Date.distantPast, to toDate: Date = Date.distantFuture) -> [SBBJSONValue] {
        let reportIdentifier = self.reportIdentifier(for: activityIdentifier)
        return self.reports.compactMap {
            guard $0.identifier == reportIdentifier,
                (fromDate <= $0.date && $0.date < toDate)
                else {
                    return nil
            }
            return $0.clientData
        }
    }
    
    /// Return the report identifier for a given activity identifier.
    open func reportIdentifier(for activityIdentifier: String) -> String {
        return self.configuration.schemaInfo(for: activityIdentifier)?.schemaIdentifier ?? activityIdentifier
    }
    
    /// Get the report category (if any defined) for the given identifier. Default calls through to
    /// `SBABridgeConfiguration` and returns `.timestamp` if undefined by the configuration.
    open func reportCategory(for reportIdentifier: String) -> SBAReportCategory {
        return self.configuration.reportCategory(for: reportIdentifier) ?? .timestamp
    }
    
    /// Get the schema info associated with the given activity identifier. By default, this looks at the
    /// shared bridge configuration's schema reference map.
    open func schemaInfo(for activityIdentifier: String) -> RSDSchemaInfo? {
        return self.configuration.schemaInfo(for: activityIdentifier)
    }
    
    func addReports(with newReports: [SBAReport], for query: ReportQuery? = nil) {
        
        var updatedReports = [SBAReport]()
        if query != nil {
            self.unionReports(newReports, query: query!)
            updatedReports.append(contentsOf: newReports)
        }
        else {
            let queries = self.reportQueries()
            queries.forEach {
                let filteredReports = self.filteredReports(newReports, query: $0)
                self.unionReports(filteredReports, query: $0)
                updatedReports.append(contentsOf: filteredReports)
            }
        }
        
        self.didUpdateReports(with: updatedReports)
    }

    func filteredReports( _ newReports: [SBAReport], query: ReportQuery) -> [SBAReport] {
        return newReports.filter { (report) -> Bool in
            guard query.identifier == report.identifier else { return false }
            switch query.queryType {
            case .today:
                return report.date.isToday
                
            case .dateRange:
                guard let dateRange = query.dateRange else { return false }
                return dateRange.start <= report.date && report.date <= dateRange.end
                
            default:
                return true
            }
        }
    }
    
    func unionReports(_ newReports: [SBAReport], query: ReportQuery) {
        if query.queryType == .mostRecent,
            let previous = self.reports.first(where: { $0.identifier == query.identifier }) {
            self.reports.remove(previous)
        }
        self.reports.formUnion(newReports)
    }
    
    /// Post notification that the reports were updated.
    open func didUpdateReports(with newReports: [SBAReport]) {
        NotificationCenter.default.post(name: .SBAUpdatedReports,
                                        object: self,
                                        userInfo: [NotificationKey.newReports: newReports])
    }
    
    /// Update the values on the scheduled activity. By default, this will recurse through the task path
    /// and its children, looking for a schedule associated with the subtask path.
    ///
    /// - parameter taskPath: The task path for the task which has just run.
    public func saveReports(for taskPath: RSDTaskPath) {
        guard taskPath.parentPath == nil else {
            assertionFailure("This method should **only** be called for the top-level task path.")
            return
        }
        
        // Exit early if there are no reports for this task.
        guard let newReports = buildReports(from: taskPath.result) else { return }
        
        // Post notification that reports have been created.
        NotificationCenter.default.post(name: .SBAWillSaveReports,
                                        object: self,
                                        userInfo: [NotificationKey.newReports: newReports])
        
        // Save each report.
        newReports.forEach { (report) in
            let reportIdentifier = report.identifier.stringValue
            let category = self.reportCategory(for: reportIdentifier)
            switch category {
            case .timestamp:
                self.participantManager.saveReportJSON(report.clientData,
                                                       withDateTime: report.date,
                                                       forReport: reportIdentifier,
                                                       completion: nil)
            default:
                self.participantManager.saveReportJSON(report.clientData,
                                                       withLocalDate: report.date.dateOnly(),
                                                       forReport: reportIdentifier,
                                                       completion: nil)
            }
        }
    }
    
    /// Build the reports to return for this task result.
    open func buildReports(from taskResult: RSDTaskResult) -> [SBAReport]? {
        
        // Recursively build a report for all the schemas in this task path.
        var newReports = [SBAReport]()
        func appendReports(_ taskResult: RSDTaskResult) {
            if let schemaInfo = taskResult.schemaInfo ?? self.schemaInfo(for: taskResult.identifier),
                let schemaIdentifier = schemaInfo.schemaIdentifier,
                let clientData = buildClientData(from: taskResult) {
                let date = self.date(for: schemaIdentifier, from: taskResult)
                let report = SBAReport(identifier: RSDIdentifier(rawValue: schemaIdentifier),
                                       date: date,
                                       clientData: clientData)
                newReports.append(report)
            }
            taskResult.stepHistory.forEach {
                guard let subtaskResult = $0 as? RSDTaskResult else { return }
                appendReports(subtaskResult)
            }
        }
        appendReports(taskResult)
        
        return newReports.count > 0 ? newReports : nil
    }
    
    /// The date to use for the report with the given identifier.
    open func date(for reportIdentifier: String, from result: RSDTaskResult) -> Date {
        let category = self.reportCategory(for: reportIdentifier)
        switch category {
        case .singleton:
            return SBAReportSingletonDate
        case .groupByDay:
            return result.endDate.startOfDay()
        case .timestamp:
            return result.endDate
        }
    }
    
    /// Build the client data from the given task path.
    ///
    /// - parameters:
    ///     - taskResult: The task result for the task which has just run.
    /// - returns: The client data built for this task result (if any).
    func buildClientData(from taskResult: RSDTaskResult) -> SBBJSONValue? {
        do {
            let clientData = try recursiveGetClientData(from: taskResult, isTopLevel: true)
            return clientData ?? (self.buildSurveyAnswerMap(from: taskResult) as NSDictionary)
        }
        catch let err {
            assertionFailure("Failed to encode client data: \(err)")
            return nil
        }
    }
    
    /// Build a simple answer map for this task result.
    /// - note: This can be used to create client data for surveys.
    open func buildSurveyAnswerMap(from taskResult: RSDTaskResult) -> [String : Any] {
        var answers = [String : Any]()
        
        func appendValue(_ value: Any?, forKey key: String) {
            answers[key] = (value as? SBBJSONValue) ?? (value as? RSDJSONValue)?.jsonObject()
        }
        
        func appendResult(_ result: RSDResult) {
            if let answers = (result as? RSDCollectionResult)?.answers() {
                answers.forEach {
                    appendValue($0.value, forKey: $0.key)
                }
            }
            else if let answerResult = result as? RSDAnswerResult {
                appendValue(answerResult.value, forKey: answerResult.identifier)
            }
        }
        
        taskResult.stepHistory.forEach { appendResult($0) }
        taskResult.asyncResults?.forEach { appendResult($0) }
        
        return answers
    }
    
    func recursiveGetClientData(from taskResult: RSDTaskResult, isTopLevel: Bool) throws  -> SBBJSONValue? {
        // Verify that this task result is not associated with a different schema.
        guard isTopLevel || (taskResult.schemaInfo ?? self.schemaInfo(for: taskResult.identifier) == nil)
            else {
                return nil
        }
        
        var dataResults: [SBBJSONValue] = []
        if let data = try recursiveGetClientData(from: taskResult.stepHistory) {
            dataResults.append(data)
        }
        if let asyncResults = taskResult.asyncResults,
            let data = try recursiveGetClientData(from: asyncResults) {
            dataResults.append(data)
        }
        
        if let clientData = dataResults.count <= 1 ? dataResults.first : (dataResults as NSArray) {
            return clientData
        }
        else {
            return nil
        }
    }
    
    func recursiveGetClientData(from results: [RSDResult]) throws -> SBBJSONValue? {
        
        func getClientData(_ result: RSDResult) throws -> SBBJSONValue? {
            if let clientResult = result as? SBAClientDataResult,
                let clientData = try clientResult.clientData() {
                return clientData
            }
            else if let taskResult = result as? RSDTaskResult {
                return try self.recursiveGetClientData(from: taskResult, isTopLevel: false)
            }
            else if let collectionResult = result as? RSDCollectionResult {
                return try self.recursiveGetClientData(from: collectionResult.inputResults)
            }
            else {
                return nil
            }
        }
        
        let dictionary = try results.rsd_filteredDictionary { (result) throws -> (String, SBBJSONValue)? in
            guard let data = try getClientData(result) else { return nil }
            return (result.identifier, data)
        }
        
        // Return the "most appropriate" value for the combined results.
        if dictionary.count == 0 {
            return nil
        }
        else if dictionary.sba_uniqueCount() == 1 {
            return dictionary.first!.value
        }
        else {
            return dictionary as NSDictionary
        }
    }
    
    func fetchReport(for query: ReportQuery, category: SBAReportCategory, startDate: Date, endDate: Date) {
        let category = self.reportCategory(for: query.reportIdentifier)
        
        switch category {
        case .timestamp:
            self.participantManager.getReport(query.reportIdentifier, fromTimestamp: startDate, toTimestamp: endDate) { [weak self] (obj, error) in
                self?.didFetchReports(for: query, category: category, reports: obj as? [SBBReportData], error: error)
            }
            
        case .groupByDay:
            self.participantManager.getReport(query.reportIdentifier, fromDate: startDate.dateOnly(), toDate: endDate.dateOnly()) { [weak self] (obj, error) in
                self?.didFetchReports(for: query, category: category, reports: obj as? [SBBReportData], error: error)
            }
            
        case .singleton:
            let dateComponents = SBAReportSingletonDate.dateOnly()
            self.participantManager.getReport(query.reportIdentifier, fromDate: dateComponents, toDate: dateComponents) { [weak self] (obj, error) in
                self?.didFetchReports(for: query, category: category, reports: obj as? [SBBReportData], error: error)
            }
        }
    }
    
    func didFetchReports(for query: ReportQuery, category: SBAReportCategory, reports inReports: [SBBReportData]?, error inError: Error? = nil) {
        
        let reportDataObjects: [SBBReportData] = {
            guard let response = inReports, query.queryType == .mostRecent, response.count > 0
                else {
                    return inReports ?? []
            }
            let report = response.sorted { (lhs, rhs) -> Bool in
                guard let lhsDate = lhs.date, let rhsDate = rhs.date else { return false }
                return lhsDate < rhsDate
                }.last!
            return [report]
        }()

        let newReports: [SBAReport] = reportDataObjects.compactMap {
            guard let clientData = $0.data, let date = $0.date else { return nil }
            let reportDate = (category == .groupByDay) ? date.startOfDay() : date
            return SBAReport(identifier: query.identifier, date: reportDate, clientData: clientData)
        }
        
        let error: Error? = {
            if inError != nil || inReports != nil {
                return inError
            }
            else {
                return RSDValidationError.unexpectedNullObject("Error and response are both nil for \(query)")
            }
        }()
        
        DispatchQueue.main.async {
            if let err = error {
                self.updateFailed(err)
            }
            else {
                self.addReports(with: newReports, for: query)
            }
            self._reloadingReports.remove(query)
            if self._reloadingReports.count == 0 {
                self.didFinishFetchingReports()
            }
        }
    }
    
    /// Called when all the reports are finished loading. Base class does nothing.
    open func didFinishFetchingReports() {
    }
}
