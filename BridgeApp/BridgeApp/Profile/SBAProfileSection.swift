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

/// The type of the profile table item. This is used to decode the item in a factory.
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

    /// List of all the standard types.
    public static func allStandardTypes() -> [SBAProfileTableItemType] {
        return [.html, .profileItem, .resource]
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

public protocol SBAProfileSection {
    var title: String? { get }
    var icon: String? { get }
    var items: [SBAProfileTableItem] { get }
}

public protocol SBAProfileTableItem {
    var title: String { get }
    var detail: String? { get }
    var isEditable: Bool { get }
    var onSelected: SBAProfileOnSelectedAction { get }
}

open class SBAProfileSectionObject: Decodable, SBAProfileSection {
    open var title: String?
    open var icon: String?
    open var items: [SBAProfileTableItem] = []
    
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
            var items: [SBAProfileTableItem] = self.items
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
            // TODO: emm 2018-08-19 deal with this for mPower 2 2.1
//        case .profileItem:
//            return try SBAProfileItemProfileTableItem(from: decoder)
        case .resource:
            return try SBAResourceProfileTableItem(from: decoder)
        default:
            assertionFailure("Attempt to decode profile table item of unknown type \(type.rawValue)")
            return nil
        }
    }

}

open class SBAProfileTableItemBase: SBAProfileTableItem {
    open var title: String
    private var _detail: String?
    open var detail: String? { return _detail }
    open var isEditable: Bool
    private var onSelectedExplicitlySet: SBAProfileOnSelectedAction? = nil
    open var onSelected: SBAProfileOnSelectedAction {
        get {
            return onSelectedExplicitlySet ?? self.defaultOnSelectedAction()
        }
        set {
            onSelectedExplicitlySet = newValue
        }
    }
    
    /// Override this in subclasses to set a default onSelected action if not otherwise specified.
    /// - returns: the default action to perform when the item is selected, if onSelected is not explicitly set.
    open func defaultOnSelectedAction() -> SBAProfileOnSelectedAction {
        return .noAction
    }
    
    // MARK: Decoder
    private enum CodingKeys: String, CodingKey {
        case title, detail, isEditable, onSelected
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        _detail = try container.decodeIfPresent(String.self, forKey: .detail)
        isEditable = try container.decodeIfPresent(Bool.self, forKey: .isEditable) ?? false
        
        // only override the default value if explicitly set in the decoder
        if let onSelectedDecodedString = try container.decodeIfPresent(String.self, forKey: .onSelected) {
            onSelected = SBAProfileOnSelectedAction(rawValue: onSelectedDecodedString)
        }
    }
}

open class SBAHTMLProfileTableItem: SBAProfileTableItemBase {
    /// Override to return .showHTML as the default onSelected action.
    override open func defaultOnSelectedAction() -> SBAProfileOnSelectedAction {
        return .showHTML
    }
    
    open var htmlResource: String
    
    open var html: String? {
        return SBAResourceFinder.shared.html(forResource: htmlResource)
    }
    
    open var url: URL? {
        if htmlResource.hasPrefix("http") || htmlResource.hasPrefix("file") {
            return URL(string: htmlResource)
        }
        else {
            return SBAResourceFinder.shared.url(forResource: htmlResource, withExtension:"html")
        }
    }
    
    // MARK: Decoder
    private enum CodingKeys: String, CodingKey {
        case htmlResource
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        htmlResource = try container.decode(String.self, forKey: .htmlResource)
        
        try super.init(from: decoder)
        
        // HTML profile table items are not editable
        self.isEditable = false
    }
}

/* TODO: emm 2018-08-19 deal with this for mPower 2 2.1
open class SBAProfileItemProfileTableItem: SBAProfileTableItemBase {
    /// Override to return .editProfileItem as the default onSelected action.
    override open func defaultOnSelectedAction() -> SBAProfileOnSelectedAction {
        return .editProfileItem
    }
    
    open var profileItemKey: String
    
    lazy open var profileItem: SBAProfileItem = {
        let profileItems = SBAProfileManager.shared.profileItems()
        return profileItems[self.profileItemKey]!
    }()
    
    func itemDetailFor(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.calendar = Calendar.current
        return formatter.string(from: date)
    }
    
    open func dateAsItemDetail(_ date: Date) -> String {
        guard let format = DateFormatter.dateFormat(fromTemplate: "Mdy", options: 0, locale: Locale.current)
            else { return String(describing: date) }
        return self.itemDetailFor(date, format: format)
    }
    
    open func dateTimeAsItemDetail(_ dateTime: Date) -> String {
        guard let format = DateFormatter.dateFormat(fromTemplate: "yEMdhma", options: 0, locale: Locale.current)
            else { return String(describing: dateTime) }
        return self.itemDetailFor(dateTime, format: format)
    }
    
    open func timeOfDayAsItemDetail(_ timeOfDay: Date) -> String {
        guard let format = DateFormatter.dateFormat(fromTemplate: "hma", options: 0, locale: Locale.current)
            else { return String(describing: timeOfDay) }
        return self.itemDetailFor(timeOfDay, format: format)
    }
    
    public func centimetersToFeetAndInches(_ centimeters: Double) -> (feet: Double, inches: Double) {
        let inches = centimeters / 2.54
        return ((inches / 12.0).rounded(), inches.truncatingRemainder(dividingBy: 12.0))
    }
    
    @objc(hkQuantityheightAsItemDetail:)
    open func heightAsItemDetail(_ height: HKQuantity) -> String {
        let heightInCm = height.doubleValue(for: HKUnit(from: .centimeter)) as NSNumber
        return self.heightAsItemDetail(heightInCm)
    }
    
    open func heightAsItemDetail(_ height: NSNumber) -> String {
        let formatter = LengthFormatter()
        formatter.isForPersonHeightUse = true
        let meters = height.doubleValue / 100.0 // cm -> m
        return formatter.string(fromMeters: meters)
    }
    
    @objc(hkQuantityWeightAsItemDetail:)
    open func weightAsItemDetail(_ weight: HKQuantity) -> String {
        let weightInKg = weight.doubleValue(for: HKUnit(from: .kilogram)) as NSNumber
        return self.weightAsItemDetail(weightInKg)
    }
    
    open func weightAsItemDetail(_ weight: NSNumber) -> String {
        let formatter = MassFormatter()
        formatter.isForPersonMassUse = true
        return formatter.string(fromKilograms: weight.doubleValue)
    }
    
    override open var detail: String? {
        guard let value = profileItem.value else { return "" }
        if let surveyItem = SBASurveyFactory.profileQuestionSurveyItems?.find(withIdentifier: profileItemKey) as? SBAFormStepSurveyItem,
            let choices = surveyItem.items as? [SBAChoice] {
            let selected = (value as? [Any]) ?? [value]
            let textList = selected.map({ (obj) -> String in
                switch surveyItem.surveyItemType {
                case .form(.singleChoice), .form(.multipleChoice),
                     .dataGroups(.singleChoice), .dataGroups(.multipleChoice):
                    return choices.find({ SBAObjectEquality($0.choiceValue, obj) })?.choiceText ?? String(describing: obj)
                case .account(.profile):
                    guard let options = surveyItem.items as? [String],
                            options.count == 1,
                            let option = SBAProfileInfoOption(rawValue: options[0])
                        else { return String(describing: obj) }
                    switch option {
                    case .birthdate:
                        guard let date = obj as? Date else { return String(describing: obj) }
                        return self.dateAsItemDetail(date)
                    case .height:
                        // could reasonably be stored either as an HKQuantity, or as an NSNumber of cm
                        let hkHeight = obj as? HKQuantity
                        if hkHeight != nil {
                            return self.heightAsItemDetail(hkHeight!)
                        }
                        guard let nsHeight = obj as? NSNumber else { return String(describing: obj) }
                        return self.heightAsItemDetail(nsHeight)
                    case .weight:
                        // could reasonably be stored either as an HKQuantity, or as an NSNumber of kg
                        let hkWeight = obj as? HKQuantity
                        if hkWeight != nil {
                            return self.weightAsItemDetail(hkWeight!)
                        }
                        guard let nsWeight = obj as? NSNumber else { return String(describing: obj) }
                        return self.weightAsItemDetail(nsWeight)
                    default:
                        return String(describing: obj)
                    }
                default:
                    return String(describing: obj)
                }
            })
            return Localization.localizedJoin(textList: textList)
        }
        return String(describing: value)
    }
    
    open var answerMapKeys: [String: String]
    
    // MARK: Decoder
    private enum CodingKeys: String, CodingKey {
        case profileItemKey, answerMapKeys
    }
    
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        // HTML profile table items are not editable
        isEditable = false
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profileItemKey = try container.decode(String.self, forKey: .profileItemKey)
        answerMapKeys = try container.decodeIfPresent([String: String].self, forKey: .answerMapKeys) ?? [self.profileItemKey: self.profileItemKey]
    }
}
 */

open class SBAResourceProfileTableItem: SBAProfileTableItemBase {
    /// Override to return .showResource as the default onSelected action.
    override open func defaultOnSelectedAction() -> SBAProfileOnSelectedAction {
        return .showResource
    }

    open var resource: String
    
    // MARK: Decoder
    private enum CodingKeys: String, CodingKey {
        case resource
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resource = try container.decode(String.self, forKey: .resource)

        try super.init(from: decoder)
        
        // Resource profile table items are not editable
        self.isEditable = false
    }
}
