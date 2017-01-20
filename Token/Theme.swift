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
        return #colorLiteral(red: 0.6129867435, green: 0.6279211044, blue: 0.6319037676, alpha: 1)
    }

    public static var tintColor: UIColor {
        return #colorLiteral(red: 0, green: 0.761487186, blue: 0.3963804841, alpha: 1)
    }

    public static var viewBackgroundColor: UIColor {
        return .white
    }

    public static var messageViewBackgroundColor: UIColor {
        return #colorLiteral(red: 0.952861011, green: 0.952994287, blue: 0.9528188109, alpha: 1)
    }

    public static var navigationTitleTextColor: UIColor {
        return .white
    }

    public static var borderColor: UIColor {
        return #colorLiteral(red: 0.844350934, green: 0.8593074083, blue: 0.8632498384, alpha: 1)
    }

    public static var outgoingMessageBackgroundColor: UIColor {
        return #colorLiteral(red: 0, green: 0.7567782402, blue: 0.9079027772, alpha: 1)
    }

    public static var incomingMessageBackgroundColor: UIColor {
        return #colorLiteral(red: 0.9999160171, green: 1, blue: 0.9998719096, alpha: 1)
    }

    public static var outgoingMessageTextColor: UIColor {
        return .white
    }

    public static var incomingMessageTextColor: UIColor {
        return .black
    }
}

extension Theme {
    static func light(size: CGFloat) -> UIFont {
        return UIFont(name: "SFUIDisplay-Light", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightLight)
    }

    static func regular(size: CGFloat) -> UIFont {
        return UIFont(name: "SFUIDisplay-Regular", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightRegular)
    }

    static func semibold(size: CGFloat) -> UIFont {
        return UIFont(name: "SFUIDisplay-Semibold", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightSemibold)
    }

    static func bold(size: CGFloat) -> UIFont {
        return UIFont(name: "SFUIDisplay-Bold", size: size) ?? UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightBold)
    }
}
