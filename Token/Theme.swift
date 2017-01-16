import UIKit
import SweetUIKit
import SweetFoundation

public final class Theme: NSObject {
    public static var randomColor: UIColor {
        let colors = [UIColor.lightGray, UIColor.green, UIColor.red, UIColor.magenta, UIColor.purple, UIColor.blue, UIColor.yellow]
        
        return colors[Int(arc4random_uniform(UInt32(colors.count)))]
    }

    public static var lightTextColor: UIColor {
        return .white
    }

    public static var darkTextColor: UIColor {
        return .black
    }

    public static var tintColor: UIColor {
        return #colorLiteral(red: 0, green: 0.761487186, blue: 0.3963804841, alpha: 1)
    }

    public static var viewBackgroundColor: UIColor {
        return .white
    }

    public static var navigationTitleTextColor: UIColor {
        return .white
    }

    public static var borderColor: UIColor {
        return #colorLiteral(red: 0.844350934, green: 0.8593074083, blue: 0.8632498384, alpha: 1)
    }
}
