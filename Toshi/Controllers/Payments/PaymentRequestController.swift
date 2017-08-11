// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit

protocol PaymentRequestControllerDelegate: class {
    func paymentRequestControllerDidFinish(valueInWei: NSDecimalNumber?)
}

class PaymentRequestController: PaymentController {
    
    weak var delegate: PaymentRequestControllerDelegate?

    private lazy var cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelItemTapped(_:)))
    private lazy var continueItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(continueItemTapped(_:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localized("payment_request")
        
        navigationItem.leftBarButtonItem = cancelItem
        navigationItem.rightBarButtonItem = continueItem
    }
    
    func cancelItemTapped(_ item: UIBarButtonItem) {
        delegate?.paymentRequestControllerDidFinish(valueInWei: nil)
    }
    
    func continueItemTapped(_ item: UIBarButtonItem) {
        delegate?.paymentRequestControllerDidFinish(valueInWei: valueInWei)
    }
}
