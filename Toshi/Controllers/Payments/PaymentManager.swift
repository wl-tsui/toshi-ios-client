import Foundation
import UIKit

typealias PaymentInfo = (fiatString: String, estimatedFeesString: String, totalFiatString: String, totalEthereumString: String, sufficientBalance: Bool)

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

    private var balance: NSDecimalNumber = 0

    init(withValue value: NSDecimalNumber, andPaymentAddress address: String) {
       self.value = value
       self.paymentAddress = address
    }

    func fetchAndUpdateBalance(cachedCompletion: @escaping ((_ balanceString: String) -> Void), fetchedCompletion: @escaping ((_ balanceString: String) -> Void)) {
        EthereumAPIClient.shared.getBalance(cachedBalanceCompletion: { cachedBalance, _ in
            self.balance = cachedBalance
            let balanceString = EthereumConverter.fiatValueStringWithCode(forWei: cachedBalance, exchangeRate: ExchangeRateClient.exchangeRate)
            cachedCompletion(balanceString)
        }, fetchedBalanceCompletion: { fetchedBalance, error in
            //WARNING: What to do when we have an error here?

            self.balance = fetchedBalance
            let balanceString = EthereumConverter.fiatValueStringWithCode(forWei: fetchedBalance, exchangeRate: ExchangeRateClient.exchangeRate)
            fetchedCompletion(balanceString)
        })
    }

    func transactionSkeleton(completion: @escaping ((_ paymentInfo: PaymentInfo) -> Void)) {
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


                //WARNING: we need to test these values that the correspond with each other
                let fiatString = EthereumConverter.fiatValueStringWithCode(forWei: weakSelf.value, exchangeRate: exchangeRate)
                let estimatedFeesString = EthereumConverter.fiatValueStringWithCode(forWei: decimalNumberFee, exchangeRate: exchangeRate)

                let totalWei = weakSelf.value.adding(decimalNumberFee)
                let totalFiatString = EthereumConverter.fiatValueStringWithCode(forWei: totalWei, exchangeRate: exchangeRate)
                let totalEthereumString = EthereumConverter.ethereumValueString(forWei: totalWei)

                let sufficientBalance = weakSelf.isBalanceSufficientFor(transactionTotalAmount: totalWei)

                let paymentInfo = PaymentInfo(fiatString: fiatString, estimatedFeesString: estimatedFeesString, totalFiatString: totalFiatString, totalEthereumString: totalEthereumString, sufficientBalance: sufficientBalance)
                completion(paymentInfo)
            } else {
                //WARNING: should deal with error
            }
        }
    }

    //WARNING: this method needs muchos testing!
    private func isBalanceSufficientFor(transactionTotalAmount: NSDecimalNumber) -> Bool {
        let result = balance.compare(transactionTotalAmount)

        return (result == .orderedAscending) ? false : true
    }

    func sendPayment(completion: @escaping ((_ error: ToshiError?) -> Void)) {
        guard let transaction = transaction else { return }
        let signedTransaction = "0x\(Cereal.shared.signWithWallet(hex: transaction))"

        EthereumAPIClient.shared.sendSignedTransaction(originalTransaction: transaction, transactionSignature: signedTransaction) { [weak self] success, _, error in
            completion(error)
        }
    }
}
