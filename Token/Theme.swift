import UIKit
import SweetUIKit
import SweetFoundation

public final class Theme: NSObject { }

extension Theme {
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

    public static var greyTextColor: UIColor {
        return #colorLiteral(red: 0.2856194079, green: 0.2896994054, blue: 0.3457691371, alpha: 1)
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

    public static var ethereumBalanceLabelColor: UIColor {
        return UIColor(hex: "2C2C2C")
    }

    public static var ethereumBalanceLabelLightColor: UIColor {
        return UIColor(hex: "919191")
    }

    public static var ethereumBalanceCallToActionColor: UIColor {
        return UIColor(hex: "02BE6E")
    }

    public static var messagesBackgroundColor: UIColor {
        return UIColor(hex: "F9FAFB")
    }

    public static var separatorColor: UIColor {
        return UIColor(hex: "EFEFEF")
    }

    public static var messagesFloatingViewBackgroundColor: UIColor {
        return UIColor.white
    }
}

extension Theme {
    static func light(size: CGFloat) -> UIFont {
        return UIFont(name: "GTAmerica-Light", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightLight)
    }

    static func regular(size: CGFloat) -> UIFont {
        return UIFont(name: "GTAmerica-Regular", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightRegular)
    }

    static func semibold(size: CGFloat) -> UIFont {
        return UIFont(name: "GTAmerica-Semibold", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightSemibold)
    }

    static func bold(size: CGFloat) -> UIFont {
        return UIFont(name: "GTAmerica-Bold", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightBold)
    }

    public static var ethereumBalanceLabelFont: UIFont {
        return self.regular(size: 16)
    }

    public static var ethereumBalanceCallToActionFont: UIFont {
        return self.semibold(size: 13)
    }
}
