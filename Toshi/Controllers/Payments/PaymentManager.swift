import Foundation
import UIKit

class PaymentManager {

    var transaction: String?

    let value: NSDecimalNumber
    let paymentAddress: String

    lazy var parameters: [String: Any] = {
        return [
            "from": Cereal.shared.paymentAddress,
            "to": paymentAddress,
            "value": value.toHexString
        ]
    }()

    init(withValue value: NSDecimalNumber, andPaymentAddress address: String) {
       self.value = value
       self.paymentAddress = address
    }

    func transactionSkeleton(completion: @escaping ((_ fiatString: String, _ estimatedFeesString: String, _ totalFiatString: String, _ totalEthereumString: String) -> Void)) {
        EthereumAPIClient.shared.transactionSkeleton(for: parameters) { [weak self] skeleton, error in
            guard error == nil else {
                // Handle error
                return
            }

            if let gasPrice = skeleton.gasPrice, let gas = skeleton.gas, let transaction = skeleton.transaction {
                guard let weakSelf = self else { return }
                weakSelf.transaction = transaction

                let gasPriceValue = NSDecimalNumber(hexadecimalString: gasPrice)
                let gasValue = NSDecimalNumber(hexadecimalString: gas)

                let fee = gasPriceValue.decimalValue * gasValue.decimalValue
                let decimalNumberFee = NSDecimalNumber(decimal: fee)

                let exchangeRate = ExchangeRateClient.exchangeRate

                let fiatString = EthereumConverter.fiatValueStringWithCode(forWei: weakSelf.value, exchangeRate: exchangeRate)
                let estimatedFeesString = EthereumConverter.fiatValueStringWithCode(forWei: decimalNumberFee, exchangeRate: exchangeRate)

                let totalWei = weakSelf.value.adding(decimalNumberFee)
                let totalFiatString = EthereumConverter.fiatValueStringWithCode(forWei: totalWei, exchangeRate: exchangeRate)
                let totalEthereumString = EthereumConverter.ethereumValueString(forWei: totalWei)

                completion(fiatString, estimatedFeesString, totalFiatString, totalEthereumString)
            } else {
                //WARNING: should deal with error
            }
        }
    }


    func sendPayment(completion: @escaping ((_ error: ToshiError?) -> Void)) {
        guard let transaction = transaction else { return }
        let signedTransaction = "0x\(Cereal.shared.signWithWallet(hex: transaction))"

        EthereumAPIClient.shared.sendSignedTransaction(originalTransaction: transaction, transactionSignature: signedTransaction) { [weak self] success, _, error in
            completion(error)
        }
    }
}
