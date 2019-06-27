//
//  SBAMedicationEditDetailsViewController.swift
//  BridgeApp (iOS)
//
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
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

protocol SBAMedicationEditDetailsViewControllerDelegate : class {
    func save(_ medication: SBAMedicationAnswer, from sender: SBAMedicationEditDetailsViewController)
    func delete(_ medication: SBAMedicationAnswer, from sender: SBAMedicationEditDetailsViewController)
}

class SBAMedicationEditDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: SBAMedicationEditDetailsViewControllerDelegate?
    
    public var medication: SBAMedicationAnswer! {
        didSet {
            guard self.isViewLoaded else { return }
            reloadData()
        }
    }
    
    var hasChanges = false {
        didSet {
            updateButtonStates()
        }
    }
    
    var items: [DosageItem] = []
    
    var editingItem: DosageItem? {
        return items.first(where: { $0.isEditing })
    }
    
    var activeTextField: UITextField?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: RSDUnderlinedButton!
    @IBOutlet weak var footerView: RSDGenericNavigationFooterView!
    @IBOutlet weak var headerShadow: RSDShadowGradient!
    @IBOutlet weak var footerMarginView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let nextButton = footerView.nextButton {
            nextButton.setTitle(Localization.localizedString("BUTTON_SAVE"), for: .normal)
            nextButton.addTarget(self, action: #selector(saveTapped(_:)), for: .touchUpInside)
        }
        else {
            assertionFailure("Expecting this view controller to be set up with a next button in the footer.")
        }
        updateColorsAndFonts()
    }
    
    var isFirstAppearance: Bool = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isFirstAppearance {
            reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstAppearance {
            focusEmptyTextField()
        }
        isFirstAppearance = false
    }
    
    func focusEmptyTextField() {
        guard let section = items.firstIndex(where: { $0.isEditing && ($0.dosage.dosage?.isEmpty ?? true) }),
            let cell = tableView.cellForRow(at: IndexPath(row: 0, section: section)) as? EditDosageCell
            else {
                return
        }
        cell.doseTextField.becomeFirstResponder()
    }
    
    var designSystem: RSDDesignSystem? {
        didSet {
            updateColorsAndFonts()
            tableView?.reloadData()
        }
    }
    
    var tableBackground: RSDColorTile = RSDStudyConfiguration.shared.colorPalette.primary.normal
    
    func updateColorsAndFonts() {
        guard let designSystem = self.designSystem, isViewLoaded else { return }
        
        let background = designSystem.colorRules.backgroundPrimary
        self.tableBackground = background
        self.view.backgroundColor = background.color
        
        self.titleLabel.font = designSystem.fontRules.font(for: .heading2, compatibleWith: self.traitCollection)
        self.titleLabel.textColor = designSystem.colorRules.textColor(on: background, for: .heading2)
        self.headerView.tintColor = designSystem.colorRules.tintedButtonColor(on: background)
        self.headerView.backgroundColor = background.color
        self.tableView.backgroundColor = background.color
        
        self.footerView.setDesignSystem(designSystem, with: designSystem.colorRules.backgroundLight)
        self.addButton.setDesignSystem(designSystem, with: background)
    }
    
    func reloadData() {
        titleLabel.text = self.medication.title ?? self.medication.identifier
        items = medication.dosageItems?.map { DosageItem(dosage: $0, isEditing: false) } ?? [DosageItem(dosage: SBADosage(), isEditing: true)]
        tableView.reloadData()
        updateButtonStates()
    }
    
    func updateButtonStates() {
        let hasRequiredValues = items.reduce(false, { $0 || $1.dosage.hasRequiredValues })
        addButton.isEnabled = hasRequiredValues
        footerView.nextButton?.isEnabled = hasRequiredValues
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard items.count > section else { return 0 }
        return items[section].numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section]
        let reuseId = item.reuseIdentifier(for: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId.stringValue, for: indexPath) as! DosageCell
        cell.dosageItem = item
        cell.controller = self
        if let editCell = cell as? EditDosageCell {
            editCell.removeButton.isHidden = (items.count == 1)
            editCell.doseTextField.delegate = self
        }
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? DosageCell,
            let vc = segue.destination as? SBADayTimePickerViewController,
            let reuseId = cell.reuseIdentifier,
            let editType = DosageReuseIdentifier(rawValue: reuseId) {
            // Set up the day/time picker
            vc.delegate = self
            switch editType {
            case .editDays:
                vc.setSelected(identifier: cell.dosageItem.uuid.uuidString, daysOfWeek: cell.dosageItem.dosage.daysOfWeek)
                vc.titleText = Localization.localizedStringWithFormatKey("MEDICATION_DAY_PICKER_TEXT", self.medication.title ?? self.medication.identifier)
            case .editTimes:
                vc.setSelected(identifier: cell.dosageItem.uuid.uuidString, times: cell.dosageItem.dosage.timestamps)
                vc.titleText = Localization.localizedStringWithFormatKey("MEDICATION_TIME_PICKER_TEXT", self.medication.title ?? self.medication.identifier)
            default:
                assertionFailure("\(reuseId) not supported.")
            }
            vc.designSystem = self.designSystem
        }
        else if let vc = segue.destination as? SBAWarningViewController {
            vc.delegate = self
            vc.designSystem = self.designSystem
            vc.item = self.medication
            vc.buttonTitle = Localization.localizedString("MEDICATION_REMOVE_BUTTON_TEXT")
            vc.text = Localization.localizedStringWithFormatKey("MEDICATION_REMOVE_TITLE_%@", medication.title!)
            vc.detailText = Localization.localizedString("MEDICATION_REMOVE_TEXT")
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        activeTextField?.resignFirstResponder()
        guard self.hasChanges else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        var actions: [UIAlertAction] = []
        
        // Always add a choice to discard the results.
        let discardResults = UIAlertAction(title: Localization.localizedString("BUTTON_OPTION_DISCARD"), style: .destructive) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        actions.append(discardResults)
        
        // Always add a choice to keep going.
        let keepGoing = UIAlertAction(title: Localization.localizedString("BUTTON_OPTION_CONTINUE"), style: .cancel) { (_) in
            // Do nothing, just hide the alert
        }
        actions.append(keepGoing)
        
        self.presentAlertWithActions(title: nil, message: Localization.localizedString("MESSAGE_CONFIRM_CANCEL_TASK"), preferredStyle: .actionSheet, actions: actions)
    }
    
    @IBAction func addTapped(_ sender: Any) {
        activeTextField?.resignFirstResponder()
        beginEdit(DosageItem(dosage: SBADosage(), isEditing: false))
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        self.medication.dosageItems = items.compactMap {
            var dose = $0.dosage
            dose.finalizeEditing()
            return dose.hasRequiredValues ? dose : nil
        }
        self.delegate?.save(self.medication, from: self)
    }
    
    func beginEdit(_ dosageItem: DosageItem) {
        activeTextField?.resignFirstResponder()
        guard !dosageItem.isEditing else { return }
        
        // If there is a table item that is currently being edited, collapse it.
        if let editingItem = self.editingItem,
            let editSection = items.firstIndex(of: editingItem) {
            tableView.beginUpdates()
            editingItem.isEditing = false
            let reloadPath = IndexPath(row: 0, section: editSection)
            var removePaths = [reloadPath]
            removePaths.append(contentsOf: editingItem.isAnytime ? [] : editingItem.daysAndTimesIndexPaths(for: editSection))
            tableView.deleteRows(at: removePaths, with: .automatic)
            tableView.insertRows(at: [reloadPath], with: .automatic)
            tableView.endUpdates()
        }
        
        // Next, either insert or begin editing the new section.
        tableView.beginUpdates()
        
        dosageItem.isEditing = true
        if let section = items.firstIndex(of: dosageItem) {
            let reloadPath = IndexPath(row: 0, section: section)
            var addPaths = [reloadPath]
            addPaths.append(contentsOf: dosageItem.isAnytime ? [] : dosageItem.daysAndTimesIndexPaths(for: section))
            tableView.deleteRows(at: [reloadPath], with: .automatic)
            tableView.insertRows(at: addPaths, with: .automatic)
        }
        else {
            let insertSection = 0
            items.insert(dosageItem, at: insertSection)
            tableView.insertSections([insertSection], with: .automatic)
        }
        
        tableView.endUpdates()
    }
    
    func remove(_ dosageItem: DosageItem) {
        activeTextField?.resignFirstResponder()
        guard let section = items.firstIndex(of: dosageItem) else {
            assertionFailure("Failed to find the dose to remove. \(dosageItem)")
            return
        }
        
        var actions: [UIAlertAction] = []
        
        let removeDosage = UIAlertAction(title: Localization.localizedString("MEDICATION_REMOVE_YES"), style: .destructive) { (_) in
            self.tableView.beginUpdates()
            self.items.remove(at: section)
            self.tableView.deleteSections([section], with: .automatic)
            self.tableView.endUpdates()
        }
        actions.append(removeDosage)
        
        let keepGoing = UIAlertAction(title: Localization.localizedString("MEDICATION_REMOVE_NO"), style: .cancel) { (_) in
            // Do nothing, just hide the alert
        }
        actions.append(keepGoing)
        
        self.presentAlertWithActions(title: nil, message: Localization.localizedString("MEDICATION_REMOVE_DOSAGE_CONFIRMATION_MESSAGE"), preferredStyle: .actionSheet, actions: actions)
    }
    
    func anytimeTapped(_ dosageItem: DosageItem) {
        setIsAnytime(true, on: dosageItem)
    }
    
    func useScheduleTapped(_ dosageItem: DosageItem) {
        setIsAnytime(false, on: dosageItem)
    }
    
    func setIsAnytime(_ isAnytime: Bool, on dosageItem: DosageItem) {
        activeTextField?.resignFirstResponder()
        
        if dosageItem.isAnytime != isAnytime,
            let section = items.firstIndex(of: dosageItem) {
        
            // Animate changing the rows to add/hide the schedule.
            tableView.beginUpdates()
            dosageItem.isAnytime = isAnytime
            if isAnytime {
                tableView.deleteRows(at: dosageItem.daysAndTimesIndexPaths(for: section), with: .automatic)
            }
            else {
                tableView.insertRows(at: dosageItem.daysAndTimesIndexPaths(for: section), with: .automatic)
            }
            tableView.endUpdates()
        }
        else {
            // If the dosage item isn't adding or deleting any rows, then just set the value directly.
            dosageItem.dosage.isAnytime = isAnytime
        }
        
        self.hasChanges = true
    }
}

extension SBAMedicationEditDetailsViewController : SBADayTimePickerViewControllerDelegate {
    
    func saveSelection(_ picker: SBADayTimePickerViewController) {
        guard let section = self.items.firstIndex(where: { $0.uuid.uuidString == picker.identifier })
            else {
                fatalError("Could not find dose to edit")
        }
        
        let dosageItem = self.items[section]
        switch picker.pickerType! {
        case .daysOfWeek:
            dosageItem.dosage.daysOfWeek = picker.selectedWeekdays()
            
        case .timeOfDay:
            dosageItem.dosage.timestamps = picker.selectedTimes(withPrevious: dosageItem.dosage.timestamps)
            
        default:
            assertionFailure("This editor does not handle changing the logged time.")
        }
        tableView.reloadSections([section], with: .none)
        
        self.hasChanges = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    func cancel(_ picker: SBADayTimePickerViewController) {
        guard let section = self.items.firstIndex(where: { $0.uuid.uuidString == picker.identifier })
            else {
                fatalError("Could not find dose to edit")
        }
        tableView.reloadSections([section], with: .none)
        picker.dismiss(animated: true, completion: nil)
    }
}

extension SBAMedicationEditDetailsViewController : SBAWarningViewControllerDelegate {
    
    func cancel(_ viewController: SBAWarningViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func removeItem(_ viewController: SBAWarningViewController) {
        if viewController.item is SBAMedicationAnswer {
            self.delegate?.delete(self.medication, from: self)
        }
    }
}

extension SBAMedicationEditDetailsViewController : UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeTextField = textField
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text,
            let textRange = Range(range, in: text),
            let uuidString = (textField as? BoxedTextField)?.identifier,
            let dosageItem = self.items.first(where: { $0.uuid.uuidString == uuidString })
            else {
                return true
        }
        self.hasChanges = true
        dosageItem.dosage.dosage = text.replacingCharacters(in: textRange, with: string)
        self.updateButtonStates()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
        guard let uuidString = (textField as? BoxedTextField)?.identifier,
            let dosageItem = self.items.first(where: { $0.uuid.uuidString == uuidString })
            else {
                return
        }
        self.hasChanges = true
        dosageItem.dosage.dosage = textField.text
        self.updateButtonStates()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(false)
        return false
    }
}

enum DosageReuseIdentifier : String {
    case summary, editDose, editDays, editTimes
}

class UniqueTableItem : Hashable {
    let uuid = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    static func == (lhs: UniqueTableItem, rhs: UniqueTableItem) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

class DosageItem : UniqueTableItem {

    var dosage: SBADosage
    
    var isEditing: Bool {
        didSet {
            if isEditing {
                updateDaysAndTimes()
            }
            else {
                dosage.finalizeEditing()
            }
        }
    }
    
    var isAnytime: Bool {
        get {
            return dosage.isAnytime ?? true
        }
        set {
            dosage.isAnytime = newValue
            updateDaysAndTimes()
        }
    }
    
    init(dosage: SBADosage, isEditing: Bool) {
        self.dosage = dosage
        self.isEditing = isEditing
    }

    func numberOfRows() -> Int {
        return !isEditing ? 1 : ((dosage.isAnytime ?? true) ? 1 : 3)
    }
    
    func reuseIdentifier(for row: Int) -> DosageReuseIdentifier {
        if !isEditing {
            return .summary
        }
        else {
            switch row {
            case 1:
                return .editTimes
            case 2:
                return .editDays
            default:
                return .editDose
            }
        }
    }
    
    func updateDaysAndTimes() {
        guard !isAnytime else { return }
        if dosage.daysOfWeek?.count ?? 0 == 0 {
            dosage.daysOfWeek = RSDWeekday.all
        }
        if dosage.selectedTimes.count == 0 {
            var timestamps = dosage.timestamps ?? []
            timestamps.append(SBATimestamp(timeOfDay: "08:00", loggedDate: nil))
            dosage.timestamps = timestamps
        }
    }
    
    func daysAndTimesIndexPaths(for section: Int) -> [IndexPath] {
        return [IndexPath(row: 1, section: section),
                IndexPath(row: 2, section: section)]
    }
}

class DosageCell : RSDDesignableTableViewCell {
    
    /// The callback delegate for the cell.
    weak var controller: SBAMedicationEditDetailsViewController?
    
    /// The dosage item associated with this cell.
    var dosageItem: DosageItem!
}

class EditDosageCell : DosageCell {
    @IBOutlet weak var removeButton: RSDUnderlinedButton!
    @IBOutlet weak var doseTextField: BoxedTextField!
    @IBOutlet weak var anytimeButton: RSDRadioButton!
    @IBOutlet weak var useScheduleButton: RSDRadioButton!
    
    override var dosageItem: DosageItem! {
        didSet {
            guard let dosageItem = self.dosageItem else { return }
            doseTextField.text = dosageItem.dosage.dosage
            doseTextField.identifier = dosageItem.uuid.uuidString
            anytimeButton.isSelected = dosageItem.dosage.isAnytime ?? false
            useScheduleButton.isSelected = !(dosageItem.dosage.isAnytime ?? true)
            anytimeButton.setTitle(Localization.localizedString("MEDICATION_TAKE_ANYTIME"), for: .normal)
            useScheduleButton.setTitle(Localization.localizedString("MEDICATION_TAKE_USING_SCHEDULE"), for: .normal)
        }
    }
    
    @IBAction func removeTapped(_ sender: Any) {
        self.controller?.remove(self.dosageItem)
    }
    
    @IBAction func anytimeTapped(_ sender: Any) {
        useScheduleButton.isSelected = false
        anytimeButton.isSelected = true
        self.controller?.anytimeTapped(self.dosageItem)
    }
    
    @IBAction func useScheduleTapped(_ sender: Any) {
        useScheduleButton.isSelected = true
        anytimeButton.isSelected = false
        self.controller?.useScheduleTapped(self.dosageItem)
    }
    
    override func setDesignSystem(_ designSystem: RSDDesignSystem, with background: RSDColorTile) {
        super.setDesignSystem(designSystem, with: background)
        anytimeButton.setDesignSystem(designSystem, with: background)
        useScheduleButton.setDesignSystem(designSystem, with: background)
    }
}

class EditDosageScheduleCell : DosageCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var arrowButton: UIButton!
    
    override var dosageItem: DosageItem! {
        didSet {
            guard let dosageItem = self.dosageItem,
                let reuseIdentifier = self.reuseIdentifier,
                let fieldId = DosageReuseIdentifier(rawValue: reuseIdentifier)
                else {
                    return
            }
            switch fieldId {
            case .editDays:
                titleLabel.text = dosageItem.dosage.daysText() ?? Localization.localizedString("SCHEDULING_SELECTION_NO_DAYS")
            case .editTimes:
                titleLabel.text = dosageItem.dosage.timesText() ?? Localization.localizedString("SCHEDULING_SELECTION_NO_TIMES")
            default:
                break
            }
        }
    }
    
    override func setDesignSystem(_ designSystem: RSDDesignSystem, with background: RSDColorTile) {
        super.setDesignSystem(designSystem, with: background)
        self.arrowButton.tintColor = designSystem.colorRules.palette.primary.normal.color
    }
}

class DosageSummaryCell : DosageCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var editButton: RSDUnderlinedButton!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorLine: UIView!
    
    override var dosageItem: DosageItem! {
        didSet {
            guard let dosageItem = self.dosageItem else { return }
            titleLabel?.text = dosageItem.dosage.dosage
            // Not anytime AND has valid values for the days and times.
            if !(dosageItem.dosage.isAnytime ?? true),
                let days = dosageItem.dosage.daysText(),
                let times = dosageItem.dosage.timesText() {
                widthConstraint?.isActive = false
                detailLabel?.text = Localization.localizedStringWithFormatKey("MEDICATION_SCHEDULE_SUMMARY", times, days)
            }
            else {
                detailLabel?.text = Localization.localizedString("MEDICATION_TAKE_ANYTIME")
                widthConstraint?.isActive = true
            }
        }
    }
    
    @IBAction func editTapped(_ sender: Any) {
        self.controller?.beginEdit(self.dosageItem)
    }
    
    override func setDesignSystem(_ designSystem: RSDDesignSystem, with background: RSDColorTile) {
        super.setDesignSystem(designSystem, with: background)
        self.separatorLine.backgroundColor = background.color
    }
}
