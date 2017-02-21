import Foundation

private var stateAssociationKey: Void?

extension TSInteraction {

    public enum PaymentState: Int {
        case none = 0
        case pendingConfirmation = 1
        case failed = 2
        case rejected = 3
        case paid = 4
    }

    private var paymentStateRaw: Int {
        get {
            return objc_getAssociatedObject(self, &stateAssociationKey) as? Int ?? 0
        }
        set {
            objc_setAssociatedObject(self, &stateAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    public var paymentState: PaymentState {
        get {
            return PaymentState(rawValue: self.paymentStateRaw)!
        }
        set {
            self.paymentStateRaw = newValue.rawValue
        }
    }
}
