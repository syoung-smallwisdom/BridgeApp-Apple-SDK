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

open class SBATrackedMedicationDetailStepViewController: RSDTableStepViewController, RSDTaskViewControllerDelegate {
    
    var selectedIndexPath: IndexPath?
    
    var underlinedButtonNib: UINib {
        let bundle = Bundle(for: SBATrackedMedicationDetailStepViewController.self)
        let nibName = "SBAUnderlinedButtonCell"
        return UINib(nibName: nibName, bundle: bundle)
    }
    
    var roundedButtonNib: UINib {
        let bundle = Bundle(for: SBATrackedMedicationDetailStepViewController.self)
        let nibName = "SBARoundedButtonCell"
        return UINib(nibName: nibName, bundle: bundle)
    }
    
    override open var isForwardEnabled: Bool {
        if let source = tableData as? SBATrackedWeeklyScheduleDataSource {
            return source.allAnswersValid()
        }
        return true
    }
    
    override open func registerReuseIdentifierIfNeeded(_ reuseIdentifier: String) {
        guard !_registeredIdentifiers.contains(reuseIdentifier) else { return }
        _registeredIdentifiers.insert(reuseIdentifier)
        
        if reuseIdentifier == SBATrackedWeeklyScheduleDataSource.FieldIdentifiers.header.stringValue {
            tableView.register(underlinedButtonNib, forCellReuseIdentifier: reuseIdentifier)
            return
        } else if reuseIdentifier == SBATrackedWeeklyScheduleDataSource.FieldIdentifiers.addSchedule.stringValue {
            tableView.register(roundedButtonNib, forCellReuseIdentifier: reuseIdentifier)
            return
        }
        
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
        if let weeklySchedule = cell as? SBATrackedWeeklyScheduleCell,
            let source = tableData as? SBATrackedWeeklyScheduleDataSource,
            let tableItem = source.tableItem(at: indexPath) {
            weeklySchedule.delegate = self
            weeklySchedule.inlineTimePicker.isOpen = (indexPath == _activeIndexPath)
            weeklySchedule.tableItem = tableItem
            let isLastScheduleItem = (indexPath.row == (source.schedulesSection.tableItems.count - 1))
            weeklySchedule.atAnytimeHidden = !isLastScheduleItem
        }
        if let dosageCell = cell as? SBATrackedTextfieldCell {
            dosageCell.textField.delegate = self
        }
        if let buttonCell = cell as? RSDButtonCell {
            if let _ = buttonCell.actionButton as? RSDUnderlinedButton {
                    buttonCell.actionButton.setTitle(Localization.localizedString("MEDICATION_REMOVE_MEDICATION"), for: .normal)
                buttonCell.actionButton.setTitleColor(UIColor.primaryTintColor, for: .normal)
                buttonCell.backgroundView?.backgroundColor = UIColor.appBackgroundDark
            }
            if let _ = buttonCell.actionButton as? RSDRoundedButton {
                buttonCell.actionButton.setTitle(Localization.localizedString("ADD_ANOTHER_SCHEDULE_BUTTON"), for: .normal)
            }
            buttonCell.delegate = self
        }
    }
    
    override open func didTapButton(on cell: RSDButtonCell) {
        if let _ = cell.actionButton as? RSDUnderlinedButton {
            removeMedicationTapped()
            return
        }
        if let _ = cell.actionButton as? RSDRoundedButton {
           addAnotherScheduleTapped()
            return
        }
        super.didTapButton(on: cell)
    }
    
    func removeMedicationTapped() {
        let removeStep = SBARemoveMedicationStepObject(identifier: step.identifier, type: .instruction)
        removeStep.imageTheme = SBAInstructionImage(identifier: "removeInstruction")
        removeStep.title = " " // adds some extra space
        var navigator = RSDConditionalStepNavigatorObject(with: [removeStep])
        navigator.progressMarkers = []
        let task = RSDTaskObject(identifier: step.identifier, stepNavigator: navigator)
        let taskVc = RSDTaskViewController(task: task)
        taskVc.delegate = self
        self.present(taskVc, animated: true, completion: nil)
    }
    
    func addAnotherScheduleTapped() {
        guard let source = tableData as? SBATrackedWeeklyScheduleDataSource else { return }
        source.addScheduleItem()
        // TODO: mdephillips 6/24/18 animate in new tableview cell and animate hiding other cell's checkbox
        self.tableView.reloadData()
    }
    
    override open func textFieldDidEndEditing(_ textField: UITextField) {
        // TODO: mdephillips 6/25/18 figure out why this isnt being done automatically
        if let source = tableData as? SBATrackedWeeklyScheduleDataSource {
            try? source.dosageTableItem?.setAnswer(textField.text)
        }
        self.answersDidChange(in: SBATrackedWeeklyScheduleDataSource.FieldIdentifiers.dosage.sectionIndex())
        super.textFieldDidEndEditing(textField)
    }
    
    public func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        
        // the user selected the "remove notification" instead of an indexPath schedule cell
        if self.selectedIndexPath == nil {
            if reason == .completed {
                if let source = tableData as? SBATrackedWeeklyScheduleDataSource {
                    source.appendRemoveMedicationToTaskPath()
                }
                super.jumpForward()
            }
        } else {
            self.selectedIndexPath = nil
            if reason == .completed {
                weak var weakSelf = self
                dismiss(animated: true, completion: {
                    weakSelf?.tableView.reloadData()
                })
                return
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    public func taskController(_ taskController: RSDTaskController, readyToSave taskPath: RSDTaskPath) {
        if let source = tableData as? SBATrackedWeeklyScheduleDataSource,
            let indexPath = self.selectedIndexPath,
            let selectedTableItem = source.sections[indexPath.section].tableItems[indexPath.row] as? SBATrackedWeeklyScheduleTableItem {
            if taskPath.result.stepHistory.count > 0,
                let collectionResult = taskPath.result.stepHistory[0] as? RSDCollectionResultObject {
                var weekdaysSelected = [RSDWeekday]()
                for weekdayResult in collectionResult.inputResults {
                    if let weekdayAnswerResult = weekdayResult as? RSDAnswerResultObject,
                        let weekdayValueArray = weekdayAnswerResult.value as? [Int] {
                        for weekdayInt in weekdayValueArray {
                            if let weekday = RSDWeekday(rawValue: weekdayInt) {
                                weekdaysSelected.append(weekday)
                            }
                        }
                    }
                }
                selectedTableItem.weekdays = weekdaysSelected
            }
        }
    }
    

    override open func actionTapped(with actionType: RSDUIActionType) -> Bool {
        if actionType == .navigation(.goForward),
            let source = tableData as? SBATrackedWeeklyScheduleDataSource {
            source.appendStepResultToTaskPathAndFinish(with: self)
        }
        return super.actionTapped(with: actionType)
    }
    
    public func taskController(_ taskController: RSDTaskController, asyncActionControllerFor configuration: RSDAsyncActionConfiguration) -> RSDAsyncActionController? {
        return nil
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
        guard let scheduleItem = cell.tableItem as? SBATrackedWeeklyScheduleTableItem,
            let source = tableData as? RSDModalStepDataSource
        else {
            assertionFailure("Cannot handle the button tap.")
            return
        }
        self.selectedIndexPath = cell.indexPath
        let step = source.step(for: scheduleItem)
        var navigator = RSDConditionalStepNavigatorObject(with: [step])
        navigator.progressMarkers = []
        let task = RSDTaskObject(identifier: step.identifier, stepNavigator: navigator)
        let taskVc = RSDTaskViewController(task: task)
        taskVc.delegate = self
        self.present(taskVc, animated: true, completion: nil)
    }
    
    public func didChangeDay(for cell: SBATrackedWeeklyScheduleCell, selected: Int) {
        _endTimeEditingIfNeeded()
    }
    
    public func didChangeTiming(for cell: SBATrackedWeeklyScheduleCell, selected: Int) {
        _endTimeEditingIfNeeded()
    }
    
    public func didTapTime(for cell: SBATrackedWeeklyScheduleCell) {
        _endTimeEditingIfNeeded()
        _activeIndexPath = cell.indexPath
        self.tableView.reloadRows(at: [cell.indexPath], with: .none)
    }
    
    private func _endTimeEditingIfNeeded(_ shouldCollapse: Bool = true) {
        guard let indexPath = _activeIndexPath,
            let cell = tableView.cellForRow(at: indexPath) as? SBATrackedWeeklyScheduleCell
            else {
                return
        }
        _activeIndexPath = nil
        if shouldCollapse {
            self.tableView.reloadRows(at: [cell.indexPath], with: .none)
        }
    }
    
    public func didChangeScheduleAtAnytimeSelection(for cell: SBATrackedWeeklyScheduleCell, selected: Bool) {
        if let source = tableData as? SBATrackedWeeklyScheduleDataSource {
            source.scheduleAtAnytimeChanged(selected: selected)
        }
        self.tableView.reloadData()
        _endTimeEditingIfNeeded()
    }
}

public protocol SBATrackedWeeklyScheduleCellDelegate : class, NSObjectProtocol {
    
    func didTapDay(for cell: SBATrackedWeeklyScheduleCell)
    
    func didTapTime(for cell: SBATrackedWeeklyScheduleCell)
    
    func didChangeScheduleAtAnytimeSelection(for cell: SBATrackedWeeklyScheduleCell, selected: Bool)
    
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
    @IBOutlet open var dayButtonContainer: UIView!
    @IBOutlet open var dayButton: UIButton!
    @IBOutlet open var atAnytimeContainer: UIView!
    @IBOutlet open var atAnytimeCheckbox: RSDCheckboxButton!
    
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
    
    var atAnytimeHidden: Bool = false {
        didSet {
            atAnytimeContainer.isHidden = atAnytimeHidden
        }
    }
    
    override open var tableItem: RSDTableItem! {
        didSet {
            guard let scheduleItem = weeklyScheduleTableItem else { return }
            atAnytimeCheckbox.isSelected = scheduleItem.scheduleAtAnytime
            if scheduleItem.scheduleAtAnytime {
                dayButtonContainer.isHidden = true
                inlineTimePicker.isHidden = true
            } else {
                dayButtonContainer.isHidden = false
                inlineTimePicker.isHidden = false
                let timePickerDate = scheduleItem.time ?? Calendar.current.date(bySetting: .hour, value: 7, of: Date()) ?? Date()
                timeButton?.setTitle(DateFormatter.localizedString(from: timePickerDate, dateStyle: .none, timeStyle: .short), for: .normal)
                timePicker.date = timePickerDate
                self.weeklyScheduleTableItem?.time = timePickerDate
                if scheduleItem.weekdays?.count ?? 0 == RSDWeekday.all.count {                    dayButton.setTitle(Localization.localizedString("MEDICATION_SCHEDULE_EVERYDAY"), for: .normal)
                } else {
                    if let weekdays = scheduleItem.weekdays {
                        dayButton.setTitle(SBATrackedWeeklyScheduleCell.weekdayTitle(for: weekdays), for: .normal)
                    }
                }
            }
        }
    }
    
    public static func weekdayTitle(for weekdays: [RSDWeekday]) -> String {
        let daysPerLine = 3
        var count = 0
        var dayButtonTitle = ""
        for weekday in weekdays {
            dayButtonTitle += weekday.text ?? ""
            count = count + 1
            if count % daysPerLine == 0 && count != weekdays.count {
                dayButtonTitle += ",\n"
            } else if count < weekdays.count {
                if count == weekdays.count - 1 {
                    dayButtonTitle += ", and "
                } else {
                    dayButtonTitle += ", "
                }
            }
        }
        return dayButtonTitle
    }
    
    var weeklyScheduleTableItem: SBATrackedWeeklyScheduleTableItem? {
        return tableItem as? SBATrackedWeeklyScheduleTableItem
    }
    
    @IBAction func timeTapped(_ sender: Any) {
        self.delegate?.didTapTime(for: self)
    }
    
    @IBAction func timeChanged(_ sender: Any) {
        self.weeklyScheduleTableItem?.time = timePicker.date
    }
    
    @IBAction func dayTapped(_ sender: Any) {
        self.delegate?.didTapDay(for: self)
    }
    
    @IBAction func atAnytimeTapped(_ sender: RSDCheckboxButton) {
        sender.isSelected = !sender.isSelected
        if let scheduleItem = weeklyScheduleTableItem {
            scheduleItem.scheduleAtAnytime = !scheduleItem.scheduleAtAnytime
        }
        self.delegate?.didChangeScheduleAtAnytimeSelection(for: self, selected: sender.isSelected)
    }
}

// TODO: mdephillips 6/26/18 why do i have to make this class? only seeing protocol impl
open class SBAInstructionImage: RSDImageThemeElement {
    
    public var imageIdentifier: String
    
    public var placementType: RSDImagePlacementType? {
        return .iconBefore
    }
    
    public var size: CGSize
    
    public var bundle: Bundle? {
        return Bundle(for: SBAInstructionImage.self)
    }
    
    fileprivate static func defaultSize() -> CGSize {
        return CGSize(width: 200.0, height: 200.0)
    }
    
    public init(identifier: String) {
        imageIdentifier = identifier
        size = SBAInstructionImage.defaultSize()
    }
}
