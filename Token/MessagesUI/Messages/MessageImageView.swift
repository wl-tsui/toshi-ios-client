import Foundation
import UIKit
import TinyConstraints

typealias MessageImageViewImageTap = () -> Void

class MessageImageView: UIImageView {

    var imageTap: MessageImageViewImageTap?

    var widthConstraint: NSLayoutConstraint?

    let totalHorizontalMargin: CGFloat = 123

    lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tap(_:)))
        gestureRecognizer.delegate = self

        return gestureRecognizer
    }()

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = true
        self.contentMode = .scaleAspectFit
        self.clipsToBounds = true
        self.backgroundColor = .white

        self.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)

        self.addGestureRecognizer(self.tapGestureRecognizer)

        self.widthConstraint = width(UIScreen.main.bounds.width - self.totalHorizontalMargin, priority: .high)
    }

    func tap(_: UITapGestureRecognizer) {
        self.imageTap?()
    }
}

extension MessageImageView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_: UIGestureRecognizer, shouldReceive _: UIPress) -> Bool {
        return true
    }

    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if let otherGestureRecognizer = otherGestureRecognizer as? UIPanGestureRecognizer {
            if let collectionView = otherGestureRecognizer.view as? UICollectionView {
                let isMoving = collectionView.isDecelerating || collectionView.isDragging
                guard isMoving else { return true }

                self.tapGestureRecognizer.isEnabled = false
                self.tapGestureRecognizer.isEnabled = true
            }
        }

        return true
    }
}
