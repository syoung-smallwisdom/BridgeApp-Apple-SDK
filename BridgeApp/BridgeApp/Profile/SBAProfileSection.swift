//
//  SBAProfileSection.swift
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

/// The type of a profile table item. This is used to decode the item in a factory.
public struct SBAProfileTableItemType : RawRepresentable, Codable {
    public typealias RawValue = String
    
    public private(set) var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Defaults to creating a `SBAHTMLProfileTableItem`.
    public static let html: SBAProfileTableItemType = "html"
    
    /// Defaults to creating a `SBAProfileItemProfileTableItem`.
    public static let profileItem: SBAProfileTableItemType = "profileItem"
    
    /// Defaults to creating a `SBAResourceProfileTableItem`.
    public static let resource: SBAProfileTableItemType = "resource"
    
    /// Defaults to creating a `SBAProfileViewProfileTableItem`.
    public static let profileView: SBAProfileTableItemType = "profileView"

    /// List of all the standard types.
    public static func allStandardTypes() -> [SBAProfileTableItemType] {
        return [.html, .profileItem, .resource, .profileView]
    }
}

extension SBAProfileTableItemType : Equatable {
    public static func ==(lhs: SBAProfileTableItemType, rhs: SBAProfileTableItemType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func ==(lhs: String, rhs: SBAProfileTableItemType) -> Bool {
        return lhs == rhs.rawValue
    }
    public static func ==(lhs: SBAProfileTableItemType, rhs: String) -> Bool {
        return lhs.rawValue == rhs
    }
}

extension SBAProfileTableItemType : Hashable {
    public var hashValue : Int {
        return self.rawValue.hashValue
    }
}

extension SBAProfileTableItemType : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension SBAProfileTableItemType {
    static func allCodingKeys() -> [String] {
        return allStandardTypes().map{ $0.rawValue }
    }
}

/// A protocol for defining a section of a profile table.
public protocol SBAProfileSection {
    /// The title text to show for the section.
    var title: String? { get }
    
    /// An icon to show in the section header.
    var icon: String? { get }
    
    /// A list of profile table items to show in the section.
    var items: [SBAProfileTableItem] { get }
}

/// A protocol for defining items to be shown in a profile table.
public protocol SBAProfileTableItem {
    /// The title text to show for the item.
    var title: String? { get }
    
    /// Detail text to show for the item.
    var detail: String? { get }
    
    /// Is the table item editable?
    var isEditable: Bool? { get }
    
    /// A set of cohorts (data groups) the participant must be in, in order to show this item in its containing profile section.
    var inCohorts: Set<String>? { get }
    
    /// A set of cohorts (data groups) the participant must **not** be in, in order to show this item in its containing profile section.
    var notInCohorts: Set<String>? { get }
    
    /// The action to perform when the item is selected.
    var onSelected: SBAProfileOnSelectedAction? { get }
}

/// A concrete implementation of the `SBAProfileSection` protocol which implements the Decodable protocol so it can be described in JSON.
open class SBAProfileSectionObject: SBAProfileSection, Decodable {
    open var title: String?
    open var icon: String?
    private var allItems: [SBAProfileTableItem] = []
    open var items: [SBAProfileTableItem] {
        get {
            
            let cohorts = SBAParticipantManager.shared.studyParticipant?.dataGroups ?? Set<String>()
            return allItems.filter({ (tableItem) -> Bool in
                // return true if participant data groups include all of the inCohorts and none of the notInCohorts
                guard tableItem.inCohorts != nil || tableItem.notInCohorts != nil
                    else {
                        return true
                }
                let mustBeIn = tableItem.inCohorts ?? Set<String>()
                let mustNotBeIn = tableItem.notInCohorts ?? Set<String>()
                return (mustBeIn.intersection(cohorts) == mustBeIn &&
                        mustNotBeIn.isDisjoint(with: cohorts))
            })
        }
        set {
            allItems = newValue
        }
    }
    
    // MARK: Decoder
    private enum CodingKeys: String, CodingKey {
        case title, icon, items
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
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decodeIfPresent(String.self, forKey: .title)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        if container.contains(.items) {
            var items: [SBAProfileTableItem] = []
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .items)
            while !nestedContainer.isAtEnd {
                let itemDecoder = try nestedContainer.superDecoder()
                let itemTypeName = try typeName(from: itemDecoder)
                let itemType = SBAProfileTableItemType(rawValue: itemTypeName)
                if let item = try decodeItem(from: itemDecoder, with: itemType) {
                    items.append(item)
                }
            }
            self.items = items
        }
    }

    /// Decode the profile table item from this decoder.
    ///
    /// - parameters:
    ///     - type:        The `ProfileTableItemType` to instantiate.
    ///     - decoder:     The decoder to use to instatiate the object.
    /// - returns: The profile item (if any) created from this decoder.
    /// - throws: `DecodingError` if the object cannot be decoded.
    open func decodeItem(from decoder:Decoder, with type:SBAProfileTableItemType) throws -> SBAProfileTableItem? {
        
        switch (type) {
        case .html:
            return try SBAHTMLProfileTableItem(from: decoder)
        case .profileItem:
            return try SBAProfileItemProfileTableItem(from: decoder)
            // TODO: emm 2018-08-19 deal with this for mPower 2 2.1
//        case .resource:
//            return try SBAResourceProfileTableItem(from: decoder)
        case .profileView:
            return try SBAProfileViewProfileTableItem(from: decoder)
        default:
            print("WARNING! Attempt to decode profile table item of unknown type \(type.rawValue)")
            return nil
        }
    }

}

/// A profile table item that displays HTML when selected.
public struct SBAHTMLProfileTableItem: SBAProfileTableItem, Decodable, RSDResourceTransformer {
    private enum CodingKeys: String, CodingKey {
        case title, detail, inCohorts, notInCohorts, htmlResource, bundleIdentifier
    }
    
    // MARK: SBAProfileTableItem
    /// Title to show for the table item.
    public var title: String?
    
    /// Detail text to show for the table item.
    public var detail: String?
    
    /// HTML profile table items are not editable.
    public var isEditable: Bool? {
        return false
    }
    
    /// A set of cohorts (data groups) the participant must be in, in order to show this item in its containing profile section.
    public var inCohorts: Set<String>?
    
    /// A set of cohorts (data groups) the participant must not be in, in order to show this item in its containing profile section.
    public var notInCohorts: Set<String>?
    
    /// HTML items show the HTML when selected.
    public var onSelected: SBAProfileOnSelectedAction? {
        return .showHTML
    }
    
    // MARK: HTML Profile Table Item
    
    /// The htmlResource for this item.
    public let htmlResource: String
    
    /// Get a URL pointer to the HTML resource.
    public var url: URL? {
        do {
            let (url,_) = try self.resourceURL(ofType: "html")
            return url
        }
        catch let err {
            debugPrint("Error getting the URL: \(err)")
            return nil
        }
    }
    
    
    // MARK: RSDResourceTransformer
    
    /// The bundle identifier for the resource bundle that contains the html.
    public var bundleIdentifier: String?
    
    /// The default bundle from the factory used to decode this object.
    public var factoryBundle: Bundle? = nil
    
    /// `RSDResourceTransformer` uses this to get the URL.
    public var resourceName: String {
        return htmlResource
    }
    
    /// Ignored - required to conform to `RSDResourceTransformer`
    public var classType: String? {
        return nil
    }

}

/// A profile table item that displays, and allows editing, the value of a Profile Item.
public struct SBAProfileItemProfileTableItem: SBAProfileTableItem, Decodable {
    private enum CodingKeys: String, CodingKey {
        case title, _isEditable = "isEditable", inCohorts, notInCohorts, _onSelected = "onSelected", profileItemKey, _profileManagerIdentifier = "profileManager", _editTaskIdentifier = "editTaskIdentifier", _choices = "choices"
    }
    
    // MARK: SBAProfileTableItem
    /// Title to show for the table item.
    public var title: String?
    
    /// Detail text to show for the table item.
    public var detail: String? {
        guard let profileItem = self.profileItem else { return nil }
        guard let profileValue = self.profileItemValue else { return "" }
        
        if let choices = self.choices {
            let answerResult = RSDAnswerResultObject(identifier: profileItem.demographicKey, answerType: profileItem.itemType.defaultAnswerResultType(), value: profileValue)
            let answer = choices
                .compactMap({ $0.isEqualToResult(answerResult) ? $0.text : nil })
                .joined(separator: ", ")
            return answer
        }
        
        if let answers = profileValue as? [Any] {
            return answers.map({ "\($0)" }).joined(separator: ", ")
        }
        else if let isOn = profileValue as? Bool {
            return isOn ? Localization.localizedString("SETTINGS_STATE_ON") : Localization.localizedString("SETTINGS_STATE_OFF")
        }
        else {
            return String(describing: profileValue)
        }
    }
    
    /// A mapping of a the choices to the values.
    public var choices: [RSDChoice]? {
        // TODO: syoung 10/28/2019 Refactor to allow for choices that map to survey choices.
        return self._choices
    }
    private let _choices: [RSDChoiceObject<String>]?
    
    /// Current profile item value to apply to, and set from, an edit control.
    public var profileItemValue: Any? {
        get {
            return self.profileItem?.value
        }
        set {
            self.profileItem?.value = newValue
        }
    }
    
    /// The table item should not be editable if the profile item itself is readonly;
    /// otherwise honor this flag's setting, defaulting to true.
    private var _isEditable: Bool?
    public var isEditable: Bool? {
        get {
            return (self.profileItem?.readonly ?? true) ? false : (self._isEditable ?? true)
        }
        set {
            guard self.profileItem?.readonly == false else { return }
            self._isEditable = newValue
        }
    }
    
    /// A set of cohorts (data groups) the participant must be in, in order to show this item in its containing profile section.
    public var inCohorts: Set<String>?
    
    /// A set of cohorts (data groups) the participant must not be in, in order to show this item in its containing profile section.
    public var notInCohorts: Set<String>?
    
    /// Profile item profile table items by default edit when selected.
    private var _onSelected: SBAProfileOnSelectedAction? = .editProfileItem
    public var onSelected: SBAProfileOnSelectedAction? {
        get {
            return self._onSelected ?? .editProfileItem
        }
        set {
            self._onSelected = newValue
        }
    }
    
    // MARK: Profile Item Profile Table Item
    
    /// The profile item key for this profile table item. Required.
    /// - warning: Using a key that is not included in the Profile Manager's profileItems is a coding error.
    public let profileItemKey: String
    
    /// The profile manager for this profile table item. If an identifier not specified in json, it will
    /// use the default (shared) manager.
    private let _profileManagerIdentifier: String?
    public var profileManager: SBAProfileManager {
        guard let identifier = self._profileManagerIdentifier,
                let manager = SBABridgeConfiguration.shared.profileManager(for: identifier)
            else {
                return SBAProfileManagerObject.shared
        }
        
        return manager
    }
    
    /// The task info identifier for the step to display to the participant when they ask to edit the value
    /// of the profile item. Falls back to the profile item's demographicSchema if not explicitly set.
    ///
    public var _editTaskIdentifier: String?
    public var editTaskIdentifier: String? {
        get {
            return _editTaskIdentifier ?? self.profileItem?.demographicSchema
        }
    }
    
    /// The actual profile item for the given profileItemKey.
    public var profileItem: SBAProfileItem? {
        let profileItems = self.profileManager.profileItems()
        return profileItems[self.profileItemKey]
    }
}

/// A profile table item that, when selected, segues to another profile table view.
public struct SBAProfileViewProfileTableItem: SBAProfileTableItem, Decodable {
    private enum CodingKeys: String, CodingKey {
        case title, detail, inCohorts, notInCohorts, _iconName = "icon", _profileDataSourceIdentifier = "profileDataSource"
    }

    // MARK: SBAProfileTableItem

    /// Title to show for the table item.
    public var title: String?
    
    /// Detail text to show for the table item.
    public var detail: String?
    
    /// Profile view profile table items are not editable.
    public var isEditable: Bool? {
        return false
    }
    
    /// A set of cohorts (data groups) the participant must be in, in order to show this item in its containing profile section.
    public var inCohorts: Set<String>?
    
    /// A set of cohorts (data groups) the participant must not be in, in order to show this item in its containing profile section.
    public var notInCohorts: Set<String>?
    
    /// Profile view profile table items segue to their associated profile table view when selected.
    public var onSelected: SBAProfileOnSelectedAction? {
        return .showProfileView
    }
    
    // MARK: Profile View Profile Table Item

    /// The image (specified by name in json) to use as the icon for this profile table item.
    private var _iconName: String?
    public var icon: UIImage? {
        get {
            guard let imageName = _iconName else { return nil }
            return UIImage(named: imageName)
        }
    }
    
    /// The profile data source for the profile table view to which this item will segue when selected.
    private var _profileDataSourceIdentifier: String
    public var profileDataSource: SBAProfileDataSource {
        get {
            return SBABridgeConfiguration.shared.profileDataSource(for: self._profileDataSourceIdentifier)!
        }
        set {
            self._profileDataSourceIdentifier = newValue.identifier
        }
    }
}

