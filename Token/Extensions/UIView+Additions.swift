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
    
    func bounce() {
        self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 150, options: .easeOut, animations: {
            self.transform = .identity
        }, completion: nil)
    }
}
