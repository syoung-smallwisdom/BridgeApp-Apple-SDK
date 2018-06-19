//
//  SBATrackedMedicationDetailStepViewController.swift
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

open class SBATrackedMedicationDetailStepViewController: RSDTableStepViewController {
    
    override open func registerReuseIdentifierIfNeeded(_ reuseIdentifier: String) {
        guard !_registeredIdentifiers.contains(reuseIdentifier) else { return }
        _registeredIdentifiers.insert(reuseIdentifier)
        
        let reuseId = RSDFormUIHint(rawValue: reuseIdentifier)
        switch reuseId {
        case .textfield:
            tableView.register(SBATrackedTextfieldCell.nib, forCellReuseIdentifier: reuseIdentifier)
            break
        default:
            if reuseIdentifier == SBATrackedWeeklyScheduleCell.reuseId {
                tableView.register(SBATrackedWeeklyScheduleCell.nib, forCellReuseIdentifier: reuseIdentifier)
            } else {
                super.registerReuseIdentifierIfNeeded(reuseIdentifier)
            }
            break
        }
    }
    private var _registeredIdentifiers = Set<String>()
    
    override open func configure(cell: UITableViewCell, in tableView: UITableView, at indexPath: IndexPath) {
        super.configure(cell: cell, in: tableView, at: indexPath)
        if let weeklySchedule = cell as? SBATrackedWeeklyScheduleCell {
            weeklySchedule.delegate = self
            //weeklySchedule.prepareForInsertion(into: tableView)
            weeklySchedule.inlineTimePicker.isOpen = (indexPath == _activeIndexPath)
        }
        if let dosageCell = cell as? SBATrackedTextfieldCell {
            dosageCell.textField.delegate = self
        }
    }
    
    private var _activeIndexPath: IndexPath?
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _endTimeEditingIfNeeded()
        super.tableView(tableView, didSelectRowAt: indexPath)
    }
    
    open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        _endTimeEditingIfNeeded()
        return indexPath.section == 0 ? nil : indexPath
    }
    
    open override func goForward() {
        _endTimeEditingIfNeeded(false)
        super.goForward()
    }
}

extension SBATrackedMedicationDetailStepViewController : SBATrackedWeeklyScheduleCellDelegate {
    public func didTapDay(for cell: SBATrackedWeeklyScheduleCell) {
        _endTimeEditingIfNeeded()
    }

    public func didChangeDay(for cell: SBATrackedWeeklyScheduleCell, selected: Int) {
        _endTimeEditingIfNeeded()
//        guard let loggingItem = cell.tableItem as? SBASymptomTableItem else { return }
//        didSelectModalItem(loggingItem, at: cell.indexPath)
//        guard let dataSource = self.tableData as? SBATrackedMedicationDetailDataSource,
//            let tableItem = cell.tableItem as? SBASymptomTableItem
//            else {
//                assertionFailure("Failed to change severity. Could not get table source or table item.")
//                return
//        }
//        tableItem.severity = SBASymptomSeverityLevel(rawValue: selected)
//        dataSource.updateResults(with: tableItem)
    }
    
    public func didChangeTiming(for cell: SBATrackedWeeklyScheduleCell, selected: Int) {
        _endTimeEditingIfNeeded()
//        guard let dataSource = self.tableData as? SBATrackedMedicationDetailDataSource,
//            let tableItem = cell.tableItem as? SBASymptomTableItem
//            else {
//                assertionFailure("Failed to change severity. Could not get table source or table item.")
//                return
//        }
//        tableItem.medicationTiming = SBASymptomMedicationTiming(intValue: selected)
//        dataSource.updateResults(with: tableItem)
    }
    
    public func didTapTime(for cell: SBATrackedWeeklyScheduleCell) {
        _endTimeEditingIfNeeded()
        _activeIndexPath = cell.indexPath
        self.tableView.reloadRows(at: [cell.indexPath], with: .none)
    }
    
    private func _endTimeEditingIfNeeded(_ shouldCollapse: Bool = true) {
        guard let indexPath = _activeIndexPath,
//            let scheduleItem = self.tableData?.tableItem(at: indexPath) as? SBASymptomTableItem,
            //let dataSource = self.tableData as? SBATrackedMedicationDetailDataSource,
            let cell = tableView.cellForRow(at: indexPath) as? SBATrackedWeeklyScheduleCell
            else {
                return
        }
        //let time = cell.timePicker.date
        //loggingItem.time = time
        //dataSource.updateResults(with: loggingItem)
        _activeIndexPath = nil
        if shouldCollapse {
            self.tableView.reloadRows(at: [cell.indexPath], with: .none)
        }
    }
    
    public func didChangeEveryDaySelection(for cell: SBATrackedWeeklyScheduleCell, selected: Bool) {
        _endTimeEditingIfNeeded()
    }
}

public protocol SBATrackedWeeklyScheduleCellDelegate : class, NSObjectProtocol {
    
    func didTapDay(for cell: SBATrackedWeeklyScheduleCell)
    
    func didTapTime(for cell: SBATrackedWeeklyScheduleCell)
    
    func didChangeEveryDaySelection(for cell: SBATrackedWeeklyScheduleCell, selected: Bool)
    
    func didChangeTiming(for cell: SBATrackedWeeklyScheduleCell, selected: Int)
}

open class SBATrackedTextfieldCell : RSDTableViewCell {
    
    /// The text field associated with this cell.
    @IBOutlet weak var textField: RSDStepTextField!
    /// The label used to display the prompt for the input field.
    @IBOutlet weak var fieldLabel: UILabel!
    /// A line show below the text field.
    @IBOutlet weak var ruleView: UIView!
    
    /// The nib to use with this cell. Default will instantiate a `SBATrackedMedicationDetailCell`.
    open class var nib: UINib {
        let bundle = Bundle(for: SBATrackedTextfieldCell.self)
        let nibName = String(describing: SBATrackedTextfieldCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
}

open class TrackedTextField: RSDStepTextField {
    
    let padding = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24);
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
}

/// Table view cell for logging symptoms.
open class SBATrackedWeeklyScheduleCell: RSDTableViewCell {
    
    public static let reuseId = "weeklySchedule"
    
    public weak var delegate: SBATrackedWeeklyScheduleCellDelegate?
    
    /// The nib to use with this cell. Default will instantiate a `SBATrackedMedicationDetailCell`.
    open class var nib: UINib {
        let bundle = Bundle(for: SBATrackedWeeklyScheduleCell.self)
        let nibName = String(describing: SBATrackedWeeklyScheduleCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
    
    @IBOutlet open var titleLabel: UILabel!
    @IBOutlet open var timeButton: UIButton!
    @IBOutlet open var timePicker: UIDatePicker!
    @IBOutlet open var dayButton: UIButton!
    @IBOutlet open var everydayCheckbox: RSDCheckboxButton!
    
    @IBOutlet open var separatorLines: [UIView]!
    @IBOutlet open var labels: [UILabel]!
    @IBOutlet var inlineTimePicker: RSDToggleConstraintView!
    
    /// Override to set the content view background color to the color of the table background.
    override open var tableBackgroundColor: UIColor! {
        didSet {
            self.contentView.backgroundColor = tableBackgroundColor
        }
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        self.titleLabel.textColor = UIColor.rsd_headerTitleLabel
        for label in self.labels {
            label.textColor = UIColor.rsd_headerTitleLabel
        }
        for line in self.separatorLines {
            line.backgroundColor = UIColor.rsd_cellSeparatorLine
        }
    }
    
    override open var tableItem: RSDTableItem! {
        didSet {
            guard let loggingItem = tableItem as? SBASymptomTableItem
                else {
                    return
            }
            titleLabel.text = loggingItem.loggedResult.text
            timeButton?.setTitle(DateFormatter.localizedString(from: loggingItem.time, dateStyle: .none, timeStyle: .short), for: .normal)
            timePicker.date = loggingItem.time
            let durationTitle = loggingItem.duration?.text ?? Localization.localizedString("ADD_DURATION_BUTTON")
            //durationButton?.setTitle(durationTitle, for: .normal)
            let medicationTiming = loggingItem.medicationTiming?.intValue ?? -1
            //medicationTimingButtons.forEach { $0.isSelected = (medicationTiming == $0.tag) }
        }
    }
    
    @IBAction func timeTapped(_ sender: Any) {
        self.delegate?.didTapTime(for: self)
    }
    
    @IBAction func dayTapped(_ sender: Any) {
        self.delegate?.didTapDay(for: self)
    }
    
    @IBAction func everydayTapped(_ sender: RSDCheckboxButton) {
        sender.isSelected = !sender.isSelected
        self.delegate?.didChangeEveryDaySelection(for: self, selected: sender.isSelected)
    }
}
