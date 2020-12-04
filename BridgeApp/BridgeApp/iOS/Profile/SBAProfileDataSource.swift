//
//  SBAProfileDataSource.swift
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

/// The type of a profile data source. This is used to decode the data source in a factory.
public struct SBAProfileDataSourceType : RawRepresentable, Codable {
    public typealias RawValue = String
    
    public private(set) var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Defaults to creating a `SBAProfileDataSourceObject`.
    public static let profileDataSource: SBAProfileDataSourceType = "profileDataSource"
    
    /// List of all the standard types.
    public static func allStandardTypes() -> [SBAProfileDataSourceType] {
        return [.profileDataSource]
    }
}

extension SBAProfileDataSourceType : Equatable {
    public static func ==(lhs: SBAProfileDataSourceType, rhs: SBAProfileDataSourceType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func ==(lhs: String, rhs: SBAProfileDataSourceType) -> Bool {
        return lhs == rhs.rawValue
    }
    public static func ==(lhs: SBAProfileDataSourceType, rhs: String) -> Bool {
        return lhs.rawValue == rhs
    }
}

extension SBAProfileDataSourceType : Hashable {
    public var hashValue : Int {
        return self.rawValue.hashValue
    }
}

extension SBAProfileDataSourceType : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension SBAProfileDataSourceType {
    static func allCodingKeys() -> [String] {
        return allStandardTypes().map{ $0.rawValue }
    }
}

/// The type of a profile table section. This is used to decode the section in a factory.
public struct SBAProfileSectionType : RawRepresentable, Codable {
    public typealias RawValue = String
    
    public private(set) var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// Defaults to creating a `SBAProfileSectionObject`.
    public static let profileSection: SBAProfileSectionType = "profileSection"
    
    /// List of all the standard types.
    public static func allStandardTypes() -> [SBAProfileSectionType] {
        return [.profileSection]
    }
}

extension SBAProfileSectionType : Equatable {
    public static func ==(lhs: SBAProfileSectionType, rhs: SBAProfileSectionType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func ==(lhs: String, rhs: SBAProfileSectionType) -> Bool {
        return lhs == rhs.rawValue
    }
    public static func ==(lhs: SBAProfileSectionType, rhs: String) -> Bool {
        return lhs.rawValue == rhs
    }
}

extension SBAProfileSectionType : Hashable {
    public var hashValue : Int {
        return self.rawValue.hashValue
    }
}

extension SBAProfileSectionType : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension SBAProfileSectionType {
    static func allCodingKeys() -> [String] {
        return allStandardTypes().map{ $0.rawValue }
    }
}

/// A protocol for defining a profile data source.
public protocol SBAProfileDataSource: class {
    /// A unique identifier for the data source.
    var identifier: String { get }
    
    /// Number of sections in the data source.
    /// - returns: Number of sections.
    func numberOfSections() -> Int
    
    /// Number of rows in the given section.
    /// - parameter section: The section of the collection.
    /// - returns: The number of rows in the given section.
    func numberOfRows(for section: Int) -> Int
    
    /// The profile table item at the given index.
    /// - parameter indexPath: The index path for the profile table item.
    func profileTableItem(at indexPath: IndexPath) -> SBAProfileTableItem?
    
    /// Title for the given section (if applicable).
    /// - parameter section: The section of the collection.
    /// - returns: The title for this section or `nil` if no title.
    func title(for section: Int) -> String?
    
    /// Image (icon) for the given section (if applicable).
    /// - parameter section: The section of the collection.
    /// - returns: The image for this section or `nil` if no image.
    func image(for section: Int) -> UIImage?
}


/// This extension provides stub implementations for 'optional' protocol methods.
public extension SBAProfileDataSource {
    func title(for section: Int) -> String? {
        return nil
    }
    
    func image(for section: Int) -> UIImage? {
        return nil
    }
}

open class SBAProfileDataSourceObject: Decodable, SBAProfileDataSource {
    static let defaultIdentifier: String = "ProfileDataSource"
    
    /// Return the default instance of the Profile Data Source from the shared Bridge configuration.
    public static var shared: SBAProfileDataSource {
        return SBABridgeConfiguration.shared.profileDataSource(for: SBAProfileDataSourceObject.defaultIdentifier) ?? SBAProfileDataSourceObject()
    }
    
    public private(set) var identifier: String = ""
    
    private var sections: [SBAProfileSection] = [SBAProfileSection]()

    public init() {
    }
    
    // MARK: Decoder
    private enum CodingKeys: String, CodingKey {
        case identifier, sections
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
        self.identifier = try container.decodeIfPresent(String.self, forKey: .identifier) ?? SBAProfileDataSourceObject.defaultIdentifier
        if container.contains(.sections) {
            var sections: [SBAProfileSection] = []
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .sections)
            while !nestedContainer.isAtEnd {
                let sectionDecoder = try nestedContainer.superDecoder()
                let sectionTypeName = try typeName(from: sectionDecoder)
                let sectionType = SBAProfileSectionType(rawValue: sectionTypeName)
                if let section = try decodeSection(from: sectionDecoder, with: sectionType) {
                    sections.append(section)
                }
            }
            self.sections = sections
        }
    }

    /// Decode the profile table section from this decoder.
    ///
    /// Override in subclasses to add support for additional section types. One reason you might do this is
    /// to use a subclass of SBAProfileSectionObject you've created that supports additional profile table
    /// item types.
    ///
    /// - parameters:
    ///     - type:        The `ProfileSectionType` to instantiate.
    ///     - decoder:     The decoder to use to instatiate the object.
    /// - returns: The profile item (if any) created from this decoder.
    /// - throws: `DecodingError` if the object cannot be decoded.
    open func decodeSection(from decoder:Decoder, with type:SBAProfileSectionType) throws -> SBAProfileSection? {
        
        switch (type) {
        case .profileSection:
            return try SBAProfileSectionObject(from: decoder)
        default:
            assertionFailure("Attempt to decode profile section of unknown type \(type.rawValue)")
            return nil
        }
    }

    // MARK: SBAProfileDataSource
    
    open func numberOfSections() -> Int {
        return sections.count
    }
    
    open func numberOfRows(for section: Int) -> Int {
        guard section < sections.count else { return 0 } // out of range
        return sections[section].items.count
    }
    
    open func profileTableItem(at indexPath: IndexPath) -> SBAProfileTableItem? {
        let section = indexPath.section
        let row = indexPath.row
        
        guard (section < sections.count) && (row < sections[section].items.count) else { return nil }
        
        return sections[section].items[row]
    }
    
    open func title(for section: Int) -> String? {
        guard section < sections.count else { return nil }
        return sections[section].title
    }
    
    open func image(for section: Int) -> UIImage? {
        guard section < sections.count else { return nil }
        guard let imageName = sections[section].icon else { return nil }
        return UIImage(named: imageName)
    }
}
