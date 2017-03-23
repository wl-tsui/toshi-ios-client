import UIKit
import SweetUIKit

class AvatarImageView: UIImageView {
    var cornerRadius: CGFloat {
        set {
            self.layer.cornerRadius = newValue
        }
        get {
            return self.layer.cornerRadius
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.clipsToBounds = true
        self.backgroundColor = .lightGray

        self.contentMode = .scaleAspectFill
    }

    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
    }

    override init(image: UIImage?) {
        super.init(image: image)
    }

    required init?(coder _: NSCoder) {
        fatalError()
    }
}
