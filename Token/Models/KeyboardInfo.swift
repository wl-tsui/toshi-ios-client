import UIKit

public struct KeyboardInfo {
    public let beginFrame: CGRect
    public let endFrame: CGRect
    public let animationCurve: UIViewAnimationCurve
    public let animationDuration: TimeInterval

    public var animationOptions: UIViewAnimationOptions {
        switch animationCurve {
        case .easeInOut: return .curveEaseInOut
        case .easeIn: return .curveEaseIn
        case .easeOut: return .curveEaseOut
        case .linear: return .curveLinear
        }
    }

    init(_ info: [AnyHashable: Any]?) {
        self.beginFrame = (info?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        self.endFrame = (info?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        self.animationCurve = UIViewAnimationCurve(rawValue: info?[UIKeyboardAnimationCurveUserInfoKey] as? Int ?? 0) ?? .easeInOut
        self.animationDuration = TimeInterval(info?[UIKeyboardAnimationDurationUserInfoKey] as? Double ?? 0.0)
    }
}
