import UIKit

class TGClockProgressView: UIView {

    var frameView = UIImageView()
    var minView = UIImageView()
    var hourView = UIImageView()

    var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        frameView.frame = bounds
        minView.frame = bounds
        hourView.frame = bounds
    }

    func startAnimating() {
        if isAnimating {
            return
        }

        hourView.layer.removeAllAnimations()
        minView.layer.removeAllAnimations()

        isAnimating = true

        animateHourView()
        animateMinView()
    }

    func stopAnimating() {
        guard isAnimating else {
            return
        }

        isAnimating = false

        hourView.layer.removeAllAnimations()
        minView.layer.removeAllAnimations()
    }

    private func commonInit() {
        backgroundColor = UIColor.clear

        frameView.image = Constant.progressFrameImage
        addSubview(frameView)

        minView.image = Constant.progressMinImage
        addSubview(minView)

        hourView.image = Constant.progressHourImage
        addSubview(hourView)
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
