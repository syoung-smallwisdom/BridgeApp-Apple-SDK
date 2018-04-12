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


/// `SBABridgeConfiguration` is used as a wrapper for combining task group and task info objects that are
/// singletons with the `SBBActivity` objects that contain a subset of the information used to implement
/// the `RSDTaskInfo` protocol.
open class SBABridgeConfiguration {
    
    /// The shared singleton.
    public static var shared = SBABridgeConfiguration()
    
    /// A mapping of the activity groups defined for this application.
    open var activityGroups : [SBAActivityGroup] = []
    
    /// A mapping of the activity infos defined for this application.
    open var activityInfoMap : [String : SBAActivityInfo] = [:]
    
    /// A mapping of schema references.
    open var schemaReferenceMap : [String : SBBSchemaReference] = [:]
    
    /// Set up BridgeSDK including loading any cached configurations.
    open func setupBridge(with factory: RSDFactory) {
        guard !_hasInitialized else { return }
        _hasInitialized = true
        
        // Insert this bundle into the list of localized bundles.
        Localization.insert(bundle: LocalizationBundle(Bundle(for: SBABridgeConfiguration.self)),
                            at: UInt(Localization.allBundles.count))
        
        // Set the factory to this one by default.
        RSDFactory.shared = factory
        
        // TODO: implement syoung 02/16/2018
    }
    private var _hasInitialized = false
    
    /// Convenience method for setting up the mappings used by this app to sort and filter schedules
    /// by task group and to extend the `SBAActivityReference` implementations.
    public func setupMapping(groups: [SBAActivityGroup]?, activityList: [SBAActivityInfo], schemaReferences: [SBBSchemaReference] = []) {
        self.activityGroups = groups ?? []
        self.activityInfoMap = activityList.rsd_filteredDictionary { ($0.identifier, $0) }
        self.schemaReferenceMap = schemaReferences.rsd_filteredDictionary { ($0.identifier, $0) }
    }
    
    /// Update the mapping by adding the given activity info.
    public func addMapping(with activityInfo: SBAActivityInfo) {
        self.activityInfoMap[activityInfo.identifier] = activityInfo
    }
    
    /// Update the mapping by adding the given activity group.
    public func addMapping(with activityGroup: SBAActivityGroup) {
        self.activityGroups.append(activityGroup)
    }
    
    /// Update the mapping by adding the given schema reference.
    public func addMapping(with schemaReference: SBBSchemaReference) {
        self.schemaReferenceMap[schemaReference.identifier] = schemaReference
    }
    
    /// Return the task transformer for the given activity reference.
    open func instantiateTaskTransformer(for activityReference: SBASingleActivityReference) -> RSDTaskTransformer! {
        // Exit early if this is a survey reference or if the activity info uses an embedded resource.
        if let surveyReference = activityReference as? SBBSurveyReference {
            return SBASurveyLoader(surveyReference: surveyReference)
        } else if let resourceTransformer = activityReference.activityInfo?.resource {
            return resourceTransformer
        }

        // Default drop-through is to look for a moduleId
        guard let moduleId = activityReference.activityInfo?.moduleId,
            let transformer = self.instantiateTaskTransformer(for: moduleId)
        else {
            assertionFailure("Failed to get a valid task transformer for this task. Missing required override.")
            return RSDResourceTransformerObject(resourceName: "NULL")
        }
        return transformer
    }
    
    /// Override this method to return a task transformer for a given task. This method is intended
    /// to be able to run active tasks such as "tapping" or "tremor" where the task module is described
    /// in another github repository.
    open func instantiateTaskTransformer(for moduleId: SBAModuleIdentifier) -> RSDTaskTransformer! {
        return moduleId.taskTransformer()
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
}

extension SBAActivityGroup {
    
    /// Returns the configuration activity info objects mapped by activity identifier.
    public var tasks : [RSDTaskInfo] {
        let map = SBABridgeConfiguration.shared.activityInfoMap
        return self.activityIdentifiers.flatMap { map[$0.stringValue] }
    }
}

/// Extend the task info protocol to include optional pointers for use by an `SBBTaskReference`
/// as the source of a task transformer.
public protocol SBAActivityInfo : RSDTaskInfo {

    /// An optional resource for loading a task from a `SBBTaskReference` or `SBBSchemaReference`
    var resource: RSDResourceTransformerObject? { get }
    
    /// An optional string that can be used to identify an active task module such as a
    /// "tapping" task or "walkAndBalance" task.
    var moduleId: SBAModuleIdentifier?  { get }
}

// MARK: Codable implementation of the mapping objects.

/// `SBAActivityMappingObject` is a decodable instance of an activity mapping
/// that can be used to decode a Plist or JSON dictionary.
struct SBAActivityMappingObject : Decodable {
    let groups : [SBAActivityGroupObject]?
    let activityList : [SBAActivityInfoObject]
}

/// `SBAActivityGroupObject` is a `Decodable` implementation of a `SBAActivityGroup`.
///
/// - example:
/// ````
///    // Example activity group.
///    let json = """
///            {
///                "identifier": "foo",
///                "title": "Title",
///                "journeyTitle": "Journey title",
///                "detail": "A detail about the object",
///                "imageSource": "fooImage",
///                "activityIdentifiers": ["taskA", "taskB", "taskC"],
///                "notificationIdentifier": "scheduleFoo",
///                "schedulePlanGuid": "abcdef12-3456-7890"
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
    
    private enum CodingKeys : String, CodingKey {
        case identifier, title, detail, journeyTitle, imageSource, activityIdentifiers, notificationIdentifier, schedulePlanGuid
    }
    
    /// Default initializer.
    public init(identifier: String,
                title: String?,
                journeyTitle: String?,
                image : UIImage?,
                activityIdentifiers : [RSDIdentifier],
                notificationIdentifier : RSDIdentifier?,
                schedulePlanGuid : String?) {
        self.identifier = identifier
        self.title = title
        self.journeyTitle = journeyTitle
        self.image = image
        self.activityIdentifiers = activityIdentifiers
        self.notificationIdentifier = notificationIdentifier
        self.schedulePlanGuid = schedulePlanGuid
        self.detail = nil
        self.imageSource = nil
    }
    
    /// Returns nil. This task group is intended to allow using a shared codable configuration
    /// and does not directly implement instantiating a task path.
    public func instantiateTaskPath(for taskInfo: RSDTaskInfo) -> RSDTaskPath? {
        return nil
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
