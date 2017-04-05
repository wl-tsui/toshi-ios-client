import UIKit

extension UIViewAnimationOptions {

    static var easeIn: UIViewAnimationOptions {
        return [.curveEaseIn, .beginFromCurrentState, .allowUserInteraction]
    }

    static var easeOut: UIViewAnimationOptions {
        return [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]
    }
}

public extension UIView {

    static func highlightAnimation(_ animations: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOut, animations: animations, completion: nil)
    }

    func bounce() {
        self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)

        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 200, options: .easeOut, animations: {
            self.transform = .identity
        }, completion: nil)
    }

    func shake() {
        self.transform = CGAffineTransform(translationX: 10, y: 0)

        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 50, options: .easeOut, animations: {
            self.transform = .identity
        }, completion: nil)
    }
}
