//
//  SBAMedicationDetailsViewController.swift
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

class SBAMedicationDetailsStepViewController: RSDTableStepViewController {
    
}

class SBAMedicationDosageTableItem : RSDTableItem {
    var dosage: SBADosage
    init(dosage: SBADosage, rowIndex: Int) {
        self.dosage = dosage
        super.init(identifier: UUID().uuidString, rowIndex: rowIndex, reuseIdentifier: SBAMedicationDosageTableCell.reuseId)
    }
}

class SBAMedicationDosageTableCell : RSDTableViewCell {
    
    static let reuseId = "dosage"
    
    override var tableItem: RSDTableItem! {
        didSet {
            //
        }
    }
}

struct SBAMedicationDetailsStep : RSDTableStep {

    var medication: SBAMedicationAnswer
    
    init(medication: SBAMedicationAnswer) {
        self.medication = medication
    }
    
    var identifier: String {
        return medication.identifier
    }
    
    var title: String? {
        return medication.title
    }
    
    let text: String? = nil
    let detail: String? = nil
    let footnote: String? = nil
    let stepType: RSDStepType = .medicationDetails
    
    func instantiateStepResult() -> RSDResult {
        return SBAMedicationDetailsResult(medication: self.medication)
    }
    
    func validate() throws {
        // do nothing
    }
    
    func action(for actionType: RSDUIActionType, on step: RSDStep) -> RSDUIAction? {
        switch actionType {
        case .navigation(.goForward):
            return RSDUIActionObject(buttonTitle: Localization.localizedString("BUTTON_SAVE"))
        case .navigation(.learnMore):
            return RSDUIActionObject(buttonTitle: Localization.localizedString("MEDICATION_ADD_DOSE_BUTTON"))
        default:
            return nil
        }
    }
    
    func shouldHideAction(for actionType: RSDUIActionType, on step: RSDStep) -> Bool? {
        switch actionType {
        case .navigation(.goBackward), .navigation(.skip):
            return true
        default:
            return nil
        }
    }
    
    func instantiateDataSource(with parent: RSDPathComponent?, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBAMedicationDetailsDataSource(step: self, parent: parent)
    }
}

struct SBAMedicationDetailsResult : RSDResult {
    
    var medication: SBAMedicationAnswer
    
    init(medication: SBAMedicationAnswer) {
        self.medication = medication
    }
    
    var identifier: String {
        return medication.identifier
    }
    
    let type: RSDResultType = .medicationDetails
    var startDate: Date = Date()
    var endDate: Date = Date()
}

class SBAMedicationDetailsDataSource : RSDStepViewModel, RSDTableDataSource {
    
    weak var delegate: RSDTableDataSourceDelegate?
    
    var sections: [RSDTableSection]
    
    var medication: SBAMedicationAnswer
    
    init(step: SBAMedicationDetailsStep, parent: RSDPathComponent?) {
        self.medication = step.medication
        let dosageItems = (medication.dosageItems?.count ?? 0) > 0 ? medication.dosageItems! : [SBADosage()]
        let tableItems = dosageItems.enumerated().map {
            return SBAMedicationDosageTableItem(dosage: $0.element, rowIndex: $0.offset)
        }
        let section = RSDTableSection(identifier: "dosages", sectionIndex: 0, tableItems: tableItems)
        self.sections = [section]
        super.init(step: step, parent: parent)
    }
    
    func itemGroup(at indexPath: IndexPath) -> RSDTableItemGroup? {
        return nil // not used
    }
    
    func allAnswersValid() -> Bool {
        return medication.dosageItems?.first(where: { $0.hasRequiredValues }) != nil
    }
    
    func saveAnswer(_ answer: Any, at indexPath: IndexPath) throws {
        guard let dosageText = answer as? String,
            let tableItem = self.tableItem(at: indexPath) as? SBAMedicationDosageTableItem
            else {
                return
        }
        tableItem.dosage.dosage = dosageText
    }
    
    func selectAnswer(item: RSDTableItem, at indexPath: IndexPath) throws -> (isSelected: Bool, reloadSection: Bool) {
        // Do nothing - not used
        return (false, false)
    }
}
