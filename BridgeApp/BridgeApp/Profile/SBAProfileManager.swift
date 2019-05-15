//
//  SBAProfileManager.swift
//  BridgeApp
//
//  Copyright © 2017-2018 Sage Bionetworks. All rights reserved.
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

/// The type of a profile manager. This is used to decode the manager in a factory.
public struct SBAProfileManagerType : RawRepresentable, Codable {
    public typealias RawValue = String
    
    public private(set) var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Defaults to creating a `SBAProfileManagerObject`.
    public static let profileManager: SBAProfileManagerType = "profileManager"
    
    /// List of all the standard types.
    public static func allStandardTypes() -> [SBAProfileManagerType] {
        return [.profileManager]
    }
}

extension SBAProfileManagerType : Equatable {
    public static func ==(lhs: SBAProfileManagerType, rhs: SBAProfileManagerType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func ==(lhs: String, rhs: SBAProfileManagerType) -> Bool {
        return lhs == rhs.rawValue
    }
    public static func ==(lhs: SBAProfileManagerType, rhs: String) -> Bool {
        return lhs.rawValue == rhs
    }
}

extension SBAProfileManagerType : Hashable {
    public var hashValue : Int {
        return self.rawValue.hashValue
    }
}

extension SBAProfileManagerType : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension SBAProfileManagerType {
    static func allCodingKeys() -> [String] {
        return allStandardTypes().map{ $0.rawValue }
    }
}

/// Profile manager error types.
public enum SBAProfileManagerErrorType {
    case unknownProfileKey
}

/// Profile manager error object.
public class SBAProfileManagerError: NSObject, Error {
    var errorType: SBAProfileManagerErrorType
    var profileKey: String
    
    public init(errorType: SBAProfileManagerErrorType, profileKey key: String) {
        self.errorType = errorType
        self.profileKey = key
        super.init()
    }
}

/// A protocol for defining a Profile Manager.
public protocol SBAProfileManager {

    /// Get a list of the profile keys defined for this app.
    /// - returns: A String array of profile item keys.
    func profileKeys() -> [String]
    
    /// Get the profile items defined for this app.
    /// - returns: A Dictionary of SBAProfileItem objects by profileKey.
    func profileItems() -> [String: SBAProfileItem]
    
    /// Get the value of a profile item by its profileKey.
    /// - returns: The value (optional) of the specified item.
    func value(forProfileKey: String) -> Any?
    
    /// Set the value of the profile item by its profileKey.
    /// - throws: Throws an error if there is no profile item with the specified profileKey.
    /// - parameter value: The new value to set for the profile item.
    /// - parameter key: The profileKey of the item whose value is to be set.
    func setValue(_ value: Any?, forProfileKey key: String) throws
    
    /// Special-case access of the data groups via the profile manager.
    func getDataGroups() -> Set<String>

}

/// Concrete implementation of the SBAProfileManager protocol.
open class SBAProfileManagerObject: SBAScheduleManager, SBAProfileManager, Decodable {
    static let groupIdentifier: String = "Profile Activity Group"
    
    /// Return the shared instance of the Profile Manager from the shared Bridge configuration.
    public static var shared: SBAProfileManager {
        return SBABridgeConfiguration.shared.profileManager ?? SBAProfileManagerObject()
    }

    public static let userDefaults = BridgeSDK.sharedUserDefaults()

    private var items: [SBAProfileItem] = []
    lazy private var itemsKeys: [String] = {
        return self.items.map({ $0.profileKey })
    }()
    
    lazy private var itemsMap: [String: SBAProfileItem] = {
        var allItems: [String: SBAProfileItem] = [:]
        for item in self.items {
            allItems[item.profileKey] = item
        }
        return allItems
    }()
    
    /// Is the account signed in?
    private var isAuthenticated: Bool = false
    

   
    // MARK: Internal methods
    // TODO: emm 2019-05-03 Deal with this (or remove? is it obsolete?) for mPower 2.1
//    func uploadDemographicData(_ schemas: Set<String>) {
//        let demographicItems = self.items.filter({ return $0.demographicSchema != nil && schemas.contains($0.demographicSchema!) })
//        guard demographicItems.count > 0 else { return }
//
//        for schemaIdentifier in schemas {
//            let itemsForSchema = demographicItems.filter({ $0.demographicSchema! == schemaIdentifier })
//            let archiveFilename = schemaIdentifier
//            let archive = SBBDataArchive(reference: schemaIdentifier, jsonValidationMapping: nil)
//
//            if let schemaRevision = SBABridgeConfiguration.shared.schemaInfo(for: schemaIdentifier)?.schemaVersion {
//                archive.setArchiveInfoObject(schemaRevision, forKey: "schemaRevision")
//            }
//
//            let demographics = self.demographics(with: itemsForSchema)
//            archive.insertDictionary(intoArchive: demographics, filename: archiveFilename, createdOn: Date())
//            do {
//                try archive.complete()
//                archive.encryptAndUploadArchive()
//            }
//            catch {}
//        }
//    }
//
//    // overrideable for testing
//    func demographics(with demographicItems: [SBAProfileItem]) -> [String: Any] {
//        var demographics: [String: Any] = [:]
//        for item in demographicItems {
//            demographics[item.demographicKey] = item.demographicJsonValue ?? NSNull()
//        }
//        return demographics
//    }
    
    // MARK: SBAScheduleManager
    
    /// Set up to manage reports for all our report-based profile items.
    override open func reportQueries() -> [SBAReportManager.ReportQuery] {
        let reportIdentifiers: [RSDIdentifier] = self.items.compactMap {
            guard $0.type == .report else { return nil }
            return RSDIdentifier(rawValue: $0.sourceKey)
        }
        
        let queries = reportIdentifiers.map({
            return ReportQuery(reportKey: $0, queryType: .mostRecent, dateRange: nil)
        })
        
        return queries
    }
    
    // MARK: SBAProfileManagerProtocol
    
    open func getDataGroups() -> Set<String> {
        return self.value(forProfileKey: "participantDataGroups") as? Set<String> ?? Set<String>()
    }
    
    /// - returns: A list of all the profile keys known to the profile manager.
    public func profileKeys() -> [String] {
        return itemsKeys
    }
    
    /// - returns: A map of all the profile items by profileKey.
    public func profileItems() -> [String: SBAProfileItem] {
        return itemsMap
    }
    
    /// Get the value of a profile item by its profileKey.
    /// - parameter key: The profileKey for the profile item to be retrieved.
    /// - returns: The value of the profile item, as stored in whatever underlying storage it uses.
    public func value(forProfileKey key: String) -> Any? {
        guard let item = self.itemsMap[key] else { return nil }
        
        return item.value
    }
    
    /// Set (or clear) a new value on a profile item by profileKey.
    /// - parameter value: The new value to set.
    /// - parameter key: The profileKey of the profile item on which to set the new value.
    public func setValue(_ value: Any?, forProfileKey key: String) throws {
        guard var item = self.itemsMap[key] else {
            throw SBAProfileManagerError(errorType: .unknownProfileKey, profileKey: key)
        }
        
        item.value = value
    }
    
    // MARK: Codable
    private enum CodingKeys: String, CodingKey {
        case items
    }
    
    private enum TypeKeys: String, CodingKey {
        case type
    }
    
    /// Get a string that will identify the type of object to instantiate for the given decoder.
    ///
    /// By default, this will look in the container for the decoder for a key/value pair where
    /// the key == "type" and the value is a `String`.
    ///
    /// - parameter decoder: The decoder to inspect.
    /// - returns: The string representing this class type (if found).
    /// - throws: `DecodingError` if the type name cannot be decoded.
    func typeName(from decoder:Decoder) throws -> String {
        let container = try decoder.container(keyedBy: TypeKeys.self)
        return try container.decode(String.self, forKey: .type)
    }
    
    override public init() {
        super.init()
    }

    public required init(from decoder: Decoder) throws {
        super.init()
        
        // Add an observer for changes to the login session.
        NotificationCenter.default.addObserver(forName: .sbbUserSessionUpdated, object: nil, queue: OperationQueue.main) { (notification) in
            guard let info = notification.userInfo?[kSBBUserSessionInfoKey] as? SBBUserSessionInfo else {
                fatalError("Expecting a non-nil user session info")
            }
            let authenticated = info.authenticated?.boolValue ?? false
            let authStateChanged = (authenticated && !self.isAuthenticated)
            self.isAuthenticated = authenticated
            if authStateChanged {
                self.reloadData()
            }
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.items) {
            var items: [SBAProfileItem] = self.items
            var schemas: [RSDIdentifier] = []
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .items)
            while !nestedContainer.isAtEnd {
                let itemDecoder = try nestedContainer.superDecoder()
                let itemTypeName = try typeName(from: itemDecoder)
                let itemType = SBAProfileItemType(rawValue: itemTypeName)
                if let item = try decodeItem(from: itemDecoder, with: itemType) {
                    items.append(item)
                    if let schema = item.demographicSchema {
                        schemas.append(RSDIdentifier(rawValue: schema))
                    }
                }
            }
            self.items = items
            self.loadReports()
            
            guard schemas.count > 0 else { return }
            
            let profileActivityGroup = SBAActivityGroupObject(identifier: SBAProfileManagerObject.groupIdentifier, title: nil, journeyTitle: nil, image: nil, activityIdentifiers: schemas, notificationIdentifier: nil, schedulePlanGuid: nil, activityGuidMap: nil)
            self.activityGroup = profileActivityGroup
            SBABridgeConfiguration.shared.addMapping(with: profileActivityGroup)
        }
    }

    /// Decode the profile item from this decoder.
    ///
    /// - parameters:
    ///     - type:        The `ProfileItemType` to instantiate.
    ///     - decoder:     The decoder to use to instatiate the object.
    /// - returns: The profile item (if any) created from this decoder.
    /// - throws: `DecodingError` if the object cannot be decoded.
    open func decodeItem(from decoder: Decoder, with type: SBAProfileItemType) throws -> SBAProfileItem? {
        
        switch (type) {
        case .report:
            return try SBAReportProfileItem(from: decoder)
/* TODO: emm 2018-08-19 deal with this for mPower 2 2.1
        case .userDefaults:
            return try SBAUserDefaultsProfileItem(from: decoder)
        case .keychain:
            return try SBAKeychainProfileItem(from: decoder)
        case .participant:
            return try SBAStudyParticipantProfileItem(from: decoder)
        case .participantCustomAttributes:
            return try SBAStudyParticipantCustomAttributesProfileItem(from: decoder)
        case .clientData:
            return try SBAClientDataProfileItem(from: decoder)
        case .fullName:
            return try SBAFullNameProfileItem(from: decoder)
        case .birthDate:
            return try SBABirthDateProfileItem(from: decoder)
 */
        default:
            assertionFailure("Attempt to decode profile item of unknown type \(type.rawValue)")
            return nil
        }
    }
    
    /// Posts a "value updated" notification that includes all the profile items. Gets called on initialization
    /// and on updating/reloading reports.
    private func postValuesUpdatedNotification() {
        var updatedItems: [String: Any?] = [:]
        for key in self.profileKeys() {
            updatedItems[key] = self.value(forProfileKey: key)
        }
        
        if updatedItems.count > 0 {
            NotificationCenter.default.post(name: .SBAProfileItemValueUpdated, object: self, userInfo: [SBAProfileItemUpdatedItemsKey: updatedItems])
        }
    }

    /// Called when all the reports are finished loading.
    override open func didFinishFetchingReports() {
        self.postValuesUpdatedNotification()
    }
}

