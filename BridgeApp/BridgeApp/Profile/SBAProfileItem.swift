//
//  SBAProfileItem.swift
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
import HealthKit
import BridgeSDK

public protocol SBAProfileItem: Decodable {
    /// profileKey is used to access a specific profile item, and so must be unique across all SBAProfileItems
    /// within an app.
    var profileKey: String { get }
    
    /// sourceKey is the profile item's key within its internal data storage. By default it will be the
    /// same as profileKey, but can be different if needed (e.g. two different profile items happen to map to
    /// the same key in different storage types).
    var sourceKey: String { get }
    
    /// demographicSchema is an optional schema identifier to mark a profile item as being part of the indicated
    /// demographic data upload schema.
    var demographicSchema: String? { get }
    
    /// demographicKey is the profile item's key in the demographic data upload schema. By default it will
    /// be the same as profileKey, but can be different if needed.
    var demographicKey: String { get }
    
    /// itemType specifies what type to store the profileItem's value as. Defaults to String if not otherwise specified.
    var itemType: RSDFormDataType { get }
    
    /// The value property is used to get and set the profile item's value in whatever internal data
    /// storage is used by the implementing class.
    var value: Any? { get set }
    
    /// jsonValue is used to get and set the profile item's value directly from appropriate JSON.
    var jsonValue: RSDJSONSerializable? { get set }
    
    /// demographicJsonValue is used when formatting the item as demographic data for upload to Bridge.
    /// By default it will fall through to the getter for the jsonValue property, but can be different
    /// if needed.
    var demographicJsonValue: RSDJSONSerializable? { get }
    
    /// Is the value read-only?
    var readonly: Bool { get }
    
/* TODO: emm 2018-08-24 do we maybe still need to support this for updating the demographic survey from the Profile tab?
    /// Some of the stored value types have a unit associated with them that is used to
    /// build the model object into an `HKQuantity`.
    var unit: HKUnit? { get }
 */
    
    /// The class type to which to deserialize this profile item.
    var type: SBAProfileItemType { get }
    
    /// This function should fetch the value associated with sourceKey from the internal data storage for the profile type being implemented.
    func storedValue(forKey key: String) -> Any?
    
    /// This function should set or update the value associated with sourceKey in the internal data storage for the profile type being implemented.
    func setStoredValue(_ newValue: Any?)
    
}

// internal protocol to share common implementation details for properties with default fallback values
fileprivate protocol SBAProfileItemInternal: SBAProfileItem {
    // backing store for non-default sourceKey value
    var _sourceKey: String? { get set }
    
    // backing store for non-default demographicKey value
    var _demographicKey: String? { get set }
    
    // backing store for non-default readonly value
    var _readonly: Bool? { get set }
}

// extension where common implementation details for properties with default fallback values are implemented
extension SBAProfileItemInternal {
    public var sourceKey: String {
        get {
            return self._sourceKey ?? self.profileKey
        }
        set {
            self._sourceKey = newValue
        }
    }
    
    public var demographicKey: String {
        get {
            return self._demographicKey ?? self.profileKey
        }
        set {
            self._demographicKey = newValue
        }
    }
    
    public var readonly: Bool {
        get {
            return self._readonly ?? false
        }
        set {
            self._readonly = newValue
        }
    }
}

extension Notification.Name {
    /// Notification name posted by SBAProfileItem for an item when updating its value, and by SBAProfileManager
    /// for all its items when it finishes loading or fetching reports.
    public static let SBAProfileItemValueUpdated: NSNotification.Name = NSNotification.Name(rawValue: "SBAProfileItemValueUpdated")
}

/// This is the key into the SBAProfileItemValueUpdated notification's userInfo for the mapping of profile keys to updated values.
public let SBAProfileItemUpdatedItemsKey: String = "SBAProfileItemUpdatedItems"

extension SBAProfileItem {
    /// The value property is used to get and set the profile item's value in whatever internal data
    /// storage is used by the implementing type. Setting the value on a non-readonly profile item causes
    /// a notification to be posted.
    public var value: Any? {
        get {
            return self.storedValue(forKey: sourceKey)
        }
        
        set {
            guard !readonly else { return }
            self.setStoredValue(newValue)
            let updatedItems: [String: Any?] = [self.profileKey: newValue]
            NotificationCenter.default.post(name: .SBAProfileItemValueUpdated, object: self, userInfo: [SBAProfileItemUpdatedItemsKey: updatedItems])
        }
    }
    
    /// jsonValue is used to get and set the profile item's value directly from appropriate JSON.
    public var jsonValue: RSDJSONSerializable? {
        get {
            return self.commonJsonValueGetter()
        }
        
        set {
            commonJsonValueSetter(jsonVal: newValue)
        }
    }
    
    /// demographicJsonValue is used when formatting the item as demographic data for upload to Bridge.
    /// By default it will fall through to the getter for the jsonValue property, but can be different
    /// if needed.
    public var demographicJsonValue: RSDJSONSerializable? {
        return self.commonDemographicJsonValue()
    }
    
    func commonJsonValueGetter() -> RSDJSONSerializable? {
        return commonItemTypeToJson(val: self.value)
    }
    
    public func commonItemTypeToJson(val: Any?) -> RSDJSONSerializable? {
        guard val != nil else { return NSNull() }
        switch self.itemType.baseType {
        case .string:
            return val as? String
            
        case .integer:
            return val as? NSNumber
            
        case .decimal:
            return val as? NSNumber

        case .boolean:
            return val as? NSNumber
            
        case .date:
            return (val as? NSDate)?.iso8601String()
            
        default:
            return nil
        }
    }
    
    mutating func commonJsonValueSetter(jsonVal: RSDJSONSerializable?) {
        guard let jsonValue = jsonVal else {
            self.value = nil
            return
        }
        
        guard let itemValue = commonJsonToItemType(jsonVal: jsonValue) else { return }
        self.value = itemValue
    }

    public func commonJsonToItemType(jsonVal: RSDJSONSerializable?) -> Any? {
        guard let jsonValue = jsonVal else {
            return nil
        }
        
        var itemValue: Any? = nil
        switch self.itemType.baseType {
        case .string:
            itemValue = jsonValue as? String ?? String(describing: jsonValue)
            
        case .integer:
            guard let val = jsonValue as? Int else { return nil }
            itemValue = val
            
        case .decimal:
            guard let val = jsonValue as? Decimal else { return nil }
            itemValue = val
            
        case .boolean:
            guard let val = jsonValue as? Bool else { return nil }
            itemValue = val
            
        case .date:
            guard let stringVal = jsonValue as? String,
                    let dateVal = NSDate(iso8601String: stringVal)
                else { return nil }
            itemValue = dateVal

        default:
            break
        }
        
        return itemValue
    }
    
    func commonMapObject(with dictionary: [String : RSDJSONSerializable]) -> Any? {
        guard let type = dictionary["type"] as? String,
                let clazz = NSClassFromString(type) as? (NSObject & Decodable).Type
            else {
                return nil
        }
        let decoder = RSDFactory.shared.createJSONDecoder()
        
        do {
            let decodingHelper = try decoder.decode(DecodingHelper.self, from: dictionary as SBBJSONValue)
            return try decodingHelper.decode(to: clazz) as! NSObject & Decodable
        } catch let err {
            debugPrint("Failed to decode an object purported to be of type \(type): \(err)")
        }

        return nil
    }
    
    func commonDemographicJsonValue() -> RSDJSONSerializable? {
        guard let jsonVal = self.commonJsonValueGetter() else { return nil }
/* TODO: emm 2018-08-24 do we maybe still need to support this for updating the demographic survey from the Profile tab?
        if self.itemType == .hkBiologicalSex {
            return (self.value as? HKBiologicalSex)?.demographicDataValue
        }
 */
        
        return jsonVal
    }
    
    func commonCheckTypeCompatible(newValue: Any?) -> Bool {
        guard newValue != nil else { return true }
        
        switch self.itemType.baseType {
        case .string:
            return true // anything can be cast to a string
            
        case .integer:
            return newValue as? NSNumber != nil
            
        case .decimal:
            return newValue as? NSNumber != nil
            
        case .boolean:
            return newValue as? NSNumber != nil
            
        case .date:
            return newValue as? NSDate != nil
            
        default:
            return true   // Any extended type isn't included in the common validation
        }
    }
    
/* TODO: emm 2018-08-24 do we maybe still need to support this for updating the demographic survey from the Profile tab?
    func commonDefaultUnit() -> HKUnit {
        return HKUnit.count()
    }
 */
}

/* TODO: emm 2018-08-24 do we maybe still need to support this for updating the demographic survey from the Profile tab?
extension HKBiologicalSex {
    public var demographicDataValue: NSString? {
        switch (self) {
        case .female:
            return "Female"
        case .male:
            return "Male"
        case .other:
            return "Other"
        default:
            return nil
        }
    }
}
 */

/// SBAReportProfileItem allows storing and retrieving profile item values to/from Bridge Participant Reports.
/// For this type of profile item, the sourceKey (which defaults to the profileKey if not specifically set) is
/// interpreted as the report identifier. If the clientDataIsItem flag is not set, then the demographicKey
/// (which, likewise, defaults to the profileKey if not specifically set) is interpreted as the item's key
/// in the report's clientData. If the flag is set, the report's clientData value is used directly.
///
/// A common scenario for a study would be to have a demographic survey which is administered once after the
/// participant signs up and consents. Often (always in e.g. Canada, where required by law), the app/study design
/// would need some way to allow the participant to change those answers later. One way to do this is to create
/// an editable profile item for each question/answer in the demographic survey. In this scenario, for each of these
/// items you would set the demographicSchema to the survey identifier, set the source key to the survey identifier
/// as well, and set the demographicKey to the identifier of the survey question corresponding to the profile item.
public struct SBAReportProfileItem: SBAProfileItemInternal {
    private enum CodingKeys: String, CodingKey {
        case profileKey, _sourceKey = "sourceKey", _demographicKey = "demographicKey", demographicSchema,
        _clientDataIsItem = "clientDataIsItem", itemType, _readonly = "readonly", type
    }

    fileprivate var _sourceKey: String?
    
    fileprivate var _demographicKey: String?
    
    fileprivate var _readonly: Bool?
    
    /// profileKey is used to access a specific profile item, and so must be unique across all SBAProfileItems
    /// within an app.
    public var profileKey: String
    
    /// demographicSchema is an optional schema identifier to mark a profile item as being part of the indicated
    /// demographic data upload schema.
    public var demographicSchema: String?
    
    /// If clientDataIsItem is true, the report's clientData field is assumed to contain the item value itself.
    ///
    /// If clientDataIsItem is false, the report's clientData field is assumed to be a dictionary in which
    /// the item value is stored and retrieved via the demographicKey.
    ///
    /// The default value is false.
    public var _clientDataIsItem: Bool?
    public var clientDataIsItem: Bool {
        get {
            return self._clientDataIsItem ?? false
        }
        set {
            self._clientDataIsItem = newValue
        }
    }

    /// itemType specifies what type to store the profileItem's value as. Defaults to String if not otherwise specified.
    public var itemType: RSDFormDataType
    
    /// The class type to which to deserialize this profile item.
    public var type: SBAProfileItemType
    
    /// The report manager to use when storing and retrieving the item's value.
    ///
    /// By default, the profile manager that decodes this item will point this property at itself. If you point it at
    /// a different report manager, you will need to ensure that report manager is set up to handle the relevant report.
    public weak var reportManager: SBAReportManager?
    
    public func storedValue(forKey key: String) -> Any? {
        guard let reportManager = self.reportManager,
                let clientData = reportManager.reports.first(where: { $0.reportKey == RSDIdentifier(rawValue: key) })?.clientData
            else {
                return nil
        }
        var json = clientData as? RSDJSONSerializable
        if !self.clientDataIsItem {
            guard let dict = clientData as? [String : RSDJSONSerializable],
                    let propJson = dict[self.demographicKey]
                else {
                    return nil
            }
            json = propJson
        }
        
        return self.commonJsonToItemType(jsonVal: json)
    }
    
    public func setStoredValue(_ newValue: Any?) {
        guard !self.readonly, let reportManager = self.reportManager else { return }
        var clientData : SBBJSONValue = NSNull()
        if self.clientDataIsItem {
            clientData = self.commonItemTypeToJson(val: newValue) as? SBBJSONValue ?? NSNull()
        } else {
            var clientJsonDict = reportManager.reports.first(where: { $0.reportKey == RSDIdentifier(rawValue: self.sourceKey) })?.clientData as? Dictionary<String, RSDJSONSerializable> ?? Dictionary<String, RSDJSONSerializable>()
            clientJsonDict[self.demographicKey] = self.commonItemTypeToJson(val: newValue)
            clientData = clientJsonDict as SBBJSONValue
        }
        let report = SBAReport(reportKey: RSDIdentifier(rawValue: self.sourceKey), date: Date(), clientData: clientData)
        reportManager.saveReport(report)
    }
    
}

// The valid keypaths into SBBStudyParticipant for SBAStudyParticipantProfileItems. This will be used to access the
// values via their keypaths.
fileprivate struct SBAParticipantKeyPath : RawRepresentable, Codable {
    public typealias RawValue = String
    
    public private(set) var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public static let email: SBAParticipantKeyPath = "email"
    
    public static let externalId: SBAParticipantKeyPath = "externalId"
    
    public static let firstName: SBAParticipantKeyPath = "firstName"
    
    public static let lastName: SBAParticipantKeyPath = "lastName"
    
    public static let phoneNumber: SBAParticipantKeyPath = "phoneNumber"
    
    /// List of all the allowed keypaths.
    public static func allowedKeypaths() -> [SBAParticipantKeyPath] {
        return [.email, .externalId, .firstName, .lastName, .phoneNumber]
    }
}

extension SBAParticipantKeyPath : Equatable {
    public static func ==(lhs: SBAParticipantKeyPath, rhs: SBAParticipantKeyPath) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func ==(lhs: String, rhs: SBAParticipantKeyPath) -> Bool {
        return lhs == rhs.rawValue
    }
    public static func ==(lhs: SBAParticipantKeyPath, rhs: String) -> Bool {
        return lhs.rawValue == rhs
    }
}

extension SBAParticipantKeyPath : Hashable {
    public var hashValue : Int {
        return self.rawValue.hashValue
    }
}

extension SBAParticipantKeyPath : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension SBAParticipantKeyPath {
    static func allCodingKeys() -> [String] {
        return allowedKeypaths().map{ $0.rawValue }
    }
}


/// SBAStudyParticipantProfileItem allows storing and retrieving profile item values to/from the SBBStudyParticipant object.
/// For this type of profile item, the sourceKey (which defaults to the profileKey if not specifically set) is
/// interpreted as the key path into the SBBStudyParticipant.
public struct SBAStudyParticipantProfileItem: SBAProfileItemInternal {
    private enum CodingKeys: String, CodingKey {
        case profileKey, _sourceKey = "sourceKey", itemType, _readonly = "readonly", type
    }
    
    fileprivate var _sourceKey: String?
    
    fileprivate var _demographicKey: String?

    public var profileKey: String
    
    public var demographicSchema: String?
    
    /// itemType specifies what type to store the profileItem's value as. Defaults to String if not otherwise specified.
    public var itemType: RSDFormDataType
    
    /// Is the value read-only?
    /// Note that if the underlying SBBStudyParticipant field is effectively read-only, this
    /// var will be true regardless of any "readonly" key specified in the item's json.
    fileprivate var _readonly: Bool?
    public var readonly: Bool {
        var itemIsPotentiallyWritable: Bool
        let path = SBAParticipantKeyPath(rawValue: self.sourceKey)
        switch path {
        case .firstName:
            itemIsPotentiallyWritable = true
        case .lastName:
            itemIsPotentiallyWritable = true
        default:
            itemIsPotentiallyWritable = false
        }
        
        // If the item isn't even *potentially* writable, ignore the readonly flag from json if any.
        // If it is, then default to false (not readonly).
        return itemIsPotentiallyWritable ? (self._readonly ?? false) : true
    }
    
    /// The class type to which to deserialize this profile item.
    public var type: SBAProfileItemType
    
    public func storedValue(forKey key: String) -> Any? {
        guard let participant = SBAParticipantManager.shared.studyParticipant else { return nil }
        return participant.value(forKeyPath: self.sourceKey)
    }
    
    public func setStoredValue(_ newValue: Any?) {
        guard !self.readonly, let participant = SBAParticipantManager.shared.studyParticipant else { return }
        participant.setValue(newValue, forKey: self.sourceKey)
        BridgeSDK.participantManager.updateParticipantRecord(withRecord: participant) { (_, _) in
        }
    }
    
}

/// SBAStudyParticipantClientDataProfileItem allows storing and retrieving profile item values to/from the
/// SBBStudyParticipant object's clientData field. For this type of profile item, the sourceKey (which defaults
/// to the profileKey if not specifically set) is interpreted as the key into SBBStudyParticipant.clientData.
/// If a fallbackKeyPath is set, and the item currently does not have a value specified in the clientData,
/// the value will be retrieved from the SBBStudyParticipant object at the specified key path. New values
/// are always set in the clientData and do not affect the value at the fallbackKeyPath.
public struct SBAStudyParticipantClientDataProfileItem: SBAProfileItemInternal {
    private enum CodingKeys: String, CodingKey {
        case profileKey, _sourceKey = "sourceKey", _fallbackKeyPath = "fallbackKeyPath", itemType, _readonly = "readonly", type
    }

    fileprivate var _sourceKey: String?
    
    fileprivate var _demographicKey: String?
    
    fileprivate var _fallbackKeyPath: String?
    public var fallbackKeyPath: String? {
        get {
            return _fallbackKeyPath
        }
        set {
            guard let newValue = newValue
                else {
                    _fallbackKeyPath = nil
                    return
            }
            guard SBAParticipantKeyPath.allCodingKeys().contains(newValue)
                else {
                    assertionFailure("Attempting to set fallbackKeyPath to an invalid key path: \(String(describing: newValue))")
                    return
            }
            _fallbackKeyPath = newValue
        }
    }
    
    fileprivate var _readonly: Bool?
    
    /// profileKey is used to access a specific profile item, and so must be unique across all SBAProfileItems
    /// within an app.
    public var profileKey: String
    
    public var demographicSchema: String?
    
    /// itemType specifies what type to store the profileItem's value as. Defaults to String if not otherwise specified.
    public var itemType: RSDFormDataType
    
    /// The class type to which to deserialize this profile item.
    public var type: SBAProfileItemType
    
    public func storedValue(forKey key: String) -> Any? {
        guard let participant = SBAParticipantManager.shared.studyParticipant else { return nil }
        var dict = participant.clientData as? [String : RSDJSONSerializable] ?? [:]
        guard let json = dict[self.sourceKey]
            else {
                guard let keyPath = self.fallbackKeyPath else { return nil }
                return participant.value(forKeyPath: keyPath)
        }
        return self.commonJsonToItemType(jsonVal: json)
    }
    
    public func setStoredValue(_ newValue: Any?) {
        guard !self.readonly, let participant = SBAParticipantManager.shared.studyParticipant else { return }
        var dict = participant.clientData as? [String : RSDJSONSerializable] ?? [:]
        dict[self.sourceKey] = self.commonItemTypeToJson(val: newValue)
        participant.clientData = dict as SBBJSONValue
        BridgeSDK.participantManager.updateParticipantRecord(withRecord: participant) { (_, _) in
        }
    }
}


/* TODO: emm 2018-08-19 deal with this for mPower 2 2.1
open class SBAProfileItemBase: SBAProfileItem, Decodable {
    
    /// The value property is used to get and set the profile item's value in whatever internal data
    /// storage is used by the implementing class.
    open var value: Any? {
        get {
            // Look at the sourceKey, if not found then fall back to the fallback key and check that
            let value = storedValue(forKey: sourceKey)
            if value == nil, let fallback = fallbackKey {
                return storedValue(forKey: fallback)
            }
            else {
                return value
            }
        }
        
        set {
            guard !readonly else { return }
            setStoredValue(newValue)
        }
    }

    public let profileKey: String
    
    public let sourceKey: String
    
    public let demographicSchema: String?
    
    public let demographicKey: String
    
    public let fallbackKey: String?
    
    public let itemType: SBAProfileTypeIdentifier
    
    open var jsonValue: SBBJSONValue? {
        get {
            return self.commonJsonValueGetter()
        }
        
        set {
            commonJsonValueSetter(value: newValue)
        }
    }
    
    open var demographicJsonValue: SBBJSONValue? {
        return self.commonDemographicJsonValue()
    }
    
    public let readonly: Bool
    
    public let unit: HKUnit?
    
    public let type: SBAProfileItemType
    
    open func storedValue(forKey key: String) -> Any? {
        return _value
    }
    
    open func setStoredValue(_ newValue: Any?) {
        _value = newValue
    }
    
    fileprivate var _value: Any?
    
    // MARK: Decodable
    private enum CodingKeys: String, CodingKey {
        case profileKey, sourceKey, demographicSchema, demographicKey,
            fallbackKey, itemType, readonly, unit, valueClassType, type
    }
    
    /// Initialize from a `Decoder`. This decoding method will use the `RSDFactory` instance associated
    /// with the decoder to decode the `profileItem`.
    ///
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - throws: `DecodingError`
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedProfileKey = try container.decode(String.self, forKey: .profileKey)
        self.profileKey = decodedProfileKey
        self.sourceKey = try container.decodeIfPresent(String.self, forKey: .sourceKey) ?? decodedProfileKey
        self.demographicSchema = try container.decodeIfPresent(String.self, forKey: .demographicSchema)
        self.demographicKey = try container.decodeIfPresent(String.self, forKey: .demographicKey) ?? decodedProfileKey
        self.fallbackKey = try container.decodeIfPresent(String.self, forKey: .fallbackKey)
        self.itemType = try SBAProfileTypeIdentifier(rawValue: container.decodeIfPresent(String.self, forKey: .itemType) ?? SBAProfileTypeIdentifier.string.rawValue)
        self.readonly = try container.decodeIfPresent(Bool.self, forKey: .readonly) ?? false
        if let unitString = try container.decodeIfPresent(String.self, forKey: .unit) {
            self.unit = HKUnit(from: unitString)
        } else {
            self.unit = nil
        }
        self.type = try container.decode(SBAProfileItemType.self, forKey: .type)
    }
}

public protocol PlistValue {
    // empty, just used to mark types as suitable for use in plists (and user defaults)
}

public protocol JSONValue: PlistValue {
    // empty, just used to mark types as acceptable for serializing to JSON
}

extension NSString: JSONValue {}
extension NSNumber: JSONValue {}
extension NSArray: JSONValue {}
extension NSDictionary: JSONValue {}
extension NSNull: JSONValue {}
extension String: JSONValue {}
extension Bool: JSONValue {}
extension Double: JSONValue {}
extension Float: JSONValue {}
extension Int: JSONValue {}
extension Int8: JSONValue {}
extension Int16: JSONValue {}
extension Int32: JSONValue {}
extension Int64: JSONValue {}
extension UInt: JSONValue {}
extension UInt8: JSONValue {}
extension UInt16: JSONValue {}
extension UInt32: JSONValue {}
extension UInt64: JSONValue {}
extension Array: JSONValue {}
extension Dictionary: JSONValue {}

extension NSData: PlistValue {}
extension NSDate: PlistValue {}
extension Data: PlistValue {}
extension Date: PlistValue {}

enum SBAProfileParticipantSourceKey: String {
    case firstName
    case lastName
    case email
    case externalId
    case notifyByEmail
    case sharingScope
    case dataGroups
}

open class SBAStudyParticipantProfileItem: SBAStudyParticipantCustomAttributesProfileItem {
    public static var studyParticipant: SBBStudyParticipant?
    
    override open func storedValue(forKey key: String) -> Any? {
        guard let studyParticipant = SBAStudyParticipantProfileItem.studyParticipant
            else {
                assertionFailure("Attempting to read \(key) (\(profileKey)) on nil SBBStudyParticipant")
                return nil
        }
        // special-case handling for an attribute to call through to the superclass implementation
        if let attributeKey = key.parseSuffix(prefix: "attributes", separator:".") {
            return super.storedValue(forKey: attributeKey)
        }
        
        guard let enumKey = SBAProfileParticipantSourceKey(rawValue: key)
            else {
                assertionFailure("Error reading \(key) (\(profileKey)): \(key) is not a valid SBBStudyParticipant key")
                return nil
        }
        
        var storedVal = studyParticipant.value(forKey: key)
        switch enumKey {
        case .sharingScope:
            guard let scopeString = storedVal as? String else { break }
            storedVal = SBBParticipantDataSharingScope(key: scopeString)
        default:
            break
        }
        
        return storedVal
    }
    
    override open func setStoredValue(_ newValue: Any?) {
        guard let studyParticipant = SBAStudyParticipantProfileItem.studyParticipant
            else {
                assertionFailure("Attempting to set \(sourceKey) (\(profileKey)) on nil SBBStudyParticipant")
                return
        }
        
        // special-case handling for an attribute to call through to the superclass implementation
        if let attributeKey = sourceKey.parseSuffix(prefix: "attributes", separator:".") {
            super.setStoredValue(newValue, forKey: attributeKey)
            return
        }
        
        guard let key = SBAProfileParticipantSourceKey(rawValue: sourceKey)
            else {
                assertionFailure("Error setting \(sourceKey) (\(profileKey)): \(sourceKey) is not a valid SBBStudyParticipant key")
                return
        }
        
        var setValue = newValue
        switch key {
        case .dataGroups:
            guard let _ = newValue as? Set<String>
                else {
                    assertionFailure("Error setting \(sourceKey) (\(profileKey)): value \(String(describing: newValue)) cannot be converted to Set")
                    return
            }
        case .sharingScope:
            guard let scope = newValue as? SBBParticipantDataSharingScope
                else {
                    assertionFailure("Error setting \(sourceKey) (\(profileKey)): value \(String(describing: newValue)) cannot be converted to SBBParticipantDataSharingScope")
                    return
            }
            setValue = SBBParticipantManager.dataSharingScopeStrings()[scope.rawValue]
        case .notifyByEmail:
            guard let _ = newValue as? Bool
                else {
                    assertionFailure("Error setting \(sourceKey) (\(profileKey)): value \(String(describing: newValue)) cannot be converted to Bool")
                    return
            }
        default:
            // the rest are String, and anything can be converted to String
            break
        }
        
        studyParticipant.setValue(setValue, forKeyPath: sourceKey)
        
        // save the change to Bridge
        SBABridgeManager.updateParticipantRecord(studyParticipant) { (_, _) in }
    }
}


open class SBAStudyParticipantCustomAttributesProfileItem: SBAProfileItemBase {
    override open func storedValue(forKey key: String) -> Any? {
        guard let attributes = SBAStudyParticipantProfileItem.studyParticipant?.attributes
            else {
                assertionFailure("Attempting to read \(key) (\(profileKey)) on nil SBBStudyParticipantCustomAttributes")
                return nil
        }
        guard attributes.responds(to: NSSelectorFromString(key))
            else {
                assertionFailure("Error reading \(key) (\(profileKey)): \(key) is not a defined SBBStudyParticipantCustomAttributes key")
                return nil
        }
        guard let rawValue = attributes.value(forKey: key) as? SBBJSONValue else { return nil }
        guard let value = commonJsonToItemType(value: rawValue)
            else {
                assertionFailure("Error reading \(key) (\(profileKey)): \(String(describing: rawValue)) is not convertible to item type \(itemType)")
                return nil
        }
        
        return value
    }
    
    override open func setStoredValue(_ newValue: Any?) {
        self.setStoredValue(newValue, forKey: sourceKey)
    }
    
    open func setStoredValue(_ newValue: Any?, forKey key: String) {
        guard let studyParticipant = SBAStudyParticipantProfileItem.studyParticipant,
                let attributes = studyParticipant.attributes
            else {
                assertionFailure("Attempting to set \(key) (\(profileKey)) on nil SBBStudyParticipantCustomAttributes")
                return
        }
        guard attributes.responds(to: NSSelectorFromString(key))
            else {
                assertionFailure("Error reading \(key) (\(profileKey)): \(key) is not a defined SBBStudyParticipantCustomAttributes key")
                return
        }
        guard newValue != nil
            else {
                attributes.setValue(nil, forKey: key)
                return
        }
        guard let jsonValue = commonItemTypeToJson(val: newValue)
            else {
                assertionFailure("Error setting \(key) (\(profileKey)): \(String(describing: value)) is not convertible to JSON")
                return
        }
        
        attributes.setValue(jsonValue, forKey: key)
        
        // save the change to Bridge
        SBABridgeManager.updateParticipantRecord(studyParticipant) { (_, _) in }
    }
}

open class SBAWhatAndWhen: NSObject, Comparable {
    static var valueKey: String { return #keyPath(value) }
    static var dateKey: String { return #keyPath(date) }
    static var isNewKey: String { return #keyPath(isNew) }
    open var value: SBBJSONValue
    open var date: NSDate
    var isNew: Bool
    
    public init(dictionaryRepresentation dictionary: [String: SBBJSONValue]) {
        value = dictionary[SBAWhatAndWhen.valueKey]!
        let dateString = dictionary[SBAWhatAndWhen.dateKey] as! String
        date = NSDate(iso8601String: dateString)
        let isNewJson = dictionary[SBAWhatAndWhen.isNewKey] as? NSNumber
        isNew = isNewJson != nil ? isNewJson!.boolValue : false
        super.init()
    }
    
    public init(_ value: SBBJSONValue, asOf date: NSDate, isNew:Bool = false) {
        self.value = value
        self.date = date
        self.isNew = isNew
        super.init()
    }
    
    public func dictionaryRepresentation() -> [String: SBBJSONValue] {
        return [
            SBAWhatAndWhen.valueKey: value,
            SBAWhatAndWhen.dateKey: date.iso8601String() as NSString
        ]
    }
    
    public func cachedDictionaryRepresentation() -> [String: SBBJSONValue] {
        var dict = self.dictionaryRepresentation()
        dict[SBAWhatAndWhen.isNewKey] = isNew as NSNumber
        return dict
    }
}

public func < (lhs: SBAWhatAndWhen, rhs: SBAWhatAndWhen) -> Bool {
    // arbitrary JSON isn't comparable, so we'll just compare dates and, secondarily, isNew
    let comparison = lhs.date.compare(rhs.date as Date)
    guard comparison == .orderedSame else { return comparison == .orderedAscending }
    
    // we'll call false < true as far as isNew is concerned
    return lhs.isNew == false && rhs.isNew == true
}

public func == (lhs: SBAWhatAndWhen, rhs: SBAWhatAndWhen) -> Bool {
    return (lhs.date as Date) == (rhs.date as Date) &&
        lhs.value.isEqual(rhs.value) &&
        lhs.isNew == rhs.isNew
}

/// The activity to which an SBAClientDataProfileItem is attached should be scheduled such that there is always an appropriate
/// SBBScheduledActivity object on which to save it (i.e. doesn't expire before being rescheduled). Its clientData must also be
/// a JSON dictionary, and the values set here will be stored at the top level by sourceKey as a list of dictionaries containing
/// "date" and "value" entries. If the value of the item is changed more quickly than it is rescheduled, the "date" timestamp
/// allows there to be more than one entry per SBBScheduledActivity instance, so this type of profile item can be used to record
/// and/or retrieve a time series of values.
open class SBAClientDataProfileItem: SBAProfileItemBase {
    private enum CodingKeys: String, CodingKey {
        case taskIdentifier, surveyIdentifier, activityIdentifier
    }
    
    // ClientData profile items are attached to and read from the most date-appropriate instance
    // of a SBBScheduledActivity for a given activityIdentifier. Since those are not always available
    // when the app needs to read and write Profile item values, we also keep track of the latest
    // (most current) value in a local keychain cache, and store any newly-set values there until
    // they can be written to an SBBScheduledActivity.
    static var cachedItemsKey: String = "SBAClientDataProfileItemCachedItems"
    private static var toBeUpdatedToBridge: Set<SBBScheduledActivity> = Set<SBBScheduledActivity>()
    static var keychain: SBAKeychainWrapperProtocol = SBAProfileManager.keychain
    
    // In the normal case (all values have been written to an SBBScheduledActivity instance), the
    // array of values for a given profile item will consist of one element, the latest. They are
    // arrays rather than single dictionaries so that multiple values with different timestamps can
    // be stored until they can be written to an SBBScheduledActivity, if for example the app
    // is not able to connect to the Bridge servers for an extended period. It's also useful if,
    // say, your app allows adding or editing events in the past.
    static var currentValues: [String: [[String: SBBJSONValue]]] {
        get {
            var error: NSError?
            let dict = keychain.object(forKey: cachedItemsKey, error: &error)
            var values = [String: [[String: SBBJSONValue]]]()
            if error != nil {
                if error!.code == Int(errSecItemNotFound) {
                    self.currentValues = values
                }
                else {
                    print("Error accessing keychain \(cachedItemsKey): \(error!.code) \(error!)")
                }
            }
            else {
                values = dict as! [String : [[String : SBBJSONValue]]]
            }
            
            return values
        }
        
        set {
            do {
                try keychain.setObject(newValue as NSSecureCoding, forKey: cachedItemsKey)
            }
            catch let error {
                assert(false, "Failed to set \(cachedItemsKey): \(String(describing: error))")
            }
        }
    }
    
    static func addToCurrentValues(_ jsonWhatAndWhen: [String: SBBJSONValue], forProfileKey key: String) {
        var currentValuesForKey = currentValues[key] ?? [[String: SBBJSONValue]]()
        currentValuesForKey.append(jsonWhatAndWhen)
        currentValues[key] = jsonWhatsAndWhensSortedByWhen(currentValuesForKey)
    }
    
    public static var scheduledActivities: [SBBScheduledActivity]? {
        didSet {
            // get all the SBAClientDataProfileItem instances from SBAProfileManager
            guard scheduledActivities != nil && scheduledActivities!.count > 0 else { return }
            let clientDataItems: [SBAClientDataProfileItem] = SBAProfileManager.shared.profileItems().values.compactMap({ return $0 as? SBAClientDataProfileItem })
            guard clientDataItems.count > 0 else { return }
            
            var updatedDemographicData = Set<String>()
            for item in clientDataItems {
                // for each one, get all its current cached values and all available values from Bridge
                let cachedItems = item.dateAndJsonValuesFromCachedItems()
                let bridgeValues = item.jsonWhatsAndWhensFromBridge()
                if cachedItems == nil && bridgeValues.count == 0 { continue }
                
                // if cached items is missing or empty, just set it with the latest value from Bridge as its only element
                // and skip ahead to the next item
                let latest = bridgeValues.last
                if cachedItems == nil || cachedItems!.count == 0 {
                    addToCurrentValues(latest!, forProfileKey: item.profileKey)
                    continue
                }
                
                // go through the cached items one-by-one and handle appropriately
                for cachedItem in cachedItems! {
                    // if cached date/value is new, attach it to the appropriate SBBScheduledActivity instance
                    if cachedItem.isNew {
                        let whatAndWhenJson = cachedItem.dictionaryRepresentation()
                        item.setToAppropriateScheduledActivity(whatAndWhenJson)
                        if item.demographicSchema != nil { updatedDemographicData.insert(item.demographicSchema!) }
                    }
                }
                
                // now remove all but the last one (they're always sorted by date)
                let finalCachedItem = cachedItems!.last!
                
                // using dictionaryRepresentation() instead of cachedDictionaryRepresentation() leaves off
                // any isNew flag from the cached item, so it won't keep trying to update it to Bridge
                var finalCachedJson = finalCachedItem.dictionaryRepresentation()
                
                // if latest value from Bridge is newer, cache it instead
                guard latest != nil
                    else {
                        currentValues[item.profileKey] = [finalCachedJson]
                        continue
                }
                let bridgeItem = SBAWhatAndWhen(dictionaryRepresentation: latest!)
                if finalCachedItem.date.compare(bridgeItem.date as Date) == .orderedAscending {
                    finalCachedJson = latest!
                }
                
                // set it
                currentValues[item.profileKey] = [finalCachedJson]
            }
            
            // if we ended up updating any SBBScheduledActivity instances, push the changes to Bridge
            guard toBeUpdatedToBridge.count > 0 else { return }
            let updatesArray = Array(toBeUpdatedToBridge)
            toBeUpdatedToBridge.removeAll()
            SBABridgeManager.updateScheduledActivities(updatesArray)
            
            // if there were any updates to demographic data items, upload demographic data
            guard updatedDemographicData.count > 0,
                let profileManager = SBAProfileManager.shared as? SBAProfileManager
                else {
                    return
            }
            profileManager.uploadDemographicData(updatedDemographicData)
        }
    }
    
    open var taskIdentifier: String?
    
    open var surveyIdentifier: String?
    
    open var activityIdentifier: String
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        taskIdentifier = try container.decodeIfPresent(String.self, forKey: .taskIdentifier)
        surveyIdentifier = try container.decodeIfPresent(String.self, forKey: .surveyIdentifier)
        activityIdentifier = try container.decodeIfPresent(String.self, forKey: .activityIdentifier) ??
                                    taskIdentifier ??
                                    surveyIdentifier ??
                                    ""
        
        try super.init(from: decoder)
    }
    
    static func jsonWhatsAndWhensSortedByWhen(_ jsonWhatsAndWhens: [[String: SBBJSONValue]]) -> [[String: SBBJSONValue]] {
        return jsonWhatsAndWhens.sorted(by: {
            return SBAWhatAndWhen(dictionaryRepresentation: $0) < SBAWhatAndWhen(dictionaryRepresentation: $1)
        })
    }
    
    func jsonWhatsAndWhensFromBridge() -> [[String: SBBJSONValue]] {
        // pull out all the non-empty lists of date/value instances for this activityIdentifier and key into one non-empty list
        guard let valueArrays = SBAClientDataProfileItem.scheduledActivities?.mapAndFilter({ (scheduledActivity) -> [[String: SBBJSONValue]]? in
            guard scheduledActivity.activityIdentifier == activityIdentifier,
                let clientData = scheduledActivity.clientData as? NSDictionary,
                let valueArray = clientData[sourceKey] as? [[String : SBBJSONValue]],
                valueArray.count > 0
                else { return nil }
            
            return valueArray
        }),
            valueArrays.count > 0
            else { return [] }
        
        // consolidate them all into one list, sort by date, and return that
        var whatsAndWhens = [[String: SBBJSONValue]]();
        for valueArray in valueArrays {
            whatsAndWhens.append(contentsOf: valueArray)
        }
        return SBAClientDataProfileItem.jsonWhatsAndWhensSortedByWhen(whatsAndWhens)
    }
    
    func dateAndJsonValuesFromCachedItems() -> [SBAWhatAndWhen]? {
        guard let whatsAndWhens = SBAClientDataProfileItem.currentValues[profileKey] else { return nil }
        return whatsAndWhens.map({ return SBAWhatAndWhen(dictionaryRepresentation: $0) })
    }
    
    override open func storedValue(forKey key: String) -> Any? {
        guard let whatAndWhen = dateAndJsonValuesFromCachedItems()?.last else { return nil }
        guard let value = commonJsonToItemType(value: whatAndWhen.value)
            else {
                assertionFailure("Error reading \(key) (\(profileKey)): \(String(describing: whatAndWhen.value)) is not convertible to item type \(itemType)")
                return nil
        }
        
        if value is NSNull {
            return nil
        }
        
        return value
    }
    
    override open func setStoredValue(_ newValue: Any?) {
        setStoredValue(newValue, asOf: Date())
    }
    
    func setToAppropriateScheduledActivity(_ jsonWhatAndWhen: [String: SBBJSONValue]) {
        // potential SBBScheduledActivity instances to update will have the right activityIdentifier and will expire after, if at all
        let when = SBAWhatAndWhen(dictionaryRepresentation: jsonWhatAndWhen).date as Date
        guard let activities = SBAClientDataProfileItem.scheduledActivities?.mapAndFilter({ (scheduledActivity) -> SBBScheduledActivity? in
            if scheduledActivity.activityIdentifier == activityIdentifier {
                return scheduledActivity
            }
            return nil
        }),
            activities.count > 0
            else { return }
        
        // the appropriate activity is either the most recent one scheduled before our asOf date, or the oldest one if none
        // were scheduled before (e.g. if the value was set during onboarding before the account was created).
        var bestActivity: SBBScheduledActivity = activities.first!
        for activity in activities.reversed() {
            if activity.scheduledOn <= when {
                bestActivity = activity
                break
            }
        }
        
        if bestActivity.startedOn == nil {
            bestActivity.startedOn = when
        }
        
        setTo(bestActivity, jsonWhatAndWhen: jsonWhatAndWhen)
    }
    
    func setTo(_ scheduledActivity: SBBScheduledActivity, jsonWhatAndWhen: [String: SBBJSONValue]) {
        let when = SBAWhatAndWhen(dictionaryRepresentation: jsonWhatAndWhen).date as Date
        let clientData = scheduledActivity.clientData as? NSMutableDictionary ?? NSMutableDictionary()
        var jsonWhatsAndWhens = clientData[sourceKey] as? [[String: SBBJSONValue]] ?? [[String: SBBJSONValue]]()
        jsonWhatsAndWhens.append(jsonWhatAndWhen)
        
        // make sure the jsonWhatsAndWhens are in ascending order by date
        jsonWhatsAndWhens = SBAClientDataProfileItem.jsonWhatsAndWhensSortedByWhen(jsonWhatsAndWhens)
        clientData[sourceKey] = jsonWhatsAndWhens
        scheduledActivity.clientData = clientData
        
        if  scheduledActivity.finishedOn == nil || when > scheduledActivity.finishedOn! {
            scheduledActivity.finishedOn = when
        }
        
        // add the found SBBScheduledActivity to the set of those that need to be updated to Bridge
        SBAClientDataProfileItem.toBeUpdatedToBridge.insert(scheduledActivity)
    }
    
    open func setStoredValue(_ newValue: Any?, asOf when: Date) {
        guard let jsonValue = commonItemTypeToJson(val: newValue) else { return }
        
        let whatAndWhen = SBAWhatAndWhen(jsonValue, asOf: when as NSDate, isNew: true)
        
        // store it in local cache so it will get updated to Bridge next time
        SBAClientDataProfileItem.addToCurrentValues(whatAndWhen.cachedDictionaryRepresentation(), forProfileKey: profileKey)
    }
    
    open func setValue(_ newValue: Any?, asOf when: Date, to scheduledActivity: SBBScheduledActivity) {
        guard let jsonValue = commonItemTypeToJson(val: newValue) else { return }
        
        let whatAndWhen = SBAWhatAndWhen(jsonValue, asOf: when as NSDate)
        
        // store it to the specified scheduled activity's clientData
        setTo(scheduledActivity, jsonWhatAndWhen: whatAndWhen.dictionaryRepresentation())
    }
    
    open func valuesAndDates() -> [SBAWhatAndWhen] {
        let fromBridge = self.jsonWhatsAndWhensFromBridge().map({ return SBAWhatAndWhen(dictionaryRepresentation: $0) })
        let fromCache = SBAClientDataProfileItem.currentValues[profileKey]?.map({ return SBAWhatAndWhen(dictionaryRepresentation: $0) }) ?? [SBAWhatAndWhen]()
        let setOfAll = Set(fromBridge).union(fromCache)
        return Array(setOfAll).sorted()
    }
    
    /// This should at least be called whenever the app is leaving the foreground, and at other appropriate times
    /// such as closing a view controller where clientData-based profile items are edited.
    ///
    /// Calling it at app launch is also appropriate, and has the handy side effect of prepopulating scheduledActivities
    /// with all SBBScheduledActivity objects currently in BridgeSDK's cache.
    public class func updateChangesToBridge() {
        // figure out the date range for new values in the local cache
        let calendar = Calendar.current
        var startDate: Date = calendar.startOfDay(for: Date())
        var endDate: Date = calendar.date(byAdding: .day, value: 1, to: startDate)!
        for whatsAndWhensJson in SBAClientDataProfileItem.currentValues.values {
            for whatAndWhenJson in whatsAndWhensJson {
                let whatAndWhen = SBAWhatAndWhen(dictionaryRepresentation: whatAndWhenJson)
                guard whatAndWhen.isNew else { continue }
                let whenDate = whatAndWhen.date as Date
                startDate = whenDate < startDate ? whenDate : startDate
                endDate = whenDate > endDate ? whenDate : endDate
            }
        }
        
        // fetch scheduled activities from Bridge covering those dates so we're fairly sure to have instances
        // to save the values on
        SBABridgeManager.fetchScheduledActivities(from: startDate, to: endDate) { (activities, error) in
            if error == nil {
                // now fetch all the scheduled activities we've got in the cache
                SBABridgeManager.fetchAllCachedScheduledActivities(completion: { (cachedActivities, cacheError) in
                    if cacheError == nil {
                        guard let scheduledActivities = cachedActivities as? [SBBScheduledActivity],
                            scheduledActivities.count > 0
                            else { return }
                        
                        // Setting this will trigger any new cached item values to be saved to the appropriate
                        // SBBScheduledActivity instance and pushed to Bridge.
                        SBAClientDataProfileItem.scheduledActivities = scheduledActivities
                    }
                })
            }
        }
    }
}

open class SBAFullNameProfileItem: SBAStudyParticipantProfileItem, SBANameDataSource {
    private enum CodingKeys: String, CodingKey {
        case givenNameKey, familyNameKey
    }
    
    override open var value: Any? {
        
        get {
            return self.fullName
        }
        
        set {
            // readonly
        }
    }
    
    override open var readonly: Bool {
        return true
    }
    
    fileprivate var givenNameKey: String
    
    fileprivate var familyNameKey: String
    
    open var name: String? {
        return self.storedValue(forKey: givenNameKey) as? String 
    }
    
    open var familyName: String? {
        return self.storedValue(forKey: familyNameKey) as? String
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        givenNameKey = try container.decodeIfPresent(String.self, forKey: .givenNameKey) ?? SBAProfileSourceKey.givenName.rawValue
        familyNameKey = try container.decodeIfPresent(String.self, forKey: .familyNameKey) ?? SBAProfileSourceKey.familyName.rawValue

        try super.init(from: decoder)
    }
}

open class SBABirthDateProfileItem: SBAStudyParticipantCustomAttributesProfileItem {
    
    override open var demographicJsonValue: SBBJSONValue? {
        guard let age = (self.value as? Date)?.currentAge() else { return nil }
        return NSNumber(value: age)
    }
}
 */
