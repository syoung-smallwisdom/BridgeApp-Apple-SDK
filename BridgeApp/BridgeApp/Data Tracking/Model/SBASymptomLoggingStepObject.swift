//
//  SBASymptomLoggingStepObject.swift
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

/// A step used for logging symptoms.
open class SBASymptomLoggingStepObject : SBATrackedItemsLoggingStepObject {
    
    #if !os(watchOS)
    /// Override to return a symptom logging step view controller.
    override open func instantiateViewController(with taskPath: RSDTaskPath) -> (UIViewController & RSDStepController)? {
        return SBASymptomLoggingStepViewController(step: self)
    }
    #endif
    
    /// Override to return a `SBASymptomLoggingDataSource`.
    open override func instantiateDataSource(with taskPath: RSDTaskPath, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBASymptomLoggingDataSource(step: self, taskPath: taskPath)
    }
}

/// A data source used to handle symptom logging.
open class SBASymptomLoggingDataSource : SBATrackedLoggingDataSource {
    
    /// Override the instantiation of the table item to return a symptom table item.
    override open class func instantiateTableItem(at rowIndex: Int, inputField: RSDInputField, itemAnswer: SBATrackedItemAnswer, choice: RSDChoice) -> RSDTableItem {
        
        let loggedResult: SBATrackedLoggingResultObject = {
            if let result = itemAnswer as? SBATrackedLoggingResultObject {
                return result
            }
            else {
                var result = SBATrackedLoggingResultObject(identifier: itemAnswer.identifier, text: choice.text, detail: choice.detail)
                result.type = .symptom
                result.loggedDate = Date()
                return result
            }
        }()
        
        return SBASymptomTableItem(loggedResult: loggedResult, rowIndex: rowIndex)
    }
}

/// The severity level of the symptom being logged.
public enum SBASymptomSeverityLevel : Int, Codable {
    case none = 0, mild, moderate, severe
}

/// The medication timing for the symptom being logged
public enum SBASymptomMedicationTiming : String, Codable {
    case preMedication = "pre-medication"
    case postMedication = "post-medication"

    public var intValue: Int {
        return SBASymptomMedicationTiming.sortOrder.index(of: self)!
    }
    
    private static let sortOrder: [SBASymptomMedicationTiming] = [.preMedication, .postMedication]
}

/// The symptom table item is tracked using the result object.
open class SBASymptomTableItem : RSDTableItem {
    
    public enum ResultIdentifier : String, CodingKey, Codable {
        case severity, duration, medicationTiming, notes
    }
    
    /// The result object associated with this table item.
    public var loggedResult: SBATrackedLoggingResultObject
    
    /// The severity level of the symptom.
    public var severity : SBASymptomSeverityLevel? {
        get {
            guard let rawValue = loggedResult.findAnswerResult(with: ResultIdentifier.severity.rawValue)?.value as? Int
                else {
                    return nil
            }
            return SBASymptomSeverityLevel(rawValue: rawValue)
        }
        set {
            var answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.severity.rawValue, answerType: .integer)
            answerResult.value = newValue?.rawValue
            _appendResults(answerResult)
        }
    }
    
    /// The time when the symptom started occuring.
    public var time: Date {
        get {
            return loggedResult.loggedDate ?? Date()
        }
        set {
            loggedResult.loggedDate = newValue
        }
    }
    
    /// The duration window describing how long the symptoms occured.
    public var duration: String? {
        get {
            return loggedResult.findAnswerResult(with: ResultIdentifier.duration.rawValue)?.value as? String
        }
        set {
            var answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.duration.rawValue, answerType: .string)
            answerResult.value = newValue
            _appendResults(answerResult)
        }
    }
    
    /// The duration window describing how long the symptoms occured.
    public var medicationTiming: SBASymptomMedicationTiming? {
        get {
            guard let rawValue = loggedResult.findAnswerResult(with: ResultIdentifier.medicationTiming.rawValue)?.value as? String
                else {
                    return nil
            }
            return SBASymptomMedicationTiming(rawValue: rawValue)        }
        set {
            var answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.duration.rawValue, answerType: .string)
            answerResult.value = newValue?.rawValue
            _appendResults(answerResult)
        }
    }
    
    /// The duration window describing how long the symptoms occured.
    public var notes: String? {
        get {
            return loggedResult.findAnswerResult(with: ResultIdentifier.notes.rawValue)?.value as? String
        }
        set {
            var answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.notes.rawValue, answerType: .string)
            answerResult.value = newValue
            _appendResults(answerResult)
        }
    }
    
    private func _appendResults(_ answerResult: RSDAnswerResultObject) {
        loggedResult.appendInputResults(with: answerResult)
        if loggedResult.loggedDate == nil {
            loggedResult.loggedDate = Date()
        }
    }
    
    /// Initialize a new RSDTableItem.
    /// - parameters:
    ///     - identifier: The cell identifier.
    ///     - rowIndex: The index of this item relative to all rows in the section in which this item resides.
    ///     - reuseIdentifier: The string to use as the reuse identifier.
    public init(loggedResult: SBATrackedLoggingResultObject, rowIndex: Int, reuseIdentifier: String = RSDFormUIHint.logging.rawValue) {
        self.loggedResult = loggedResult
        super.init(identifier: loggedResult.identifier, rowIndex: rowIndex, reuseIdentifier: reuseIdentifier)
    }
}
