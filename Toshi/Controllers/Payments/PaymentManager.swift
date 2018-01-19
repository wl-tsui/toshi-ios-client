import Foundation
import UIKit

typealias PaymentInfo = (fiatString: String, estimatedFeesString: String, totalFiatString: String, totalEthereumString: String, balanceString: String, sufficientBalance: Bool)

class PaymentManager {

    private(set) var transaction: String?

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

    func fetchPaymentInfo(completion: @escaping ((_ paymentInfo: PaymentInfo) -> Void)) {
        EthereumAPIClient.shared.transactionSkeleton(for: parameters) { [weak self] skeleton, error in
            guard error == nil else {
                // Handle error
                return
            }

            guard let gasPrice = skeleton.gasPrice, let gas = skeleton.gas, let transaction = skeleton.transaction, let weakSelf = self else { return }

            weakSelf.transaction = transaction


            let gasPriceValue = NSDecimalNumber(hexadecimalString: gasPrice)
            let gasValue = NSDecimalNumber(hexadecimalString: gas)

            let fee = gasPriceValue.decimalValue * gasValue.decimalValue
            let decimalNumberFee = NSDecimalNumber(decimal: fee)

            let exchangeRate = ExchangeRateClient.exchangeRate


            //WARNING: we need to test these values that the correspond with each other
            let fiatString = EthereumConverter.fiatValueStringWithCode(forWei: weakSelf.value, exchangeRate: exchangeRate)
            let estimatedFeesString = EthereumConverter.fiatValueStringWithCode(forWei: decimalNumberFee, exchangeRate: exchangeRate)

            let totalWei = weakSelf.value.adding(decimalNumberFee)
            let totalFiatString = EthereumConverter.fiatValueStringWithCode(forWei: totalWei, exchangeRate: exchangeRate)
            let totalEthereumString = EthereumConverter.ethereumValueString(forWei: totalWei)

            /// We don't care about the cached balance since we immediately want to know if the current balance is sufficient or not.
            EthereumAPIClient.shared.getBalance(cachedBalanceCompletion: { _, _ in }, fetchedBalanceCompletion: { fetchedBalance, error in
                //WARNING: What to do when we have an error here?

                let balanceString = EthereumConverter.fiatValueStringWithCode(forWei: fetchedBalance, exchangeRate: ExchangeRateClient.exchangeRate)
                let sufficientBalance = fetchedBalance.isGreaterOrEqualThen(value: totalWei)

                let paymentInfo = PaymentInfo(fiatString: fiatString, estimatedFeesString: estimatedFeesString, totalFiatString: totalFiatString, totalEthereumString: totalEthereumString, balanceString: balanceString, sufficientBalance: sufficientBalance)
                completion(paymentInfo)
            })
        }
    }

    func sendPayment(completion: @escaping ((_ error: ToshiError?, _ transactionHash: String?) -> Void)) {
        guard let transaction = transaction else { return }
        let signedTransaction = "0x\(Cereal.shared.signWithWallet(hex: transaction))"

        print("--- SENDING PAYMENT ---")

        EthereumAPIClient.shared.sendSignedTransaction(originalTransaction: transaction, transactionSignature: signedTransaction) { success, transactionHash, error in

            print("COMPLETED Payment: SUCCESS: \(success)")
            completion(error, transactionHash)
        }
    }
}
