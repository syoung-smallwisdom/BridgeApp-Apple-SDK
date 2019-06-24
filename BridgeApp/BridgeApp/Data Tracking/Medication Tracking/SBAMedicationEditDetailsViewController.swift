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
    
    var items: [DosageItem] = []
    
    var editingItem: DosageItem? {
        return items.first(where: { $0.isEditing })
    }

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
        
        footerView.nextButton?.setTitle(Localization.localizedString("BUTTON_SAVE"), for: .normal)
        updateColorsAndFonts()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        focusEmptyTextField()
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
        titleLabel.text = self.medication.title
        items = medication.dosageItems?.map { DosageItem(dosage: $0, isEditing: false) } ?? [DosageItem()]
        tableView.reloadData()
        updateButtonStates()
    }
    
    func updateButtonStates() {
        let hasRequiredValues = editingItem?.dosage.hasRequiredValues ?? false
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
            case .editTimes:
                vc.setSelected(identifier: cell.dosageItem.uuid.uuidString, times: cell.dosageItem.dosage.timestamps)
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
        beginEdit(DosageItem())
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
        guard !dosageItem.isEditing else { return }
        
        tableView.beginUpdates()
        
        var removePaths: [IndexPath] = []
        var addPaths: [IndexPath] = []
        
        var section = items.firstIndex(of: dosageItem)
        let insertSection = 0
        
        if let editingItem = self.editingItem,
            let editSection = items.firstIndex(of: editingItem) {
            removePaths.append(IndexPath(row: 0, section: editSection))
            let newEditSection = ((section != nil) || (insertSection > editSection)) ? editSection : editSection + 1
            addPaths.append(IndexPath(row: 0, section: newEditSection))
            if !editingItem.isAnytime {
                removePaths.append(contentsOf: editingItem.daysAndTimesIndexPaths(for: newEditSection))
            }
            editingItem.isEditing = false
        }
        
        if section != nil {
            removePaths.append(IndexPath(row: 0, section: section!))
        }
        else {
            section = insertSection
            items.insert(dosageItem, at: insertSection)
        }
        addPaths.append(IndexPath(row: 0, section: section!))
        if !dosageItem.isAnytime {
            addPaths.append(contentsOf: dosageItem.daysAndTimesIndexPaths(for: section!))
        }
        dosageItem.isEditing = true

        tableView.deleteRows(at: removePaths, with: .automatic)
        tableView.insertRows(at: addPaths, with: .automatic)
        
        tableView.endUpdates()
    }
    
    func remove(_ dosageItem: DosageItem) {
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
        guard !dosageItem.isAnytime,
            let section = items.firstIndex(of: dosageItem)
            else {
                dosageItem.dosage.isAnytime = true
                return  // Do nothing if the anytime is already selected
        }
        tableView.beginUpdates()
        dosageItem.isAnytime = true
        tableView.deleteRows(at: dosageItem.daysAndTimesIndexPaths(for: section), with: .automatic)
        tableView.endUpdates()
    }
    
    func useScheduleTapped(_ dosageItem: DosageItem) {
        guard dosageItem.isAnytime,
            let section = items.firstIndex(of: dosageItem)
            else {
                return  // Do nothing if "uses schedule" is already selected
        }
        tableView.beginUpdates()
        dosageItem.isAnytime = false
        tableView.insertRows(at: dosageItem.daysAndTimesIndexPaths(for: section), with: .automatic)
        tableView.endUpdates()
    }
}

extension SBAMedicationEditDetailsViewController : SBADayTimePickerViewControllerDelegate {
    
    func saveSelection(_ picker: SBADayTimePickerViewController) {
        guard let dosageItem = self.items.first(where: { $0.uuid.uuidString == picker.identifier })
            else {
                fatalError("Could not find dose to edit")
        }
        
        switch picker.pickerType! {
        case .daysOfWeek:
            dosageItem.dosage.daysOfWeek = picker.selectedWeekdays()
            
        case .timeOfDay:
            dosageItem.dosage.timestamps = picker.selectedTimes(withPrevious: dosageItem.dosage.timestamps)
            
        default:
            assertionFailure("This editor does not handle changing the logged time.")
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func cancel(_ picker: SBADayTimePickerViewController) {
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let uuidString = (textField as? BoxedTextField)?.identifier,
            let dosageItem = self.items.first(where: { $0.uuid.uuidString == uuidString })
            else {
                return
        }
        dosageItem.dosage.dosage = textField.text
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
    
    init(dosage: SBADosage = SBADosage(), isEditing: Bool? = nil) {
        self.dosage = dosage
        self.isEditing = isEditing ?? !dosage.hasRequiredValues
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
            timestamps.append(SBATimestamp(timeOfDay: "08:00", loggedDate: nil)!)
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
            useScheduleButton.isSelected = !(dosageItem.dosage.isAnytime ?? false)
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
            titleLabel.text = dosageItem.dosage.dosage
            // Not anytime AND has valid values for the days and times.
            if !(dosageItem.dosage.isAnytime ?? true),
                let days = dosageItem.dosage.daysText(),
                let times = dosageItem.dosage.timesText() {
                widthConstraint.isActive = false
                detailLabel.text = Localization.localizedStringWithFormatKey("MEDICATION_SCHEDULE_SUMMARY", times, days)
            }
            else {
                detailLabel.text = Localization.localizedString("MEDICATION_TAKE_ANYTIME")
                widthConstraint.isActive = true
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
