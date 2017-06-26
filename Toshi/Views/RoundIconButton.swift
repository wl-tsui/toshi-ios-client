import Foundation
import UIKit

class RoundIconButton: UIControl {

    private lazy var circle: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.tintColor
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false

        return view
    }()

    private lazy var icon: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = false

        return view
    }()

    convenience init(imageName: String, circleDiameter: CGFloat) {
        self.init(frame: .zero)

        self.circle.layer.cornerRadius = circleDiameter / 2
        addSubview(self.circle)

        self.circle.size(CGSize(width: circleDiameter, height: circleDiameter))
        self.circle.center(in: self)

        self.icon.image = UIImage(named: imageName)
        addSubview(self.icon)

        self.icon.center(in: self)
    }

    override var isEnabled: Bool {
        didSet {
            self.transform = self.isEnabled ? .identity : CGAffineTransform(scaleX: 0.5, y: 0.5)
            self.alpha = self.isEnabled ? 1 : 0

            self.circle.backgroundColor = self.isEnabled ? Theme.tintColor : Theme.greyTextColor
        }
    }
}
