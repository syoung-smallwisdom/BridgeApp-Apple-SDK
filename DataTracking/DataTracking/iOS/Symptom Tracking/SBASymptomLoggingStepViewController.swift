//
//  SBASymptomLoggingStepViewController.swift
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

open class SBASymptomLoggingStepViewController: RSDTableStepViewController {
    
    override open func registerReuseIdentifierIfNeeded(_ reuseIdentifier: String) {
        guard !_registeredIdentifiers.contains(reuseIdentifier) else { return }
        _registeredIdentifiers.insert(reuseIdentifier)
        
        let reuseId = RSDFormUIHint(rawValue: reuseIdentifier)
        switch reuseId {
        case .logging:
            tableView.register(SBASymptomLoggingCell.nib, forCellReuseIdentifier: reuseIdentifier)
        default:
            super.registerReuseIdentifierIfNeeded(reuseIdentifier)
        }
    }
    private var _registeredIdentifiers = Set<String>()
    
    override open func configure(cell: UITableViewCell, in tableView: UITableView, at indexPath: IndexPath) {
        super.configure(cell: cell, in: tableView, at: indexPath)
        if let symptomCell = cell as? SBASymptomLoggingCell {
            symptomCell.delegate = self
            symptomCell.prepareForInsertion(into: tableView)
            symptomCell.inlineTimePicker.isOpen = (indexPath == _activeIndexPath)
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

extension SBASymptomLoggingStepViewController : SBASymptomLoggingCellDelegate {

    public func didChangeSeverity(for cell: SBASymptomLoggingCell, selected: Int) {
        _endTimeEditingIfNeeded()
        guard let dataSource = self.tableData as? SBASymptomLoggingDataSource,
            let tableItem = cell.tableItem as? SBASymptomTableItem
            else {
                assertionFailure("Failed to change severity. Could not get table source or table item.")
                return
        }
        tableItem.severity = SBASymptomSeverityLevel(rawValue: selected)
        dataSource.updateResults(with: tableItem)
    }
    
    public func didChangeMedicationTiming(for cell: SBASymptomLoggingCell, selected: Int) {
        _endTimeEditingIfNeeded()
        guard let dataSource = self.tableData as? SBASymptomLoggingDataSource,
            let tableItem = cell.tableItem as? SBASymptomTableItem
            else {
                assertionFailure("Failed to change severity. Could not get table source or table item.")
                return
        }
        tableItem.medicationTiming = SBASymptomMedicationTiming(intValue: selected)
        dataSource.updateResults(with: tableItem)
    }
    
    public func didTapTime(for cell: SBASymptomLoggingCell) {
        _endTimeEditingIfNeeded()
        _activeIndexPath = cell.indexPath
        self.tableView.reloadRows(at: [cell.indexPath], with: .none)
    }
    
    private func _endTimeEditingIfNeeded(_ shouldCollapse: Bool = true) {
        guard let indexPath = _activeIndexPath,
            let loggingItem = self.tableData?.tableItem(at: indexPath) as? SBASymptomTableItem,
            let dataSource = self.tableData as? SBASymptomLoggingDataSource,
            let cell = tableView.cellForRow(at: indexPath) as? SBASymptomLoggingCell
            else {
                return
        }
        let time = cell.timePicker.date
        loggingItem.time = time
        dataSource.updateResults(with: loggingItem)
        _activeIndexPath = nil
        if shouldCollapse {
            self.tableView.reloadRows(at: [cell.indexPath], with: .none)
        }
    }
    
    public func didTapAddDuration(for cell: SBASymptomLoggingCell) {
        _endTimeEditingIfNeeded()
        guard let loggingItem = cell.tableItem as? SBASymptomTableItem else { return }
        didSelectModalItem(loggingItem, at: cell.indexPath)
    }
}

public protocol SBASymptomLoggingCellDelegate : class, NSObjectProtocol {
    
    func didChangeSeverity(for cell: SBASymptomLoggingCell, selected: Int)
    
    func didTapTime(for cell: SBASymptomLoggingCell)
    
    func didTapAddDuration(for cell: SBASymptomLoggingCell)
    
    func didChangeMedicationTiming(for cell: SBASymptomLoggingCell, selected: Int)
}

/// Table view cell for logging symptoms.
open class SBASymptomLoggingCell: RSDTableViewCell {
    
    public weak var delegate: SBASymptomLoggingCellDelegate?
    
    /// The nib to use with this cell. Default will instantiate a `SBASymptomLoggingCell`.
    open class var nib: UINib {
        let bundle = Bundle.module
        let nibName = String(describing: SBASymptomLoggingCell.self)
        return UINib(nibName: nibName, bundle: bundle)
    }
    
    @IBOutlet open var titleLabel: UILabel!
    @IBOutlet open var subtitleLabel: UILabel!
    @IBOutlet open var severityButtons: [SBASeverityButton]!
    @IBOutlet open var timeButton: RSDUnderlinedButton!
    @IBOutlet open var durationButton: RSDUnderlinedButton!
    @IBOutlet open var timePicker: UIDatePicker!
    @IBOutlet open var medicationTimingButtons: [RSDCheckboxButton]!
    
    @IBOutlet open var separatorLines: [UIView]!
    @IBOutlet open var labels: [UILabel]!
    @IBOutlet var detailsListStackView: UIStackView!
    @IBOutlet var inlineTimePicker: RSDToggleConstraintView!
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        updateColors()
    }
    
    func updateColors() {
        let designSystem = self.designSystem ?? RSDDesignSystem()
        let background = self.backgroundColorTile ?? RSDGrayScale().white
        self.titleLabel.textColor = designSystem.colorRules.textColor(on: background, for: .smallHeader)
        self.subtitleLabel.textColor = designSystem.colorRules.textColor(on: background, for: .bodyDetail)
        for label in self.labels {
            label.textColor = designSystem.colorRules.textColor(on: background, for: .smallHeader)
        }
        for line in self.separatorLines {
            line.backgroundColor = designSystem.colorRules.separatorLine
        }
    }
    
    override open func setDesignSystem(_ designSystem: RSDDesignSystem, with background: RSDColorTile) {
        super.setDesignSystem(designSystem, with: background)
        self.contentView.backgroundColor = background.color
        updateColors()
    }
    
    override open var tableItem: RSDTableItem! {
        didSet {
            guard let loggingItem = tableItem as? SBASymptomTableItem
                else {
                    return
            }
            titleLabel.text = loggingItem.loggedResult.text
            subtitleLabel.text = loggingItem.loggedResult.detail
            let severity = loggingItem.severity?.rawValue ?? -1
            severityButtons.forEach { $0.isSelected = (severity == $0.tag) }
            timeButton?.setTitle(DateFormatter.localizedString(from: loggingItem.time, dateStyle: .none, timeStyle: .short), for: .normal)
            timePicker.date = loggingItem.time
            let durationTitle = loggingItem.duration?.text ?? Localization.localizedString("ADD_DURATION_BUTTON")
            durationButton?.setTitle(durationTitle, for: .normal)
            let medicationTiming = loggingItem.medicationTiming?.intValue ?? -1
            medicationTimingButtons.forEach { $0.isSelected = (medicationTiming == $0.tag) }
        }
    }
    
    @IBAction func severityTapped(_ sender: SBASeverityButton) {
        if sender.isSelected {
            sender.isSelected = false
            self.delegate?.didChangeSeverity(for: self, selected: -1)
        }
        else {
            self.severityButtons.forEach { $0.isSelected = (sender.tag == $0.tag) }
            self.delegate?.didChangeSeverity(for: self, selected: sender.tag)
        }
    }
    
    @IBAction func timeTapped(_ sender: Any) {
        self.delegate?.didTapTime(for: self)
    }
    
    @IBAction func addDurationTapped(_ sender: Any) {
        self.delegate?.didTapAddDuration(for: self)
    }
    
    @IBAction func medicationTimingTapped(_ sender: RSDCheckboxButton) {
        if sender.isSelected {
            sender.isSelected = false
            self.delegate?.didChangeMedicationTiming(for: self, selected: -1)
        }
        else {
            self.medicationTimingButtons.forEach {
                $0.isSelected = (sender.tag == $0.tag)
            }
            self.delegate?.didChangeMedicationTiming(for: self, selected: sender.tag)
        }
    }
    
    open func prepareForInsertion(into tableView: UITableView) {
        if detailsListStackView.axis == .horizontal,
            tableView.bounds.width <= 320 {
            detailsListStackView.axis = .vertical
        }
    }
}

@IBDesignable
open class SBASeverityButton : UIButton, RSDViewDesignable {
    
    open private(set) var backgroundColorTile: RSDColorTile?
    
    open private(set) var designSystem: RSDDesignSystem?
    
    override open var tag: Int {
        didSet {
            _updateBackgroundColor()
        }
    }
    
    override open var isSelected: Bool {
        didSet {
            _updateBackgroundColor()
        }
    }
    
    private func _updateBackgroundColor() {
        let designSystem = self.designSystem ?? RSDDesignSystem()
        let background = designSystem.colorRules.backgroundLight
        let textNormalColor = severityColorScale.stroke(for: self.tag, isSelected: false)
        let textSelectedColor = designSystem.colorRules.textColor(on: background, for: .body)
        setTitleColor(textNormalColor, for: .normal)
        setTitleColor(textSelectedColor, for: .selected)
        self.backgroundColor = _fillColor()
        self.layer.borderColor = _strokeColor().cgColor
    }
    
    private func _fillColor() -> UIColor {
        return severityColorScale.fill(for: self.tag, isSelected: isSelected)
    }
    
    private func _strokeColor() -> UIColor {
        return severityColorScale.stroke(for: self.tag, isSelected: isSelected)
    }
    
    lazy var severityColorScale: RSDSeverityColorScale =
        (self.designSystem ?? RSDDesignSystem()).colorRules.severityColorScale
    
    public func setDesignSystem(_ designSystem: RSDDesignSystem, with background: RSDColorTile) {
        self.designSystem = designSystem
        self.backgroundColorTile = background
        self.severityColorScale = designSystem.colorRules.severityColorScale
        _updateBackgroundColor()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 3.0
        layer.borderWidth = 1.0
        _updateBackgroundColor()
    }
}
