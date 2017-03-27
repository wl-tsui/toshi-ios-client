import UIKit

class TGClockProgressView: UIView {

    var frameView = UIImageView()
    var minView = UIImageView()
    var hourView = UIImageView()

    var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.frameView.frame = bounds
        self.minView.frame = bounds
        self.hourView.frame = bounds
    }

    func startAnimating() {
        if isAnimating {
            return
        }

        self.hourView.layer.removeAllAnimations()
        self.minView.layer.removeAllAnimations()

        self.isAnimating = true

        self.animateHourView()
        self.animateMinView()
    }

    func stopAnimating() {
        guard isAnimating else {
            return
        }

        self.isAnimating = false

        self.hourView.layer.removeAllAnimations()
        self.minView.layer.removeAllAnimations()
    }

    private func commonInit() {
        backgroundColor = UIColor.clear

        self.frameView.image = Constant.progressFrameImage
        addSubview(self.frameView)

        self.minView.image = Constant.progressMinImage
        addSubview(self.minView)

        self.hourView.image = Constant.progressHourImage
        addSubview(self.hourView)
    }

    private func animateHourView() {
        UIView.animate(withDuration: Constant.hourDuration, delay: 0.0, options: .curveLinear, animations: { () -> Void in
            self.hourView.transform = self.hourView.transform.rotated(by: CGFloat(M_2_PI))
        }, completion: { finished -> Void in
            if finished {
                self.animateHourView()
            } else {
                self.isAnimating = false
            }
        })
    }

    private func animateMinView() {
        UIView.animate(withDuration: Constant.minuteDuration, delay: 0.0, options: .curveLinear, animations: { () -> Void in
            self.minView.transform = self.minView.transform.rotated(by: CGFloat(M_2_PI))
        }, completion: { finished -> Void in
            if finished {
                self.animateMinView()
            } else {
                self.isAnimating = false
            }
        })
    }

    struct Constant {
        static let progressFrameImage = #imageLiteral(resourceName: "TGClockGreenFrame").withRenderingMode(.alwaysTemplate)
        static let progressMinImage = #imageLiteral(resourceName: "TGClockGreenMin").withRenderingMode(.alwaysTemplate)
        static let progressHourImage = #imageLiteral(resourceName: "TGClockGreenHour").withRenderingMode(.alwaysTemplate)
        static let minuteDuration = TimeInterval(0.3)
        static let hourDuration = TimeInterval(1.8)
    }
}
