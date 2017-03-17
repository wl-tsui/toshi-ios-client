import UIKit

extension UIViewAnimationOptions {
    
    static var easeOut: UIViewAnimationOptions {
        return [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]
    }
}

public extension UIView {
    
    static func highlightAnimation(_ animations: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOut, animations: animations, completion: nil)
    }
}
