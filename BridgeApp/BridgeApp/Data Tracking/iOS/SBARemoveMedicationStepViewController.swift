//
//  SBARemoveMedicationStepViewController.swift
//  BridgeApp (iOS)
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

import UIKit

open class SBARemoveMedicationStepViewController: RSDTableStepViewController {
    
    override open var isForwardEnabled: Bool {
        return true
    }
    
    override open func registerReuseIdentifierIfNeeded(_ reuseIdentifier: String) {
        guard !_registeredIdentifiers.contains(reuseIdentifier) else { return }
        _registeredIdentifiers.insert(reuseIdentifier)
        
        if reuseIdentifier == SBARemoveMedicationDataSource.FieldIdentifiers.label.stringValue {
            tableView.register(SBAFormTitleTextCell.nib, forCellReuseIdentifier: reuseIdentifier)
            return
        }
        
        super.registerReuseIdentifierIfNeeded(reuseIdentifier)
    }
    private var _registeredIdentifiers = Set<String>()
    
    override open func configure(cell: UITableViewCell, in tableView: UITableView, at indexPath: IndexPath) {
        super.configure(cell: cell, in: tableView, at: indexPath)
        
        // TODO: medephillips 6/26/18 move this color to color theme and UIColor ext
        let redHeaderColor = UIColor(red: 238.0/255.0, green: 96.0/255.0, blue: 112.0/255.0, alpha: 1.0)
        self.navigationHeader?.backgroundColor = redHeaderColor
        self.statusBarBackgroundView?.backgroundColor = redHeaderColor
        self.navigationFooter?.nextButton?.setTitle(Localization.localizedString("MEDICATION_REMOVE_BUTTON_TEXT"), for: .normal)
        let buttonBackgroundColor = UIColor(red: 245.0/255.0, green: 179.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        self.navigationFooter?.nextButton?.backgroundColor = buttonBackgroundColor
        let textColor = UIColor(red: 26.0/255.0, green: 28.0/255.0, blue: 41.0/255.0, alpha: 1.0)
        self.navigationFooter?.nextButton?.setTitleColor(textColor, for: .normal)
        
        if let labelCell = cell as? SBAFormTitleTextCell {
            let underlinedPhrase = self.step.identifier
            let titleStr = String(format: Localization.localizedString("MEDICATION_REMOVE_TITLE_%@"), step.identifier)
            if let underlinedRange = titleStr.range(of: underlinedPhrase) {
                let underlinedIndex = titleStr.distance(from: titleStr.startIndex, to: underlinedRange.lowerBound)
                let attributedText = NSMutableAttributedString(string: titleStr)
                attributedText.addAttribute(NSAttributedStringKey.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: NSMakeRange(underlinedIndex, underlinedPhrase.count))
                labelCell.label.attributedText = attributedText
            }
            labelCell.subLabel.text = Localization.localizedString("MEDICATION_REMOVE_TEXT")
        }
    }
}

open class SBAFormTitleTextCell : RSDTextLabelCell {
    
    /// The text field associated with this cell.
    /// The label used to display text using this cell.
    @IBOutlet public var subLabel: UILabel!
    
    /// The nib to use with this cell. Default will instantiate a `SBAFormTitleTextCell`.
    open class var nib: UINib {
        let bundle = Bundle(for: SBAFormTitleTextCell.self)
        let nibName = String(describing: SBAFormTitleTextCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
}

/// A step used for logging symptoms.
open class SBARemoveMedicationStepObject : RSDUIStepObject, RSDStepViewControllerVendor {
    
    public func instantiateViewController(with taskPath: RSDTaskPath) -> (UIViewController & RSDStepController)? {
        return SBARemoveMedicationStepViewController(step: self)
    }
    
    /// Override to return a `SBASymptomLoggingDataSource`.
    open override func instantiateDataSource(with taskPath: RSDTaskPath, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBARemoveMedicationDataSource.init(identifier: identifier, step: self, taskPath: taskPath)
    }
}

/// A data source used to handle symptom logging.
open class SBARemoveMedicationDataSource : RSDTableDataSource {
    
    enum FieldIdentifiers : String, CodingKey {
        case label
    }
    
    public var identifier: String
    
    public var delegate: RSDTableDataSourceDelegate?
    
    public var step: RSDStep
    
    public var taskPath: RSDTaskPath!
    
    public var sections: [RSDTableSection]

    public init (identifier: String, step: RSDStep, taskPath: RSDTaskPath) {
        
        self.identifier = identifier
        self.step = step
        self.taskPath = taskPath
        self.sections = []
        
        sections.append(createFormTitleTextSection())
    }
    
    fileprivate func createFormTitleTextSection() -> RSDTableSection {
        let tableItem = RSDTableItem(identifier: FieldIdentifiers.label.stringValue, rowIndex: 0, reuseIdentifier: FieldIdentifiers.label.stringValue)
        let section = RSDTableSection(identifier: FieldIdentifiers.label.stringValue, sectionIndex: 0, tableItems: [tableItem])
        return section
    }
    
    internal var _currentTaskController: RSDModalStepTaskController?
    internal var _currentTableItem: RSDModalStepTableItem?
    
    // MARK: RSDModalStepTaskControllerDelegate
    
    open func goForward(with taskController: RSDModalStepTaskController) {
        self.delegate?.tableDataSource(self, didFinishWith: taskController.stepController)
    }

    /// Default behavior is to dismiss the view controller without changes.
    open func goBack(with taskController: RSDModalStepTaskController) {
        self.delegate?.tableDataSource(self, didFinishWith: taskController.stepController)
        _currentTaskController = nil
        _currentTableItem = nil
    }
    
    public func itemGroup(at indexPath: IndexPath) -> RSDTableItemGroup? {
        return nil
    }
    
    public func allAnswersValid() -> Bool {
        return true
    }
    
    public func saveAnswer(_ answer: Any, at indexPath: IndexPath) throws {
        
    }
    
    public func selectAnswer(item: RSDTableItem, at indexPath: IndexPath) throws -> (isSelected: Bool, reloadSection: Bool) {
        return (false, false)
    }
}
