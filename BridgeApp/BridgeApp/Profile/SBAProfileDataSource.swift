//
//  SBAProfileDataSource.swift
//  BridgeAppSDK
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
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

public var SBAProfileJSONFilename = "Profile"
public var SBAProfileDataSourceClassType = "ProfileDataSource"

public protocol SBAProfileDataSource: class {
    /// Number of sections in the data source.
    /// - returns: Number of sections.
    func numberOfSections() -> Int
    
    /// Number of rows in the section.
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
    
    /// Image (icon) for the given section (if applicable)
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

open class SBAProfileDataSourceObject: NSObject, Decodable, SBAProfileDataSource {
    /// Return the shared instance of the Profile Data Source from the shared Bridge configuration.
    public static let shared: SBAProfileDataSource = {
        return SBABridgeConfiguration.shared.profileDataSource
    }()

    private var sections: [SBAProfileSection]

    public override init() {
        sections = [SBAProfileSection]()
        super.init()
    }
    
    // MARK: Decoder
    private enum CodingKeys: String, CodingKey {
        case sections
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        sections = try container.decodeIfPresent([SBAProfileSectionObject].self, forKey: .sections) ?? [SBAProfileSection]()
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
