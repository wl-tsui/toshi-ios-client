import Foundation
import PromiseKit

/// Not sure what this does yet, or if we actually need it.
class AccountManager: NSObject {
    let TAG = "[AccountManager]"
    let textSecureAccountManager: TSAccountManager

    required init(textSecureAccountManager: TSAccountManager) {
        self.textSecureAccountManager = textSecureAccountManager
    }

    @objc func register(verificationCode: String) -> AnyPromise {
        return AnyPromise(register(verificationCode: verificationCode))
    }

    func register(verificationCode: String) -> Promise<Void> {
        return firstly {
            Promise { fulfill, reject in

                if verificationCode.characters.count == 0 {
                    let error = OWSErrorWithCodeDescription(.userError, NSLocalizedString("REGISTRATION_ERROR_BLANK_VERIFICATION_CODE", comment: "alert body during registration"))
                    reject(error)
                }

                fulfill()
            }
        }.then {
            print("\(self.TAG) verification code looks well formed.")

            return self.registerForTextSecure(verificationCode: verificationCode)
        }.then {
            print("\(self.TAG) successfully registered for TextSecure")
        }
    }

    func updatePushTokens(pushToken: String, voipToken: String) -> Promise<Void> {
        return firstly {
            self.updateTextSecurePushTokens(pushToken: pushToken, voipToken: voipToken)
        }.then {
            print("\(self.TAG) Successfully updated text secure push tokens.")
        }
    }

    private func updateTextSecurePushTokens(pushToken: String, voipToken: String) -> Promise<Void> {
        return Promise { fulfill, reject in
            self.textSecureAccountManager.registerForPushNotifications(pushToken: pushToken, voipToken: voipToken, success: fulfill, failure: reject)
        }
    }

    private func registerForTextSecure(verificationCode: String) -> Promise<Void> {
        return Promise { fulfill, reject in
            self.textSecureAccountManager.verifyAccount(withCode: verificationCode,
                                                        success: fulfill,
                                                        failure: reject)
        }
    }
}
