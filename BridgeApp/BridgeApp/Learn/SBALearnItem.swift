//
//  SBALearnItem.swift
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

/// A learn item is intended for a table-style display of information about a research study.
public protocol SBALearnItem {
    
    /// Check validity as a SBALearnItem.
    func isValidLearnItem() -> Bool
    
    /// Title to show in the Learn tab table view cell.
    var learnTitle: String { get }
    
    /// Optional additional detail information about the learn item.
    var learnDetail: String? { get }
    
    /// Content file (html) to load for the Detail view for this item.
    var learnURL: URL { get }
    
    /// The image to use as the item's icon in the Learn tab table view cell.
    var learnIconImage: UIImage? { get }
}

/// The learn item object is a concrete, serializable implementation of the `SBALearnItem` protocol.
public struct SBALearnItemObject : SBALearnItem, Codable {
    private enum CodingKeys: String, CodingKey {
        case learnTitle = "title", learnDetail = "detail", href, iconImage
    }
    
    /// A valid learn item has an href value.
    public func isValidLearnItem() -> Bool {
        return (_learnURL != nil)
    }
    
    /// The title for the learn item.
    public let learnTitle : String

    /// The url for the learn item.
    public var learnURL: URL {
        return _learnURL!
    }
    private var _learnURL: URL? {
        if href.hasPrefix("http") || href.hasPrefix("file") {
            return URL(string: href)
        }
        else {
            let resource = RSDResourceTransformerObject(resourceName: href)
            do {
                let (url, _) = try resource.resourceURL(ofType: "html", bundle: nil)
                return url
            }
            catch let err {
                assertionFailure("Failed to get the url: \(err)")
                return nil
            }
        }
    }
    private let href: String
    
    /// An added detail string for the learn item.
    public let learnDetail: String?
    
    /// The image icon for the learn item.
    public var learnIconImage : UIImage? {
        guard let imageName = self.iconImage else { return nil }
        return UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
    }
    private let iconImage: String?
}
