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

public protocol SBAProfileItem: class, Decodable {
    
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
    
    /// Is the value read-only?
    var readonly: Bool { get }
    
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
    
    /// Used in the setters for the profile items to set a new value to client data.
    public func commonItemTypeToBridgeJson(val: Any?) -> SBBJSONValue {
        do {
            let answerType = self.itemType.defaultAnswerResultType()
            let ret = try answerType.jsonEncode(from: val)
            guard let json = ret else { return NSNull() }
            return json.toClientData()
        }
        catch let err {
            assertionFailure("WARNING! Failed to encode \(self.demographicKey) from \(String(describing: val)): \(err)")
            return NSNull()
        }
    }
    
    public func commonBridgeJsonToItemType(jsonVal: SBBJSONValue?) -> Any? {
        guard let jsonVal = jsonVal else {
            return nil
        }
        
        do {
            let answerType = self.itemType.defaultAnswerResultType()
            return try answerType.jsonDecode(from: jsonVal.toJSONSerializable(), with: self.itemType)
        }
        catch let err {
            if self.itemType == .base(.string) {
                return "\(jsonVal)"
            }
            else {
                assertionFailure("WARNING! Failed to decode \(self.demographicKey) from \(jsonVal): \(err)")
                return nil
            }
        }
    }
}

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
public final class SBAReportProfileItem: SBAProfileItemInternal {
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
        var json = clientData
        if !self.clientDataIsItem {
            guard let dict = clientData as? NSDictionary,
                    let propJson = dict[self.demographicKey] as? SBBJSONValue
                else {
                    return nil
            }
            json = propJson
        }
        
        return self.commonBridgeJsonToItemType(jsonVal: json)
    }
    
    public func setStoredValue(_ newValue: Any?) {
        guard !self.readonly, let reportManager = self.reportManager else { return }
        let previousReport = reportManager.reports
            .sorted(by: { $0.date < $1.date })
            .last(where: { $0.reportKey == RSDIdentifier(rawValue: self.sourceKey) })
        var clientData : SBBJSONValue = NSNull()
        if self.clientDataIsItem {
            clientData = self.commonItemTypeToBridgeJson(val: newValue)
        } else {
            var clientJsonDict = previousReport?.clientData as? [String : Any] ?? [String : Any] ()
            clientJsonDict[self.demographicKey] = self.commonItemTypeToBridgeJson(val: newValue)
            clientData = clientJsonDict as NSDictionary
        }
        let report = reportManager.newReport(reportIdentifier: self.sourceKey, date: Date(), clientData: clientData)
        reportManager.saveReport(report)
    }
    
}

/// SBADataGroupProfileItem allows storing and retrieving profile item values to/from a data group.
///
/// A common scenario for a study would be to have a demographic survey which is administered once
/// after the participant signs up and consents. Often (always in e.g. Canada, where required by law),
/// the app/study design would need some way to allow the participant to change those answers later.
/// One way to do this is to create an editable profile item for each question/answer in the
/// demographic survey. In this scenario, for each of these items you would set the demographicSchema
/// to the survey identifier, set the source key to the survey identifier as well, and set the
/// demographicKey to the identifier of the survey question corresponding to the profile item.
public final class SBADataGroupProfileItem: SBAProfileItemInternal {
    private enum CodingKeys: String, CodingKey {
        case profileKey, _sourceKey = "sourceKey", _demographicKey = "demographicKey", demographicSchema, itemType, _readonly = "readonly", type, dataGroups
    }

    fileprivate var _sourceKey: String?
    
    fileprivate var _demographicKey: String?
    
    fileprivate var _readonly: Bool?
    
    /// `profileKey` is used to access a specific profile item, and so must be unique across all
    /// SBAProfileItems within an app.
    public var profileKey: String
    
    /// `demographicSchema` is an optional schema identifier to mark a profile item as being part of
    /// the indicated demographic data upload schema.
    public var demographicSchema: String?

    /// `itemType` specifies what type to store the profileItem's value as. Defaults to String if not
    /// otherwise specified.
    public var itemType: RSDFormDataType
    
    /// The class type to which to deserialize this profile item.
    public var type: SBAProfileItemType
    
    /// The data groups that are linked to this profile item.
    public var dataGroups: Set<String>
    
    public func storedValue(forKey key: String) -> Any? {
        guard let currentDataGroups = SBAParticipantManager.shared.studyParticipant?.dataGroups
            else {
                return nil
        }
        let value = currentDataGroups.intersection(self.dataGroups).joined(separator: ", ")
        return value
    }
    
    public func setStoredValue(_ newValue: Any?) {
        guard let participant = SBAParticipantManager.shared.studyParticipant
            else {
                print("WARNING! Trying to set the data groups without a participant")
                return
        }
        let currentDataGroups: Set<String> = participant.dataGroups ?? []
        let newGroups: Set<String> = {
            if let array = newValue as? [String] {
                return Set(array)
            }
            else if let set = newValue as? Set<String> {
                return set
            }
            else if let string = newValue as? String {
                let characters = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ","))
                let array = string.components(separatedBy: characters).compactMap { $0.isEmpty ? nil : $0
                }
                return Set(array)
            }
            else {
                return currentDataGroups
            }
        }()
        let addGroups = self.dataGroups.intersection(newGroups)
        let updatedGroups = currentDataGroups.subtracting(self.dataGroups).union(addGroups)
        SBBParticipantManager.default()?.updateDataGroups(withGroups: updatedGroups, completion: nil)
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

/// This extends the SBBStudyParticipant to allow accessing the phone number via a phoneNumber key.
@objc
extension SBBStudyParticipant {
    @objc
    public var phoneNumber: String? {
        return self.phone?.number
    }
}

/// SBAStudyParticipantProfileItem allows storing and retrieving profile item values to/from the SBBStudyParticipant object.
/// For this type of profile item, the sourceKey (which defaults to the profileKey if not specifically set) is
/// interpreted as the key path into the SBBStudyParticipant.
public final class SBAStudyParticipantProfileItem: SBAProfileItemInternal {
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
public final class SBAStudyParticipantClientDataProfileItem: SBAProfileItemInternal {
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
        guard let dict = participant.clientData as? [String : Any],
            let json = dict[self.sourceKey] as? SBBJSONValue
            else {
                if let keyPath = self.fallbackKeyPath {
                    return participant.value(forKeyPath: keyPath)
                }
                else {
                    return nil
                }
        }
        return self.commonBridgeJsonToItemType(jsonVal: json)
    }
    
    public func setStoredValue(_ newValue: Any?) {
        guard !self.readonly, let participant = SBAParticipantManager.shared.studyParticipant else { return }
        var dict = participant.clientData as? [String : Any] ?? [:]
        dict[self.sourceKey] = self.commonItemTypeToBridgeJson(val: newValue)
        participant.clientData = dict as SBBJSONValue
        BridgeSDK.participantManager.updateParticipantRecord(withRecord: participant) { (_, _) in
        }
    }
}

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
