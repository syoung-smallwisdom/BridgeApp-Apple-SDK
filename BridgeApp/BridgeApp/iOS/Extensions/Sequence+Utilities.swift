//
//  Sequence+Utilities.swift
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

extension Dictionary where Value : NSObjectProtocol {
    
    public func sba_uniqueCount() -> Int {
        return NSSet(array: (self as NSDictionary).allValues ).count
    }
}

extension Array where Element : NSObjectProtocol {
    
    public func sba_uniqueCount() -> Int {
        return NSSet(array: self).count
    }
    
    /// Create a union set of two arrays where the elements of this array are replaced with the elements of
    /// the `other` array if the `evaluate` block evaluates to `true`.
    ///
    /// - parameters:
    ///     - other: The other array with which this one should be unioned.
    ///     - evaluate: The function to use to evaluate the search pattern.
    /// - returns: The elements that match the pattern.
    public func sba_union(with other:[Element], where evaluate: (Element, Element) throws -> Bool) rethrows -> [Element] {
        var results = self
        try other.forEach { (element) in
            if let idx = try results.firstIndex(where: { try evaluate($0, element) }) {
                results.remove(at: idx)
            }
            results.append(element)
        }
        return results
    }
}

extension Dictionary where Value : Hashable {

    public func sba_uniqueCount() -> Int {
        return Set(self.values).count
    }
}

extension Array where Element : Hashable {

    public func sba_uniqueCount() -> Int {
        return Set(self).count
    }
}
