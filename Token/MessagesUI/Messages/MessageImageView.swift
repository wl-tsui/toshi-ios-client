import Foundation
import UIKit
import TinyConstraints

typealias MessageImageViewImageTap = () -> Void

class MessageImageView: UIView {

    var imageTap: MessageImageViewImageTap?

    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)

        return view
    }()

    lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(_:)))
        gestureRecognizer.allowableMovement = 0
        gestureRecognizer.minimumPressDuration = 0
        gestureRecognizer.delegate = self

        return gestureRecognizer
    }()

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

        self.clipsToBounds = true
        self.backgroundColor = .white

        self.addSubview(self.imageView)
        self.imageView.edges(to: self)

        self.addGestureRecognizer(self.tapGestureRecognizer)
        self.addGestureRecognizer(self.longPressGestureRecognizer)
    }

    func longPress(_ gestureRecognizer: UILongPressGestureRecognizer) {

        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction], animations: {
            switch gestureRecognizer.state {
            case .began, .changed, .possible:
                self.imageView.alpha = 0.9
            default:
                self.imageView.alpha = 1
            }
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 10, options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction], animations: {
            switch gestureRecognizer.state {
            case .began, .changed, .possible:
                self.imageView.layer.transform = CATransform3DMakeScale(1.03, 1.03, 1)
            default:
                self.imageView.layer.transform = CATransform3DIdentity
            }
        }, completion: nil)
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
                self.longPressGestureRecognizer.isEnabled = false
                self.tapGestureRecognizer.isEnabled = true
                self.longPressGestureRecognizer.isEnabled = true
            }
        }

        return true
    }
}
