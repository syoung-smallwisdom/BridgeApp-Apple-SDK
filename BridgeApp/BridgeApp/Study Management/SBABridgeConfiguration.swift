//
//  SBABridgeConfiguration.swift
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
import BridgeSDK

// https://stackoverflow.com/a/48173579
struct DecodingHelper: Decodable {
    private let decoder: Decoder
    
    init(from decoder: Decoder) throws {
        self.decoder = decoder
    }
    
    func decode(to type: Decodable.Type) throws -> Decodable {
        let decodable = try type.init(from: decoder)
        return decodable
    }
}

/// Override the default task repository to include transforming from surveys, compound activities, and other
/// tasks defined by the Bridge configuration.
open class SBATaskRepository : RSDTaskRepository {
    
    override open func taskTransformer(for taskInfo: RSDTaskInfo) throws -> RSDTaskTransformer {
        if let transformer = taskInfo.resourceTransformer {
            return transformer
        }
        else if let surveyReference = taskInfo as? SBBSurveyReference {
            return SBASurveyLoader(surveyReference: surveyReference)
        }
        else if let combo = taskInfo as? SBBCompoundActivity {
            return SBAConfigurationTaskTransformer(task: combo)
        }
        else {
            let activityIdentifier = (taskInfo as? SBAActivityInfo)?.moduleId?.stringValue ?? taskInfo.identifier
            return SBABridgeConfiguration.shared.taskTransformer(for: activityIdentifier)
        }
    }
    
    override open func schemaInfo(for taskInfo: RSDTaskInfo) -> RSDSchemaInfo? {
        return SBABridgeConfiguration.shared.schemaInfo(for: taskInfo.identifier) ?? taskInfo.schemaInfo
    }
}

/// `SBABridgeConfiguration` is used as a wrapper for combining task group and task info objects that are
/// singletons with the `SBBActivity` objects that contain a subset of the information used to implement
/// the `RSDTaskInfo` protocol.
open class SBABridgeConfiguration {
    
    /// The shared singleton.
    public static var shared = SBABridgeConfiguration()
    
    /// A mapping of identifiers to activity groups defined for this application.
    fileprivate var activityGroupMap : [String : SBAActivityGroup] = [:]
    
    /// A mapping of activity identifiers to activity infos defined for this application.
    fileprivate var activityInfoMap : [String : SBAActivityInfo] = [:]
    
    /// A mapping of schema identifiers to schema references.
    fileprivate var schemaReferenceMap: [String : SBBSchemaReference] = [:]
    
    /// A mapping of activity identifiers to survey references.
    fileprivate var surveyReferenceMap: [String : SBBSurveyReference] = [:]
    
    /// A mapping of activity identifiers to tasks.
    fileprivate var taskMap : [String : RSDTask] = [:]
    
    /// A mapping of task identifier to schema identifier.
    fileprivate var taskToSchemaIdentifierMap : [String : String] = [:]
    
    /// A mapping of report identifier to report category.
    fileprivate var reportMap : [String : SBAReportCategory] = [:]
    
    /// The duration of the study. Default = 1 year.
    open var studyDuration : DateComponents = {
        var studyDuration = DateComponents()
        studyDuration.year = 1
        return studyDuration
    }()
    
    /// The profile manager for the study.
    open private(set) var profileManager : SBAProfileManager = SBAProfileManagerObject()
    
    /// The profile data source for the study.
    open private(set) var profileDataSource : SBAProfileDataSource = SBAProfileDataSourceObject()
    
    public init() {
    }
    
    /// Set up BridgeSDK including loading any cached configurations.
    open func setupBridge(with factory: RSDFactory, setupBlock: (()->Void)? = nil) {
        guard !_hasInitialized else { return }
        _hasInitialized = true
        
        RSDTaskRepository.shared = SBATaskRepository()
        
        // Insert this bundle into the list of localized bundles.
        Localization.insert(bundle: LocalizationBundle(Bundle(for: SBABridgeConfiguration.self)),
                            at: UInt(Localization.allBundles.count))
        
        // Set the factory to this one by default.
        RSDFactory.shared = factory
        let _ = SBAParticipantManager.shared
        
        if let block = setupBlock {
            block()
        } else {
            BridgeSDK.setup()
        }
        
        // Set up the app config. Load the cached version and also set up a listener to get the updated config
        // once it has loaded.
        NotificationCenter.default.addObserver(forName: .sbbAppConfigUpdated, object: nil, queue: OperationQueue.main) { (notification) in
            guard let appConfig = notification.userInfo?[kSBBAppConfigInfoKey] as? SBBAppConfig ?? BridgeSDK.appConfig()
                else {
                    return
            }
            self.setup(with: appConfig)
        }
        if let appConfig = BridgeSDK.appConfig() {
            setup(with: appConfig)
        }
        else {
            refreshAppConfig()
        }
    }
    private var _hasInitialized = false
    
    /// Refresh the app config by pinging Bridge services.
    open func refreshAppConfig() {
        (SBBComponentManager.component(SBBStudyManager.classForCoder()) as! SBBStudyManagerProtocol).getAppConfig { (response, error) in
            guard error == nil, let appConfig = response as? SBBAppConfig else { return }
            DispatchQueue.main.async {
                self.setup(with: appConfig)
            }
        }
    }
    
    /// Decode the `clientData`, schemas, and surveys for this application.
    open func setup(with appConfig: SBBAppConfig) {
        // Map the schemas
        appConfig.schemaReferences?.forEach {
            self.addMapping(with: $0 as! SBBSchemaReference)
        }
        appConfig.surveyReferences?.forEach {
            self.addMapping(with: $0 as! SBBSurveyReference)
        }
        if let clientData = appConfig.clientData {
            // If there is a clientData object, need to serialize it back into data before decoding it.
            do {
                let decoder = RSDFactory.shared.createJSONDecoder()
                let mappingObject = try decoder.decode(SBAActivityMappingObject.self, from: clientData)
                if let studyDuration = mappingObject.studyDuration {
                    self.studyDuration = studyDuration
                }
                mappingObject.groups?.forEach {
                    self.addMapping(with: $0)
                }
                mappingObject.activityList?.forEach {
                    self.addMapping(with: $0)
                }
                mappingObject.tasks?.forEach {
                    self.addMapping(with: $0)
                }
                mappingObject.taskToSchemaIdentifierMap?.forEach {
                    self.addMapping(from: $0.key, to: $0.value)
                }
                mappingObject.reportMappings?.forEach {
                    self.addMapping(with: $0.key, to: $0.value)
                }
                
                if let profileMapping = mappingObject.profile {
                    self.profileManager = profileMapping.manager
                    self.profileDataSource = profileMapping.dataSource
                }
            } catch let err {
                debugPrint("Failed to decode the clientData object: \(err)")
                // Attempt refreshing the app config in case the cached version is out-of-date.
                refreshAppConfig()
            }
        }
    }
    
    
    /// Update the mapping by adding the given activity info.
    open func addMapping(with activityInfo: SBAActivityInfo) {
        self.activityInfoMap[activityInfo.identifier] = activityInfo
    }
    
    /// Update the mapping by adding the given activity group.
    open func addMapping(with activityGroup: SBAActivityGroup) {
        self.activityGroupMap[activityGroup.identifier] = activityGroup
    }
    
    /// Update the mapping by adding the given schema reference.
    open func addMapping(with schemaReference: SBBSchemaReference) {
        self.schemaReferenceMap[schemaReference.identifier] = schemaReference
    }
    
    /// Update the mapping by adding the given survey reference.
    open func addMapping(with surveyReference: SBBSurveyReference) {
        self.surveyReferenceMap[surveyReference.identifier] = surveyReference
    }
    
    /// Update the mapping by adding the given task.
    open func addMapping(with task: RSDTask) {
        if !self.activityInfoMap.contains(where: { $0.value.moduleId?.stringValue == task.identifier })  {
            let activityInfo = SBAActivityInfoObject(identifier: RSDIdentifier(rawValue: task.identifier),
                                                     title: nil,
                                                     subtitle: nil,
                                                     detail: nil,
                                                     estimatedMinutes: nil,
                                                     iconImage: nil,
                                                     resource: nil,
                                                     moduleId: SBAModuleIdentifier(rawValue: task.identifier))
            self.addMapping(with: activityInfo)
        }
        self.taskMap[task.identifier] = task
    }
    
    /// Update the mapping of a report identifier to a given category.
    open func addMapping(with reportIdentifier: String, to category: SBAReportCategory) {
        self.reportMap[reportIdentifier] = category
    }
    
    /// Update the mapping from the activity identifier to the matching schema identifier.
    open func addMapping(from activityIdentifier: String, to schemaIdentifier: String) {
        self.taskToSchemaIdentifierMap[activityIdentifier] = schemaIdentifier
    }

    /// Override this method to return a task transformer for a given task. This method is intended
    /// to be able to run active tasks such as "tapping" or "tremor" where the task module is described
    /// in another github repository.
    open func taskTransformer(for activityIdentifier: String) -> RSDTaskTransformer {
        if let task = self.task(for: activityIdentifier) {
            return SBAConfigurationTaskTransformer(task: task)
        }
        else if let surveyReference = self.survey(for: activityIdentifier) {
            return SBASurveyLoader(surveyReference: surveyReference)
        }
        else if let transformer = self.activityInfo(for: activityIdentifier)?.resourceTransformer {
            return transformer
        }
        else {
            return RSDResourceTransformerObject(resourceName: activityIdentifier)
        }
    }
    
    /// Get the activity group with the given identifier.
    open func activityGroup(with identifier: String) -> SBAActivityGroup? {
        return activityGroupMap[identifier]
    }
    
    /// Look for a task info object in the mapping tables for the given activity reference.
    open func activityInfo(for activityIdentifier: String) -> SBAActivityInfo? {
        return self.activityInfoMap[activityIdentifier]
    }
    
    /// Get the task to return for the given identifier.
    open func task(for activityIdentifier: String) -> RSDTask? {
        
        // Look for a mapped task identifier.
        let storedTask = self.taskMap[activityIdentifier]
        let schemaInfo = self.schemaInfo(for: activityIdentifier)
        
        // Copy if option available.
        if let copyableTask = storedTask as? RSDCopyTask {
            return copyableTask.copy(with: activityIdentifier, schemaInfo: schemaInfo)
        } else {
            return storedTask
        }
    }
    
    /// Get the schema info associated with the given activity identifier. By default, this looks at the
    /// shared bridge configuration's schema reference map.
    open func schemaInfo(for activityIdentifier: String) -> RSDSchemaInfo? {
        let schemaIdentifier = self.taskToSchemaIdentifierMap[activityIdentifier] ?? activityIdentifier
        return self.schemaReferenceMap[schemaIdentifier]
    }
    
    /// Get the survey with the given identifier.
    open func survey(for surveyIdentifier: String) -> SBBSurveyReference? {
        return self.surveyReferenceMap[surveyIdentifier]
    }
    
    /// Get the report category for a given report identifier.
    open func reportCategory(for reportIdentifier: String) -> SBAReportCategory? {
        return self.reportMap[reportIdentifier]
    }
    
    /// Listing of all the surveys included in the reference mapping.
    public func allSurveys() -> [SBBSurveyReference] {
        return surveyReferenceMap.map { $0.value }
    }
    
    /// Listing of all the schemas included in the reference mapping.
    public func allSchemas() -> [SBBSchemaReference] {
        return schemaReferenceMap.map { $0.value }
    }
    
    /// Listing of all the activity groups in the reference mapping.
    public func allActivityGroups() -> [SBAActivityGroup] {
        return activityGroupMap.map { $0.value }
    }
}

/// A light-weight pointer to a stored task.
class SBAConfigurationTaskTransformer : RSDTaskTransformer {
    
    let task: RSDTask
    init(task: RSDTask) {
        self.task = task
    }
    
    var estimatedFetchTime: TimeInterval {
        return 0
    }
    
    func fetchTask(with taskIdentifier: String, schemaInfo: RSDSchemaInfo?, callback: @escaping RSDTaskFetchCompletionHandler) {
        DispatchQueue.main.async {
            if let copyableTask = self.task as? RSDCopyTask {
                callback(copyableTask.copy(with: taskIdentifier, schemaInfo: schemaInfo), nil)
            } else {
                callback(self.task, nil)
            }
        }
    }
}


/// A protocol that can be used to filter and parse the scheduled activities for a
/// variety of customized UI/UX designs based on the objects defined in the
public protocol SBAActivityGroup : RSDTaskGroup {
    
    /// The text to display for the task group when displaying this in a list or
    /// collection where the format of the string is compact or extended, depending
    /// upon the requirements of the UI design.
    var journeyTitle: String? { get }
    
    /// A list of the activity identifiers associated with this task group.
    var activityIdentifiers : [RSDIdentifier] { get }
    
    /// An identifier that can be used to associate an `SBBScheduledActivity` instance
    /// with setting up a local reminder for when to perform a task.
    var notificationIdentifier : RSDIdentifier? { get }
    
    /// The schedule plan guid that can be used to map scheduled activities to
    /// the appropriate group in the case where more than one group may contain
    /// the same tasks.
    var schedulePlanGuid : String? { get }
    
    /// The activity guid map that can be used to map scheduled activities to
    /// the appropriate group in the case where more than one group may contain
    /// the same tasks **but** where the activities are not all grouped on the server
    /// using the same schedule. This guid can be found in the Bridge Study Manager UI
    /// by hovering your cursor over the copy icon and selecting "Copy GUID".
    var activityGuidMap : [String : String]? { get }
}

/// Extend the task info protocol to include optional pointers for use by an `SBBTaskReference`
/// as the source of a task transformer.
public protocol SBAActivityInfo : RSDTaskInfo {
    
    /// An optional string that can be used to identify an active task module such as a
    /// "tapping" task or "walkAndBalance" task.
    var moduleId: SBAModuleIdentifier?  { get }
}

// MARK: Codable implementation of the mapping objects.

/// `SBAActivityMappingObject` is a decodable instance of an activity mapping
/// that can be used to decode a Plist or JSON dictionary.
struct SBAActivityMappingObject : Decodable {
    let studyDuration : DateComponents?
    let groups : [SBAActivityGroupObject]?
    let activityList : [SBAActivityInfoObject]?
    let tasks : [RSDTaskObject]?
    let taskToSchemaIdentifierMap : [String : String]?
    let reportMappings : [String : SBAReportCategory]?
    let profile : SBAProfileMappingObject?
}

/// `SBAActivityGroupObject` is a `Decodable` implementation of a `SBAActivityGroup`.
///
/// - example:
/// ````
///    // Example activity group using a shared `schedulePlanGuid`.
///    let json = """
///            {
///                "identifier": "foo",
///                "title": "Title",
///                "journeyTitle": "Journey title",
///                "detail": "A detail about the object",
///                "imageSource": "fooImage",
///                "activityIdentifiers": ["taskA", "taskB", "taskC"],
///                "notificationIdentifier": "scheduleFoo",
///                "schedulePlanGuid": "abcdef12-3456-7890",
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
///
///    // Example activity group using the `activity.guid` identifiers to map schedules to tasks.
///    let json = """
///            {
///                "identifier": "foo",
///                "activityIdentifiers": ["taskA", "taskB", "taskC"],
///                "activityGuidMap": {
///                                     "taskA":"ababab12-3456-7890",
///                                     "taskB":"cdcdcd12-3456-7890",
///                                     "taskC":"efefef12-3456-7890"
///                                     }
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
///
///    // Example activity group where the first schedule matching the given activity identifer is used.
///    let json = """
///            {
///                "identifier": "foo",
///                "activityIdentifiers": ["taskA", "taskB", "taskC"]
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
/// ````
public struct SBAActivityGroupObject : Decodable, SBAOptionalImageVendor, SBAActivityGroup {

    /// A short string that uniquely identifies the task group.
    public let identifier: String
    
    /// The primary text to display for the task group in a localized string.
    public let title: String?
    
    /// Detail text information about the task group.
    public let detail: String?
    
    /// The text to display for the task group when displaying this in a list or
    /// collection where the format of the string is compact or extended, depending
    /// upon the requirements of the UI design.
    public let journeyTitle: String?
    
    /// An icon image that can be used for displaying the task group.
    public let imageSource: RSDImageWrapper?

    /// Use an image directly rather than an image wrapper.
    public private(set) var image : UIImage? = nil
    
    /// A list of the activity identifiers associated with this task group.
    public let activityIdentifiers : [RSDIdentifier]
    
    /// An identifier that can be used to associate an `SBBScheduledActivity` instance
    /// with setting up a local reminder for when to perform a task.
    public let notificationIdentifier : RSDIdentifier?
    
    /// The schedule plan guid that can be used to map scheduled activities to
    /// the appropriate group in the case where more than one group may contain
    /// the same tasks.
    public let schedulePlanGuid : String?
    
    /// The activity guid map that can be used to map scheduled activities to
    /// the appropriate group in the case where more than one group may contain
    /// the same tasks **but** where the activities are not all grouped on the server
    /// using the same schedule. This guid can be found in the Bridge Study Manager UI
    /// by hovering your cursor over the copy icon and selecting "Copy GUID".
    public let activityGuidMap : [String : String]?
    
    private enum CodingKeys : String, CodingKey {
        case identifier, title, detail, journeyTitle, imageSource, activityIdentifiers, notificationIdentifier, schedulePlanGuid, activityGuidMap
    }
    
    /// Default initializer.
    public init(identifier: String,
                title: String?,
                journeyTitle: String?,
                image : UIImage?,
                activityIdentifiers : [RSDIdentifier],
                notificationIdentifier : RSDIdentifier?,
                schedulePlanGuid : String?,
                activityGuidMap : [String : String]?) {
        self.identifier = identifier
        self.title = title
        self.journeyTitle = journeyTitle
        self.image = image
        self.activityIdentifiers = activityIdentifiers
        self.notificationIdentifier = notificationIdentifier
        self.schedulePlanGuid = schedulePlanGuid
        self.detail = nil
        self.imageSource = nil
        self.activityGuidMap = activityGuidMap
    }
    
    /// Returns nil. This task group is intended to allow using a shared codable configuration
    /// and does not directly implement instantiating a task path.
    public func instantiateTaskViewModel(for taskInfo: RSDTaskInfo) -> RSDTaskViewModel? {
        return nil
    }
    
    /// Returns the configuration activity info objects mapped by activity identifier.
    public var tasks : [RSDTaskInfo] {
        let map = SBABridgeConfiguration.shared.activityInfoMap
        return self.activityIdentifiers.compactMap { map[$0.stringValue] }
    }
}

/// `SBAActivityInfoObject` is a `Decodable` implementation of a `SBAActivityInfo`.
///
/// - example:
/// ````
///    // Example JSON for a task that references a module id.
///    let json = """
///            {
///                "identifier": "foo",
///                "title": "Title",
///                "subtitle": "Subtitle",
///                "detail": "A detail about the object",
///                "imageSource": "fooImage",
///                "minuteDuration": 10,
///                "moduleId": "tapping"
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
///
///    // Example JSON for a task that references an embedded resource file.
///    let json = """
///            {
///                "identifier": "foo",
///                "title": "Title",
///                "subtitle": "Subtitle",
///                "detail": "A detail about the object",
///                "imageSource": "fooImage",
///                "minuteDuration": 10,
///                "resource": {   "resourceName" : "Foo_Task",
///                                "bundleIdentifier" : "org.example.Foo",
///                                "classType" : "FooTask"
///                            }
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
/// ````
public struct SBAActivityInfoObject : Decodable, SBAOptionalImageVendor, SBAActivityInfo {

    private enum CodingKeys : String, CodingKey {
        case identifier, title, subtitle, detail, _estimatedMinutes = "minuteDuration", imageSource, resource, moduleId
    }
    
    /// A short string that uniquely identifies the task.
    public let identifier : String
    
    /// The primary text to display for the task in a localized string.
    public var title : String?
    
    /// The subtitle text to display for the task in a localized string.
    public var subtitle : String?
    
    /// Additional detail text to display for the task. Generally, this would be displayed
    /// while the task is being fetched.
    public var detail : String?
    
    /// The estimated number of minutes that the task will take.
    public var estimatedMinutes: Int {
        return _estimatedMinutes ?? 0
    }
    private var _estimatedMinutes: Int?
    
    /// An optional resource for loading a task from a `SBBTaskReference` or `SBBSchemaReference`.
    public var resource: RSDResourceTransformerObject?
    
    /// An optional string that can be used to identify an active task module such as a
    /// "tapping" task or "walkAndBalance" task.
    public var moduleId: SBAModuleIdentifier?
    
    /// An icon image that can be used for displaying the task.
    public var imageSource : RSDImageWrapper?
    
    /// Use an image directly rather than an image wrapper.
    public var image : UIImage? = nil
    
    /// The schema info on this object is ignored.
    public var schemaInfo: RSDSchemaInfo? = nil
    
    /// The resource transformer points to the `resource`.
    public var resourceTransformer: RSDTaskTransformer? {
        return resource
    }
    
    public func copy(with identifier: String) -> SBAActivityInfoObject {
        var copy = SBAActivityInfoObject(identifier: identifier)
        copy.title = self.title
        copy.subtitle = self.subtitle
        copy.detail = self.detail
        copy._estimatedMinutes = self._estimatedMinutes
        copy.resource = self.resource
        copy.moduleId = self.moduleId
        copy.imageSource = self.imageSource
        copy.image = self.image
        copy.schemaInfo = self.schemaInfo
        return copy
    }
    
    public init(identifier : String) {
        self.identifier = identifier
    }
    
    /// Default initializer.
    public init(identifier : RSDIdentifier,
                title : String?,
                subtitle : String?,
                detail : String?,
                estimatedMinutes: Int?,
                iconImage : UIImage?,
                resource: RSDResourceTransformerObject?,
                moduleId: SBAModuleIdentifier?) {
        self.identifier = identifier.stringValue
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self._estimatedMinutes = estimatedMinutes
        self.image = iconImage
        self.resource = resource
        self.moduleId = moduleId
        self.imageSource = nil
    }
}

/// Convenience protocol to allow vending the image either from a `UIImage` *or* `RSDImageWrapper`.
public protocol SBAOptionalImageVendor {
    
    /// The image property is used if the  object is instantiated from within the app.
    var image : UIImage? { get }
    
    /// The image source is used if decoding the object.
    var imageSource : RSDImageWrapper? { get }
}

extension SBAOptionalImageVendor {

    /// Returns either the `iconImage` or `icon`
    public var imageVendor: RSDImageVendor? {
        return self.image ?? self.imageSource
    }
}

struct SBAProfileMappingObject : Decodable {
    private enum CodingKeys: String, CodingKey {
        case manager, dataSource
    }
    
    let manager: SBAProfileManager
    let dataSource: SBAProfileDataSource
    
    init(from decoder: Decoder) throws {
        guard let factory: SBAFactory = decoder.factory as? SBAFactory else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expecting the factory to be a subclass of `SBAFactory`")
            throw DecodingError.typeMismatch(SBAFactory.self, context)
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let managerDecoder = try container.superDecoder(forKey: .manager)
        self.manager = try factory.decodeProfileManager(from: managerDecoder)
        let dataSourceDecoder = try container.superDecoder(forKey: .dataSource)
        self.dataSource = try factory.decodeProfileDataSource(from: dataSourceDecoder)
    }
}
