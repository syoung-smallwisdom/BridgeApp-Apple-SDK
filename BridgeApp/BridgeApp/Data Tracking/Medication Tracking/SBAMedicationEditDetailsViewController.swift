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

class SBAMedicationEditDetailsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class DosageItem : Hashable {

    let uuid = UUID()
    var dosage: SBADosage
    var isEditing: Bool
    
    init(dosage: SBADosage = SBADosage(), isEditing: Bool? = nil) {
        self.dosage = dosage
        self.isEditing = isEditing ?? !dosage.hasRequiredValues
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    static func == (lhs: DosageItem, rhs: DosageItem) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    func numberOfRows() -> Int {
        return !isEditing ? 1 : ((dosage.isAnytime ?? true) ? 1 : 3)
    }
    
    func reuseIdentifier(for row: Int) -> String {
        if !isEditing {
            return "Summary"
        }
        else {
            switch row {
            case 1:
                return "EditDays"
            case 2:
                return "EditTimes"
            default:
                return "EditDose"
            }
        }
    }
}

class DosageCell : UITableViewCell {
    
    /// The callback delegate for the cell.
    weak var controller: SBAMedicationEditDetailsViewController?
    
    /// The dosage item associated with this cell.
    var dosageItem: DosageItem!
}
