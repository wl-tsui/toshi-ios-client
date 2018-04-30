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

struct TransactionSkeleton: Codable {

    let gas: String?
    let gasPrice: String?
    let transaction: String?
    let value: String?

    enum CodingKeys: String, CodingKey {
        case
        gas,
        gasPrice = "gas_price",
        transaction = "tx",
        value
    }

    static var empty: TransactionSkeleton {
        return TransactionSkeleton(gas: nil,
                                   gasPrice: nil,
                                   transaction: nil,
                                   value: nil)
    }
}
