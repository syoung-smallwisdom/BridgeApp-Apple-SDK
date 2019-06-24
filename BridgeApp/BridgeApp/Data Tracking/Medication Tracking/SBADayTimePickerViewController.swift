//
//  SBADayTimePickerViewController.swift
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

protocol SBADayTimePickerViewControllerDelegate : class {
    func saveSelection(_ picker: SBADayTimePickerViewController)
    func cancel(_ picker: SBADayTimePickerViewController)
}

class SBADayTimePickerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: SBADayTimePickerViewControllerDelegate?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var headerShadow: RSDShadowGradient!
    @IBOutlet weak var footerView: RSDGenericNavigationFooterView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerMargin: UIView!
    
    public private(set) var identifier: String!
    public private(set) var pickerType : PickerType!
    public private(set) var sections: [PickerSection]!
    
    public var singleChoice: Bool {
        return pickerType == .loggedTime
    }
    
    public var selectedChoices: [PickerChoice] {
        guard let sections = self.sections else { return [] }
        return sections.compactMap({ section in
            section.items.compactMap {
                $0.isSelected ? $0.choice : nil
            }
        }).flatMap { $0 }
    }
    
    
    public func selectedWeekdays() -> Set<RSDWeekday>? {
        guard pickerType == .daysOfWeek else {
            assertionFailure("Attemping to get selected weekdays for a picker that is not set up for that purpose.")
            return nil
        }
        let choices = selectedChoices
        if choices.count == 0 {
            return nil
        }
        else if choices.count == 1, let _ = choices.first as? Everyday {
            return RSDWeekday.all
        }
        else {
            return Set(choices.compactMap { $0 as? RSDWeekday })
        }
    }
    
    public func selectedTimes(withPrevious times: [SBATimestamp]?) -> [SBATimestamp]? {
        guard pickerType == .timeOfDay else {
            assertionFailure("Attemping to get selected times for a picker that is not set up for that purpose.")
            return nil
        }
        guard let choices = selectedChoices as? [SBATime] else { return nil }
        let filteredInput = times?.reduce(into: [SBATime : SBATimestamp]()) { (hashtable, value) in
            guard let time = self.selectedTime(from: value.loggedDate?.timeOnly()) else { return }
            hashtable[time] = value
            } ?? [:]
        let timestamps: [SBATimestamp] = choices.compactMap {
            if let existing = filteredInput[$0] {
                var timestamp: SBATimestamp = existing
                timestamp.timeOfDay = $0.timeOfDay
                return timestamp
            }
            else {
                return SBATimestamp(timeOfDay: $0.timeOfDay)
            }
        }
        return timestamps.count > 0 ? timestamps : nil
    }
    
    public func setSelected(identifier: String, daysOfWeek: Set<RSDWeekday>?) {
        guard self.identifier == nil else {
            assertionFailure("Trying to set selection for a picker view that is already set up")
            return
        }
        self.identifier = identifier
        self.pickerType = .daysOfWeek
        let isEveryday = (daysOfWeek == RSDWeekday.all)
        let selectedDays = daysOfWeek ?? []
        var items: [PickerItem] = RSDWeekday.all.sorted().map {
            PickerItem(choice: $0, isSelected: !isEveryday && selectedDays.contains($0))
        }
        items.append(PickerItem(choice: Everyday(), isSelected: isEveryday))
        self.sections = [PickerSection(title: nil, items: items)]
    }
    
    public func setSelected(identifier: String, times: [SBATimestamp]?) {
        guard self.identifier == nil else {
            assertionFailure("Trying to set selection for a picker view that is already set up")
            return
        }
        self.identifier = identifier
        self.pickerType = .timeOfDay
        let selectedTimes: [SBATime] = times?.compactMap { self.selectedTime(from: $0.timeComponents) } ?? []
        self.sections = buildSections(selectedTimes)
    }
    
    public func setSelected(identifier: String, loggedTime: Date?) {
        guard self.identifier == nil else {
            assertionFailure("Trying to set selection for a picker view that is already set up")
            return
        }
        self.identifier = identifier
        self.pickerType = .loggedTime
        var selectedTimes = [SBATime]()
        if let time = self.selectedTime(from: loggedTime?.timeOnly()) {
            selectedTimes.append(time)
        }
        self.sections = buildSections(selectedTimes)
    }
    
    func selectedTime(from timeComponents: DateComponents?) -> SBATime? {
        guard let tc = timeComponents, let hour = tc.hour, let minute = tc.minute
            else {
                return nil
        }
        let interval = 30 // minutes
        return SBATime(hour: hour, minute: minute < interval ? 0 : interval)
    }
    
    func buildSections(_ selectedTimes: [SBATime]) -> [PickerSection] {
        return SBATimeRange.allCases.map { (timeRange) -> PickerSection in
            let items = timeRange.times(at: 30).flatMap({ $0 }).map {
                PickerItem(choice: $0, isSelected: selectedTimes.contains($0))
            }
            let localizationKey = "\(timeRange.stringValue.uppercased())_PICKER_SECTION_TITLE"
            let title = Localization.localizedString(localizationKey)
            return PickerSection(title: title, items: items)
        }
    }
    
    public enum PickerType {
        case daysOfWeek, timeOfDay, loggedTime
    }
    
    // MARK: UI View management

    override func viewDidLoad() {
        super.viewDidLoad()
        self.headerShadow.isHidden = true
        updateColorsAndFonts()
        self.footerView!.nextButton!.addTarget(self, action: #selector(saveTapped(_:)), for: .touchUpInside)
    }
    
    var designSystem: RSDDesignSystem? {
        didSet {
            self.tableView?.reloadData()
            self.updateColorsAndFonts()
        }
    }
    
    func updateColorsAndFonts() {
        guard let designSystem = self.designSystem, isViewLoaded else { return }
        let background = designSystem.colorRules.backgroundLight
        self.view.backgroundColor = background.color
        self.tableView.backgroundColor = background.color
        self.headerView.backgroundColor = background.color
        self.footerMargin.backgroundColor = background.color
        self.footerView.setDesignSystem(designSystem, with: background)
        self.titleLabel.font = designSystem.fontRules.font(for: .heading2, compatibleWith: self.traitCollection)
        self.titleLabel.textColor = designSystem.colorRules.textColor(on: background, for: .heading2)
        self.detailLabel.font = designSystem.fontRules.font(for: .small)
        self.detailLabel.textColor = designSystem.colorRules.textColor(on: background, for: .small)
        self.headerView.tintColor = designSystem.colorRules.tintedButtonColor(on: background)
        self.footerView.nextButton?.setTitle(Localization.localizedString("BUTTON_SAVE"), for: .normal)
    }
    
    // MARK: Table data source and selection

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(ceil(Double(sections[section].items.count) / 2.0))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "twoButton", for: indexPath) as! TwoChoicePickerCell
        let leftIndex = indexPath.row * 2
        let rightIndex = leftIndex + 1
        let section = sections[indexPath.section]
        var items = [section.items[leftIndex]]
        if rightIndex < section.items.count {
            items.append(section.items[rightIndex])
        }
        cell.choices = items
        cell.controller = self
        if let designSystem = self.designSystem {
            cell.setDesignSystem(designSystem, with: designSystem.colorRules.backgroundLight)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    // MARK: Actions
    
    func toggleSelect(_ selectedItem: PickerItem) {
        
        let isSelected = !selectedItem.isSelected
        
        if isSelected && (selectedItem.choice.isExclusive || singleChoice){
            sections.enumerated().forEach { (sectionIndex, section) in
                section.items.enumerated().forEach { (itemIndex, item) in
                    guard item != selectedItem else { return }
                    item.isSelected = false
                    let rowIndex = itemIndex / 2
                    let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    guard let cell = tableView.cellForRow(at: indexPath) as? TwoChoicePickerCell else { return }
                    let buttonIndex = itemIndex % 2
                    cell.buttons[buttonIndex].isSelected = false
                }
            }
        }
        selectedItem.isSelected = isSelected
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        self.delegate?.saveSelection(self)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.delegate?.cancel(self)
    }
}

protocol PickerChoice {

    /// Localized text string to display for the choice.
    var text: String? { get }
    
    /// For a multiple choice option, is this choice mutually exclusive? For example, "none of the above".
    var isExclusive: Bool { get }
}

struct Everyday : PickerChoice {
    
    var text: String? {
        return Localization.localizedString("SCHEDULE_EVERY_DAY")
    }
    
    var isExclusive: Bool {
        return true
    }
}

extension RSDWeekday : PickerChoice {
}

extension SBATime : PickerChoice {
    
    var text: String? {
        return self.localizedTime()
    }
    
    var isExclusive: Bool {
        return false
    }
}

class PickerSection : UniqueTableItem {
    let title : String?
    let items : [PickerItem]
    
    init(title : String?, items : [PickerItem]) {
        self.title = title
        self.items = items
    }
}

class PickerItem : UniqueTableItem {
    let choice : PickerChoice
    var isSelected : Bool
    
    init(choice : PickerChoice, isSelected : Bool) {
        self.choice = choice
        self.isSelected = isSelected
    }
}

class TwoChoicePickerCell : RSDDesignableTableViewCell {
    
    weak var controller: SBADayTimePickerViewController?
    
    @IBOutlet var buttons: [UIButton]!
    
    var choices: [PickerItem]! {
        didSet {
            choices.enumerated().forEach {
                let button = buttons[$0.offset]
                button.setTitle($0.element.choice.text, for: .normal)
                button.isSelected = $0.element.isSelected
                button.isHidden = false
                button.tag = $0.offset
            }
            for ii in choices.count..<buttons.count {
                buttons[ii].isHidden = true
            }
        }
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        let idx = sender.tag
        guard idx < choices.count, let controller = self.controller else {
            assertionFailure("Attempting to tap an item that is not mapped.")
            return
        }
        sender.isSelected = !sender.isSelected
        controller.toggleSelect(choices[idx])
    }
}
