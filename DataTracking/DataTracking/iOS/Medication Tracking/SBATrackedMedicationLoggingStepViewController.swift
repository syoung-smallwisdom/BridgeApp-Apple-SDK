//
//  SBATrackedMedicationLoggingStepViewController.swift
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
import Research
import ResearchUI

/// Extend `SBAMedicationLoggingStepObject` to implement the step view controller vendor.
extension SBAMedicationLoggingStepObject : RSDStepViewControllerVendor {
}

/// `SBATrackedMedicationLoggingStepViewController` is the default view controller shown for a `SBAMedicationLoggingStepObject`.
///
/// - seealso: `SBAMedicationLoggingStepObject`
open class SBATrackedMedicationLoggingStepViewController: SBAMedicationListStepViewController {
    
    override open func registerReuseIdentifierIfNeeded(_ reuseIdentifier: String) {
        guard !_registeredIdentifiers.contains(reuseIdentifier) else { return }
        _registeredIdentifiers.insert(reuseIdentifier)
        
        if reuseIdentifier == SBAMedicationLoggingCell.reuseId {
            tableView.register(SBAMedicationLoggingCell.nib, forCellReuseIdentifier: reuseIdentifier)
        }
        else {
            super.registerReuseIdentifierIfNeeded(reuseIdentifier)
        }
    }
    private var _registeredIdentifiers = Set<String>()
    
    override open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = super.tableView(tableView, viewForHeaderInSection: section)
        if let header = view as? RSDTableSectionHeader {
            
            // Keep a strong reference to the label so it sticks around when removeFromSuperview is called
            let titleLabelRef = header.titleLabel!
            if let constraints = titleLabelRef.rsd_constraint(for: .leading, relation: .equal) {
                titleLabelRef.rsd_alignToSuperview([.trailing], padding: constraints.constant)
            }
            
            // Style the header to match design
            let backgroundColor = self.designSystem.colorRules.backgroundPrimary
            header.contentView.backgroundColor = backgroundColor.color
            header.titleLabel.textColor = self.designSystem.colorRules.textColor(on: backgroundColor, for: .largeHeader)
            header.titleLabel.textAlignment = .center
            header.titleLabel.font = self.designSystem.fontRules.font(for: .largeHeader, compatibleWith: traitCollection)
        }
        return view
    }
    
    override open func configure(cell: UITableViewCell, in tableView: UITableView, at indexPath: IndexPath) {
        super.configure(cell: cell, in: tableView, at: indexPath)
        
        guard let source = tableData as? SBAMedicationLoggingDataSource,
            let tableItem = source.tableItem(at: indexPath) else {
                return
        }
        
        if let loggingCell = cell as? SBAMedicationLoggingCell {
            loggingCell.delegate = self
            loggingCell.tableItem = tableItem
        }
    }
    
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let source = tableData as? SBAMedicationLoggingDataSource,
            let tableItem = source.tableItem(at: indexPath) as? SBATrackedMedicationLoggingTableItem
            else {
                super.tableView(tableView, didSelectRowAt: indexPath)
                return
        }
        tableItem.isEditingDisplayTime = false
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func showTimeEditing(on cell: SBAMedicationLoggingCell) {
        cell.tableItem = cell.loggingTableItem
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    /// Called when a user action on a cell or button is linked to a modal item.
    override open func didSelectModalItem(_ modalItem: RSDModalStepTableItem, at indexPath: IndexPath) {
        // We don't actually want to show a modal but send the user to the review step
        guard let navigator = (self.stepViewModel.parentTaskPath?.task?.stepNavigator as? SBAMedicationTrackingStepNavigator),
            let reviewStep = navigator.getReviewStep() as? SBATrackedMedicationReviewStepObject else {
            return
        }
        self.assignSkipToIdentifier(reviewStep.identifier)
        self.goForward()
    }
}

extension SBATrackedMedicationLoggingStepViewController: SBAMedicationLoggingCellDelegate {
    public func timeUpdated(cell: SBAMedicationLoggingCell) {
        guard let source = tableData as? SBAMedicationLoggingDataSource,
            let loggingItem = cell.loggingTableItem else {
                return
        }
        source.updateLoggingDetails(for: loggingItem, at: cell.indexPath)
    }
    
    public func logTapped(cell: SBAMedicationLoggingCell) {
        updateLogging(for: cell)
    }
    
    public func undoTapped(cell: SBAMedicationLoggingCell) {
        updateLogging(for: cell)
    }
    
    func updateLogging(for cell: SBAMedicationLoggingCell) {
        guard let source = tableData as? SBAMedicationLoggingDataSource,
            let loggingItem = cell.loggingTableItem else {
                return
        }
        if loggingItem.dosage.isAnytime ?? true, let indexPath = cell.indexPath {
            source.reloadLoggingDetails(for: loggingItem, at: cell.indexPath)
            self.tableView.reloadSections([indexPath.section], with: .none)
        }
        else {
            source.updateLoggingDetails(for: loggingItem, at: cell.indexPath)
            cell.tableItem = loggingItem
        }
    }

    public func timeTapped(cell: SBAMedicationLoggingCell) {
        guard let loggingItem = cell.loggingTableItem else { return }
        if loggingItem.isEditingDisplayTime {
            showTimeEditing(on: cell)
        } else {
            self.tableView.reloadRows(at: [loggingItem.indexPath], with: .automatic)
        }
    }
}

public protocol SBAMedicationLoggingCellDelegate : class, NSObjectProtocol {
    /// Called when the user taps the time button.
    func timeTapped(cell: SBAMedicationLoggingCell)
    func logTapped(cell: SBAMedicationLoggingCell)
    func undoTapped(cell: SBAMedicationLoggingCell)
    func timeUpdated(cell: SBAMedicationLoggingCell)
}

open class SBAMedicationLoggingCell: RSDTableViewCell {
    
    public enum BottomDividerType: Int {
        case thin   = 1
        case thick  = 8
    }
    
    public static let reuseId = "medicationLogging"
    
    public weak var delegate: SBAMedicationLoggingCellDelegate?
    
    fileprivate let titleLabelHeightConstant = CGFloat(64.0)
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelHeight: NSLayoutConstraint!
    
    @IBOutlet weak var weekdayLabel: UILabel!
    @IBOutlet weak var takeAnytimeLabel: UILabel!
    @IBOutlet weak var checkmarkView: RSDCheckmarkView!
    
    @IBOutlet weak var loggedView: UIView!
    @IBOutlet weak var loggedTimeButton: RSDUnderlinedButton!
    @IBOutlet weak var takenButton: RSDRoundedButton!
    @IBOutlet weak var undoButton: RSDUnderlinedButton!
    
    @IBOutlet weak var notLoggedView: UIView!
    @IBOutlet weak var notLoggedTimeLabel: UILabel!
    
    @IBOutlet weak var bottomDivider: UIView!
    @IBOutlet weak var bottomDividerHeight: NSLayoutConstraint!
    
    fileprivate let datePickerHeightConstant = CGFloat(162.0)
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerHeight: NSLayoutConstraint!
    
    var loggingTableItem: SBATrackedMedicationLoggingTableItem? {
        return self.tableItem as? SBATrackedMedicationLoggingTableItem
    }
    
    open override var usesTableBackgroundColor: Bool {
        return false
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        updateColorsAndFonts()
    }
    
    override open func setDesignSystem(_ designSystem: RSDDesignSystem, with background: RSDColorTile) {
        super.setDesignSystem(designSystem, with: background)
        updateColorsAndFonts()
    }
    
    func updateColorsAndFonts() {
        let designSystem = self.designSystem ?? RSDDesignSystem()
        let backgroundColor = self.backgroundColorTile ?? designSystem.colorRules.backgroundLight
        
        self.checkmarkView.backgroundColor = designSystem.colorRules.palette.secondary.normal.color
        self.titleLabel.textColor = designSystem.colorRules.textColor(on: backgroundColor, for: .mediumHeader)
        self.titleLabel.font = designSystem.fontRules.font(for: .mediumHeader, compatibleWith: traitCollection)
        self.weekdayLabel.textColor = designSystem.colorRules.textColor(on: backgroundColor, for: .small)
        self.weekdayLabel.font = designSystem.fontRules.font(for: .small, compatibleWith: traitCollection)
        self.notLoggedTimeLabel.textColor = designSystem.colorRules.textColor(on: backgroundColor, for: .body)
        self.notLoggedTimeLabel.font = designSystem.fontRules.font(for: .body, compatibleWith: traitCollection)
        self.takeAnytimeLabel.text = Localization.localizedString("MEDICATION_TAKE_ANYTIME")
        self.takeAnytimeLabel.textColor = designSystem.colorRules.textColor(on: backgroundColor, for: .body)
        self.takeAnytimeLabel.font = designSystem.fontRules.font(for: .body, compatibleWith: traitCollection)
        
        self.loggedTimeButton.setDesignSystem(designSystem, with: backgroundColor)
        self.undoButton.setDesignSystem(designSystem, with: backgroundColor)
        self.takenButton.setDesignSystem(designSystem, with: backgroundColor)
        
        updateDividerColor()
    }
    
    func updateDividerColor() {
        let designSystem = self.designSystem ?? RSDDesignSystem()
        self.bottomDivider.backgroundColor = (self.bottomDividerType == .thin) ?
            designSystem.colorRules.separatorLine :
            designSystem.colorRules.backgroundPrimary.color
    }
    
    override open var tableItem: RSDTableItem! {
        didSet {
            guard let loggingItem = self.loggingTableItem else { return }
            
            self.titleLabel.text = loggingItem.title
            self.isTitleHidden = loggingItem.groupIndex != 0
            
            self.bottomDividerType = (loggingItem.groupIndex == (loggingItem.groupCount - 1)) ? .thick : .thin
            
            self.weekdayLabel.text = loggingItem.detail
            
            let isLogged = loggingItem.loggedDate != nil
            self.loggedView.isHidden = !isLogged
            self.notLoggedView.isHidden = isLogged
            
            self.loggedTimeButton.isHidden = (loggingItem.timeText == nil)
            self.notLoggedTimeLabel.isHidden = (loggingItem.timeText == nil)
            let timeFormat = !isLogged ? "%@" : Localization.localizedString("MEDICATION_LOGGING_TIME_EDIT_%@")
            if let timeText = loggingItem.timeText {
                let timeStr = String(format: timeFormat, timeText)
                self.loggedTimeButton.setTitle(timeStr, for: .normal)
                self.notLoggedTimeLabel.text = timeStr
                self.takeAnytimeLabel.isHidden = true
            }
            else {
                self.takeAnytimeLabel.isHidden = false
                self.weekdayLabel.isHidden = true
                self.notLoggedTimeLabel.isHidden = true
            }
            
            self.datePicker.date = loggingItem.displayDate ?? Date()
            if loggingItem.isEditingDisplayTime {
                self.datePickerHeight.constant = self.datePickerHeightConstant
            } else {
                self.datePickerHeight.constant = 0
            }
        }
    }
    
    open var hasBeenLogged: Bool {
        guard let loggingItem = self.loggingTableItem else { return false }
        return loggingItem.loggedDate == nil
    }
    
    open var isTitleHidden: Bool = false {
        didSet {
            self.titleLabel.isHidden = self.isTitleHidden
            self.titleLabelHeight.constant = self.isTitleHidden ? 0 : self.titleLabelHeightConstant
        }
    }
    
    open var bottomDividerType: BottomDividerType = .thin {
        didSet {
            self.bottomDividerHeight.constant = CGFloat(self.bottomDividerType.rawValue)
            updateDividerColor()
        }
    }
    
    /// The nib to use with this cell. Default will instantiate a `SBAMedicationLoggingCell`.
    open class var nib: UINib {
        let bundle = Bundle.module
        let nibName = String(describing: SBAMedicationLoggingCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
    
    @IBAction func takenTapped() {
        guard let loggingItem = self.loggingTableItem else { return }
        loggingItem.logTimestamp()
        self.delegate?.logTapped(cell: self)
    }
    
    @IBAction func undoTapped() {
        guard let loggingItem = self.loggingTableItem else { return }
        loggingItem.undo()
        self.delegate?.undoTapped(cell: self)
    }
    
    @IBAction func timeTapped() {
        guard let loggingItem = self.loggingTableItem else { return }
        loggingItem.isEditingDisplayTime = !loggingItem.isEditingDisplayTime
        self.delegate?.timeTapped(cell: self)
    }
    
    @IBAction func timeUpdated() {
        guard let loggingItem = self.loggingTableItem else { return }
        loggingItem.loggedDate = self.datePicker.date
        self.tableItem = loggingItem
        self.delegate?.timeUpdated(cell: self)
    }
}
