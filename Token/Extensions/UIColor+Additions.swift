import UIKit

extension UIImage {
    func colored(with color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)

        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)

        let context = UIGraphicsGetCurrentContext()!

        color.setFill()
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.multiply)

        context.draw(self.cgImage!, in: rect)
        context.clip(to: rect, mask: self.cgImage!)
        context.addRect(rect)
        context.drawPath(using: .eoFill)

        let coloredImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return coloredImg!
    }
}
