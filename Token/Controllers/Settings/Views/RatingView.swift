import SweetUIKit

open class RatingView: UIView {
    
    static let starSize: CGFloat = 12
    
    private var rating: Float = 0
    private var numberOfStars: Int = 0
    private var ratingConstraint: NSLayoutConstraint?
    
    convenience init(numberOfStars: Int) {
        self.init(frame: .zero)
        
        self.numberOfStars = numberOfStars

        let backgroundStars = UIView(withAutoLayout: true)
        backgroundStars.layer.mask = self.starsMask
        backgroundStars.backgroundColor = Theme.ratingBackground
        self.addSubview(backgroundStars)
        
        NSLayoutConstraint.activate([
            backgroundStars.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundStars.leftAnchor.constraint(equalTo: self.leftAnchor),
            backgroundStars.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundStars.rightAnchor.constraint(equalTo: self.rightAnchor),
            backgroundStars.widthAnchor.constraint(equalToConstant: RatingView.starSize * CGFloat(numberOfStars)),
            backgroundStars.heightAnchor.constraint(equalToConstant: RatingView.starSize)
            ])
        
        let ratingStars = UIView(withAutoLayout: true)
        ratingStars.layer.mask = self.starsMask
        ratingStars.backgroundColor = Theme.ratingTint
        self.addSubview(ratingStars)
        
        NSLayoutConstraint.activate([
            ratingStars.topAnchor.constraint(equalTo: self.topAnchor),
            ratingStars.leftAnchor.constraint(equalTo: self.leftAnchor),
            ratingStars.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            ratingStars.heightAnchor.constraint(equalToConstant: RatingView.starSize)
            ])
        
        self.ratingConstraint = ratingStars.widthAnchor.constraint(equalToConstant: 0)
        self.ratingConstraint?.isActive = true
        self.layoutIfNeeded()
    }
    
    func set(rating: Float, animated: Bool = false) {
        self.rating = min(Float(self.numberOfStars), max(0, rating))
        self.ratingConstraint?.constant = RatingView.starSize * CGFloat(rating)
        
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
        
        for i in 0..<numberOfStars {
            
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
        
        for i in 0..<6 {
            let x = radius * sin(CGFloat(i) * theta) + offset
            let y = radius * cos(CGFloat(i) * theta)
            path.addLine(to: CGPoint(x: x + center.x, y: (y * flipVertical) + center.y))
        }
        
        path.close()
        
        return path.cgPath
    }
}
