//
//  SBALearnInfo.swift
//  BridgeApp
//
//  Copyright © 2016-2019 Sage Bionetworks. All rights reserved.
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
import Research

/// The learn info protocol is used by apps that display information about the research study using
/// a table view presentation.
public protocol SBALearnInfo {
    
    /// Access the SBALearnItem objects to show in the Learn tab table view.
    /// - parameter index: The index into the `SBALearnItem` array.
    /// - returns: The learn item.
    subscript(index: Int) -> SBALearnItem? { get }
    
    /// How many SBALearnItem objects to show.
    /// - returns: The count of learn items.
    var count: Int { get }
    
}

extension SBALearnInfo {
    
    /// Convenience method for getting the `SBALearnItem` for a table or collection using
    /// the `IndexPath`.  `IndexPath.section` is ignored.
    /// - parameter indexPath: The index path for the item to get.
    /// - returns:  The learnItem at that index path.
    public func item(at indexPath: IndexPath) -> SBALearnItem? {
        guard let item = self[indexPath.item] else {
            assertionFailure("no learn item at index \(indexPath.row)")
            return nil
        }
        return item
    }
}

fileprivate protocol SBALearnInfoList : SBALearnInfo {
    var rowItems: [SBALearnItemObject] { get }
}

/// `SBALearnInfo` implementation that uses a localizable plist.
public struct SBALearnInfoPList: SBALearnInfo {
    
    fileprivate let rowItems: [SBALearnItemObject]
    
    public init() {
        do {
            try self.init(name: "LearnInfo")
        }
        catch let err {
            assertionFailure("Failed to decode learn info: \(err)")
            self.init(rowItems: [])
        }
    }
    
    private init(rowItems: [SBALearnItemObject]) {
        self.rowItems = rowItems
    }
    
    public init(name: String, bundle: Bundle? = nil) throws {
        let resource = RSDResourceTransformerObject(resourceName: name)
        let (plistData, _) = try resource.resourceData(ofType: "plist", bundle: bundle)
        let decoder = try RSDFactory.shared.createDecoder(for: .plist)
        let list = try decoder.decode(SBALearnInfoObject.self, from: plistData)
        self.rowItems = list.rowItems
    }
}

/// `SBALearnInfo` implementation that can be decoded from JSON, PList, or Dictionary.
public struct SBALearnInfoObject: SBALearnInfo, Codable {
    fileprivate let rowItems: [SBALearnItemObject]
}

extension SBALearnInfoObject : SBALearnInfoList {
}

extension SBALearnInfoPList : SBALearnInfoList {
}

extension SBALearnInfoList {
    
    public subscript(index: Int) -> SBALearnItem? {
        guard index >= 0 && index < rowItems.count else {
            assertionFailure("index \(index) out of bounds (0...\(rowItems.count))")
            return nil
        }
        return rowItems[index]
    }
    
    public var count : Int {
        return rowItems.count
    }
}
