// Copyright (c) 2018 Token Browser, Inc
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

import Foundation

final class SofaTokenPayment: SofaWrapper {

    var status: SofaPayment.Status {
        guard let status = self.json[SofaPaymentKeys.status] as? String else { return .unconfirmed }
        return SofaPayment.Status(rawValue: status) ?? .unconfirmed
    }

    var recipientAddress: String? {
        return json[SofaPaymentKeys.toAddress] as? String
    }

    var senderAddress: String? {
        return json[SofaPaymentKeys.fromAddress] as? String
    }

    var contractAddress: String? {
        return json[SofaPaymentKeys.contractAddress] as? String
    }

    override var type: SofaType {
        return .tokenPayment
    }

    var value: NSDecimalNumber {
        guard let hexValue = json[SofaPaymentKeys.value] as? String else { return NSDecimalNumber.zero }

        return NSDecimalNumber(hexadecimalString: hexValue)
    }
}
