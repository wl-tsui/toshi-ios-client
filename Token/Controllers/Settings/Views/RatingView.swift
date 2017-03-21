import UIKit
import SweetUIKit

open class RatingView: UIView {

    static let starSize: CGFloat = 12
    private var rating: Float = 0
    private var numberOfStars: Int = 0

    private lazy var backgroundStars: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.mask = self.starsMask
        view.backgroundColor = Theme.ratingBackground

        return view
    }()

    private lazy var ratingStars: UIView = {
        let view = UIView(withAutoLayout: true)
        view.layer.mask = self.starsMask
        view.backgroundColor = Theme.ratingTint

        return view
    }()

    private lazy var ratingConstraint: NSLayoutConstraint = {
        self.ratingStars.widthAnchor.constraint(equalToConstant: 0)
    }()

    convenience init(numberOfStars: Int) {
        self.init(frame: .zero)
        self.numberOfStars = numberOfStars

        self.addSubview(self.backgroundStars)

        NSLayoutConstraint.activate([
            self.backgroundStars.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundStars.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.backgroundStars.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.backgroundStars.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.backgroundStars.widthAnchor.constraint(equalToConstant: RatingView.starSize * CGFloat(numberOfStars)).priority(.high),
            self.backgroundStars.heightAnchor.constraint(equalToConstant: RatingView.starSize).priority(.high),
        ])

        self.addSubview(self.ratingStars)

        NSLayoutConstraint.activate([
            self.ratingStars.topAnchor.constraint(equalTo: self.topAnchor),
            self.ratingStars.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.ratingStars.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])

        self.ratingConstraint.isActive = true
    }

    func set(rating: Float, animated: Bool = false) {
        self.rating = min(Float(self.numberOfStars), max(0, rating))
        self.ratingConstraint.constant = RatingView.starSize * CGFloat(rating)

        if animated {
            UIViewPropertyAnimator(duration: 1, dampingRatio: 0.9) {
                self.layoutIfNeeded()
            }.startAnimation()
        } else {
            self.layoutIfNeeded()
        }
    }

    var starsMask: CALayer {
        let starRadius = RatingView.starSize / 2

        let mask = CAShapeLayer()
        mask.frame = CGRect(x: 0, y: 0, width: RatingView.starSize, height: RatingView.starSize)
        mask.position = CGPoint(x: starRadius, y: starRadius)

        var mutablePath: CGMutablePath?

        for i in 0 ..< numberOfStars {

            if let mutablePath = mutablePath {
                mutablePath.addPath(self.starPath(with: starRadius, offset: CGFloat(i) * RatingView.starSize))
            } else {
                mutablePath = self.starPath(with: starRadius).mutableCopy()
            }
        }

        mask.path = mutablePath

        return mask
    }

    func starPath(with radius: CGFloat, offset: CGFloat = 0) -> CGPath {
        let center = CGPoint(x: radius, y: radius)
        let theta = CGFloat(M_PI * 2) * (2 / 5)
        let flipVertical: CGFloat = -1

        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x, y: radius * center.y * flipVertical))

        for i in 0 ..< 6 {
            let x = radius * sin(CGFloat(i) * theta) + offset
            let y = radius * cos(CGFloat(i) * theta)
            path.addLine(to: CGPoint(x: x + center.x, y: (y * flipVertical) + center.y))
        }

        path.close()

        return path.cgPath
    }
}
