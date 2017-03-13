import UIKit

public enum LayoutPriority: UILayoutPriority {
    case required = 1000
    case high = 750
    case low = 250
    case fittingSize = 50
    
    public var value: UILayoutPriority {
        return self.rawValue
    }
}

public extension NSLayoutConstraint {
    
    func priority(_ priority: LayoutPriority) -> Self {
        self.priority = priority.value
        return self
    }
}
