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
    
    /// Notification name posted by the `SBAReportManager` when a report will be saved to the server.
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
    public let reportKey: RSDIdentifier

    /// The date for the report.
    public let date: Date
    
    /// The time zone of the report.
    public let timeZone: TimeZone
    
    /// The client data blob associated with this report.
    public let clientData: SBBJSONValue
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(reportKey)
        hasher.combine(date)
    }
    
    public static func == (lhs: SBAReport, rhs: SBAReport) -> Bool {
        return lhs.reportKey == rhs.reportKey && lhs.date == rhs.date
    }
    
    public init(reportKey: RSDIdentifier, date: Date, clientData: SBBJSONValue, timeZone: TimeZone = TimeZone.current) {
        self.reportKey = reportKey
        self.date = date
        self.clientData = clientData
        self.timeZone = timeZone
    }
    
    public init(identifier: String, date: Date?, json: RSDJSONSerializable, timeZone: TimeZone = TimeZone.current) {
        self.reportKey = RSDIdentifier(rawValue: identifier)
        self.date = date ?? SBAReportSingletonDate
        self.clientData = json.toClientData()
        self.timeZone = timeZone
    }
    
    init(taskData: RSDTaskData) {
        self.init(identifier: taskData.identifier, date: taskData.timestampDate, json: taskData.json)
    }
}

extension SBAReport : RSDTaskData {
    
    public var identifier: String {
        return reportKey.stringValue
    }
    
    public var timestampDate: Date? {
        return (date == SBAReportSingletonDate) ? nil : date
    }
    
    public var json: RSDJSONSerializable {
        return clientData.toJSONSerializable()
    }
}

/// The `localDate` used as the reference date for a singleton date object. The user's enrollment date is not
/// used for this so that the report can be found even if the enrollment date is changed.
public let SBAReportSingletonDate: Date = Date(timeIntervalSinceReferenceDate: 0)

/// Default data source handler for reports. This manager is used to get and store `SBBReportData` objects.
open class SBAReportManager: SBAArchiveManager, RSDDataStorageManager {

    /// List of keys used in the notifications sent by this manager.
    public enum NotificationKey : String {
        case newReports
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
    public func now() -> Date {
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
        
        if shouldLoadOnInit {
            self.loadReports()
        }
    }
    
    /// Should the reports be loaded on initialization of the manager (default) or should the
    /// initial loading be handled *after* some set up or using lazy loading?
    open var shouldLoadOnInit: Bool {
        return true
    }
    
    /// Instantiate a new instance of a task view model from the given information. At least one of the input
    /// parameters should be non-nil or this with throw an exception.
    open func instantiateTaskViewModel(task: RSDTask?, taskInfo: RSDTaskInfo?) throws -> RSDTaskViewModel {
        if let task = task {
            let model = RSDTaskViewModel(task: task)
            model.dataManager = self
            return model
        }
        else if let taskInfo = taskInfo {
            let model = RSDTaskViewModel(taskInfo: taskInfo)
            model.dataManager = self
            return model
        }
        else {
            throw RSDValidationError.unexpectedNullObject("Either the task or task info must be non-nil")
        }
    }
    
    public var reports = Set<SBAReport>()
    
    /// The report query is used to describe the type of report being requested.
    public struct ReportQuery : Codable, Hashable {
        
        /// The identifier for the report.
        public let reportKey: RSDIdentifier
        
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
            return reportKey.stringValue
        }
        
        public init(reportKey: RSDIdentifier, queryType: QueryType = .mostRecent, dateRange: (start: Date, end: Date)? = nil) {
            self.reportKey = reportKey
            self.queryType = queryType
            self.startRange = dateRange?.start
            self.endRange = dateRange?.end
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(reportKey)
            hasher.combine(queryType)
        }
    }
    
    /// A serial queue used to manage data crunching.
    static let offMainQueue = DispatchQueue(label: "org.sagebionetworks.BridgeApp.SBAReportManager.shared")
    
    /// The reports with which this manager is concerned. Default returns an empty array.
    open func reportQueries() -> [ReportQuery] {
        return []
    }
    
    /// Reload the data by fetching changes to the data that are used by this manager.
    open func reloadData() {
        loadReports()
    }
    
    /// State management for whether or not the manager is reloading.
    open var isReloading: Bool {
        return isReloadingReports
    }
    
    /// State management for whether or not the *reports* specifically are reloading.
    public final var isReloadingReports: Bool {
        return _reloadingReports.count > 0
    }
    private var _reloadingReports = Set<ReportQuery>()
    
    /// Load the reports using the `reportQueries()` for this schedule manager.
    public final func loadReports() {
        DispatchQueue.main.async {
            if self.isReloadingReports { return }
            let queries = self.reportQueries()
            self._reloadingReports.formUnion(queries)
            
            // If there aren't any reports to fetch then exit early.
            guard queries.count > 0 else {
                self.didFinishFetchingReports()
                return
            }
            
            SBAReportManager.offMainQueue.async {
                // Make sure our requested date ranges from "day one" cover the ReportSingletonDate no matter what time zone it was created in.
                // We subtract 2 days because the Bridge endpoint is non-inclusive of the startDate so only subtracting 1 day won't get reports
                // stored with timestamp 2000-12-31T00:00:00.000Z (or date 2000-12-31).
                let dayOne = SBAReportSingletonDate.addingNumberOfDays(-2)
                queries.forEach { (query) in
                    let category = self.reportCategory(for: query.reportIdentifier)
                    do {
                        switch query.queryType {
                        case .mostRecent:
                            let report: SBBReportData = try self.participantManager.getLatestCachedData(forReport: query.reportIdentifier)
                            if !report.isEmpty {
                                self.didFetchReports(for: query, category: category, reports: [report])
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
    
    // MARK: RSDDataStorageManager
    
    private struct HoldDataKey : Hashable {
        let uuid: UUID
        let identifier: String
        init(_ uuid: UUID, _ identifier: String) {
            self.uuid = uuid
            self.identifier = identifier
        }
    }
    
    private let _holdDataQueue = DispatchQueue(label: "org.sagebionetworks.BridgeApp.SBAReportManager.holdData")
    private var _holdData = [HoldDataKey : RSDTaskData]()
    
    public func previousTaskData(for taskIdentifier: RSDIdentifier) -> RSDTaskData? {
        return report(with: taskIdentifier.stringValue)
    }
    
    public func saveTaskData(_ data: RSDTaskData, from taskResult: RSDTaskResult?) {
        
        // If there isn't a task result then save the task data directly to a report.
        guard let uuid = taskResult?.taskRunUUID else {
            let report = SBAReport(taskData: data)
            DispatchQueue.main.async {
                self.saveReport(report)
            }
            return
        }
        // Otherwise, save it to a holding dictionary for access later when packaging up all the reports
        // for upload at the same time.
        _holdDataQueue.async {
            self._holdData[HoldDataKey(uuid, data.identifier)] = data
        }
    }
    
    
    // MARK: Data handling

    /// Called on the main thread if updating fails.
    open func updateFailed(_ error: Error) {
        debugPrint("WARNING: Failed to fetch cached objects: \(error)")
    }
    
    /// Find the most recent client data for this activity identifier.
    ///
    /// - parameter activityIdentifier: The activity identifier for the client data associated with this task.
    /// - returns: The client data JSON (if any) associated with this activity identifier.
    @available(*, deprecated)
    open func clientData(with activityIdentifier: String) -> SBBJSONValue? {
        return report(with: activityIdentifier)?.clientData
    }
    
    /// Find the most recent report for this activity identifier.
    ///
    /// - parameter activityIdentifier: The activity identifier for the client data associated with this task.
    /// - returns: The latest report (if any) associated with this activity identifier.
    open func report(with activityIdentifier: String) -> SBAReport? {
        let reportIdentifier = self.reportIdentifier(for: activityIdentifier)
        let report = reports.sorted { (lhs, rhs) -> Bool in
            return lhs.date < rhs.date
            }.last { $0.reportKey == reportIdentifier }
        return report
    }
    
    /// Find the client data within the given date range for this activity identifier.
    ///
    /// - parameter activityIdentifier: The activity identifier for the client data associated with this task.
    /// - returns: The client data JSON (if any) associated with this activity identifier.
    open func allClientData(with activityIdentifier: String, from fromDate: Date = Date.distantPast, to toDate: Date = Date.distantFuture) -> [SBBJSONValue] {
        let reportIdentifier = self.reportIdentifier(for: activityIdentifier)
        return self.reports.compactMap {
            guard $0.reportKey == reportIdentifier,
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
            guard query.reportKey == report.reportKey else { return false }
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
        guard newReports.count > 0 else { return }
        if query.queryType == .mostRecent,
            let previous = self.reports.first(where: { $0.reportKey == query.reportKey }),
            newReports.count == 1 {
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
    
    /// Build and save the report `clientData` for the completed task. This should only be called for the
    /// top-level path.
    ///
    /// - parameter taskViewModel: The task path for the task which has just run.
    public func saveReports(for taskViewModel: RSDTaskViewModel) {
        guard taskViewModel.parent == nil else {
            assertionFailure("This method should **only** be called for the top-level task path.")
            return
        }
        
        // Exit early if there are no reports for this task.
        guard let newReports = buildReports(from: taskViewModel.taskResult) else { return }
        
        // Post notification that reports have been created.
        NotificationCenter.default.post(name: .SBAWillSaveReports,
                                        object: self,
                                        userInfo: [NotificationKey.newReports: newReports])
        
        // Save each report to Bridge.
        newReports.forEach { (report) in
            self.saveReportToBridge(report)
        }
    }
    
    /// Save an individual new report.
    ///
    /// - parameter report: The report object to save.
    public func saveReport(_ report: SBAReport) {
        // Post notification that a report has been created.
        NotificationCenter.default.post(name: .SBAWillSaveReports,
                                        object: self,
                                        userInfo: [NotificationKey.newReports: [report]])
        
        // Save the report to Bridge.
        self.saveReportToBridge(report)
    }
    
    /// Save an individual report to Bridge.
    ///
    /// - parameter report: The report object to save to Bridge.
    public func saveReportToBridge(_ report: SBAReport) {
        let reportIdentifier = report.reportKey.stringValue
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
    
    /// Build the reports to return for this task result.
    open func buildReports(from taskResult: RSDTaskResult) -> [SBAReport]? {
        
        // Recursively build a report for all the schemas in this task path.
        var newReports = [SBAReport]()
        func appendReports(_ taskResult: RSDTaskResult) {
            if let schemaInfo = taskResult.schemaInfo ?? self.schemaInfo(for: taskResult.identifier),
                let schemaIdentifier = schemaInfo.schemaIdentifier,
                let clientData = buildClientData(from: taskResult) {
                let date = self.date(for: schemaIdentifier, from: taskResult)
                let report = SBAReport(reportKey: RSDIdentifier(rawValue: schemaIdentifier),
                                       date: date,
                                       clientData: clientData,
                                       timeZone: TimeZone.current)
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
        
        // Get the hold data, if any.
        var holdJSON: RSDJSONSerializable?
        _holdDataQueue.sync {
            let key = HoldDataKey(taskResult.taskRunUUID, taskResult.identifier)
            holdJSON = self._holdData[key]?.json
            self._holdData[key] = nil
        }
        
        // For now, assume that if there is data from the task, that that scoring is all we need. Eventually,
        // this might need to incorporate adding to that data, but don't build that into the function until
        // we discover a need for it. syoung 05/08/2019
        if let json = holdJSON {
            return json.toClientData()
        }
        
        // Otherwise, use a default builder for the scoring.
        let builder = RSDDefaultScoreBuilder()
        return builder.getScoringData(from: taskResult)?.toClientData()
    }
    
    /// This is no longer used by the report manager to build a report. syoung 05/07/2019
    @available(*, unavailable)
    open func buildSurveyAnswerMap(from taskResult: RSDTaskResult) -> [String : Any] {
        fatalError("Do not override this method - it is no longer used.")
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
            let isoString = $0.dateTime ?? $0.localDate ?? ""
            let timeZone = TimeZone(iso8601: isoString) ?? TimeZone.current
            return SBAReport(reportKey: query.reportKey, date: reportDate, clientData: clientData, timeZone: timeZone)
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

extension SBBReportData {
    
    var isEmpty: Bool {
        return data == nil && date == nil
    }
}
