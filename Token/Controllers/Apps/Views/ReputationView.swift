import UIKit
import SweetUIKit

class ReputationView: UIView {
    static let height: CGFloat = 105

    private lazy var ratingLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = "4.5"
        label.font = Theme.light(size: 49)
        label.textColor = Theme.ratingTint
        label.textAlignment = .center

        return label
    }()

    private lazy var ratingView: RatingView = {
        let view = RatingView(numberOfStars: 5)
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    private lazy var ratingsCountLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = "522 ratings"
        label.textColor = Theme.lightGreyTextColor
        label.font = Theme.regular(size: 14)

        return label
    }()

    private lazy var fiveStarsBarView: ReputationBarView = {
        let view = ReputationBarView(withAutoLayout: true)
        view.numberOfStars = 5
        view.percentage = 0.5

        return view
    }()

    private lazy var fourStarsBarView: ReputationBarView = {
        let view = ReputationBarView(withAutoLayout: true)
        view.numberOfStars = 4
        view.percentage = 1

        return view
    }()

    private lazy var threeStarsBarView: ReputationBarView = {
        let view = ReputationBarView(withAutoLayout: true)
        view.numberOfStars = 3
        view.percentage = 0.2

        return view
    }()

    private lazy var twoStarsBarView: ReputationBarView = {
        let view = ReputationBarView(withAutoLayout: true)
        view.numberOfStars = 2
        view.percentage = 0.1

        return view
    }()

    private lazy var oneStarsBarView: ReputationBarView = {
        let view = ReputationBarView(withAutoLayout: true)
        view.numberOfStars = 1
        view.percentage = 0

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.ratingLabel)
        self.addSubview(self.ratingView)
        self.addSubview(self.ratingsCountLabel)
        self.addSubview(self.fiveStarsBarView)
        self.addSubview(self.fourStarsBarView)
        self.addSubview(self.threeStarsBarView)
        self.addSubview(self.twoStarsBarView)
        self.addSubview(self.oneStarsBarView)

        let horizontalMargin: CGFloat = 31
        let height: CGFloat = 16
        let bottomSpacing: CGFloat = 2

        NSLayoutConstraint.activate([
            self.ratingLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.ratingLabel.leftAnchor.constraint(equalTo: self.leftAnchor),

            self.ratingView.topAnchor.constraint(equalTo: self.ratingLabel.bottomAnchor, constant: 5),
            self.ratingView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 5),

            self.ratingsCountLabel.topAnchor.constraint(equalTo: self.ratingView.bottomAnchor, constant: 10),
            self.ratingsCountLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 5),

            self.fiveStarsBarView.topAnchor.constraint(equalTo: self.topAnchor, constant: 9),
            self.fiveStarsBarView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.fiveStarsBarView.leftAnchor.constraint(equalTo: self.ratingsCountLabel.rightAnchor, constant: horizontalMargin),
            self.fiveStarsBarView.heightAnchor.constraint(equalToConstant: height),

            self.fourStarsBarView.topAnchor.constraint(equalTo: self.fiveStarsBarView.bottomAnchor, constant: bottomSpacing),
            self.fourStarsBarView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.fourStarsBarView.leftAnchor.constraint(equalTo: self.ratingsCountLabel.rightAnchor, constant: horizontalMargin),
            self.fourStarsBarView.heightAnchor.constraint(equalToConstant: height),

            self.threeStarsBarView.topAnchor.constraint(equalTo: self.fourStarsBarView.bottomAnchor, constant: bottomSpacing),
            self.threeStarsBarView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.threeStarsBarView.leftAnchor.constraint(equalTo: self.ratingsCountLabel.rightAnchor, constant: horizontalMargin),
            self.threeStarsBarView.heightAnchor.constraint(equalToConstant: height),

            self.twoStarsBarView.topAnchor.constraint(equalTo: self.threeStarsBarView.bottomAnchor, constant: bottomSpacing),
            self.twoStarsBarView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.twoStarsBarView.leftAnchor.constraint(equalTo: self.ratingsCountLabel.rightAnchor, constant: horizontalMargin),
            self.twoStarsBarView.heightAnchor.constraint(equalToConstant: height),

            self.oneStarsBarView.topAnchor.constraint(equalTo: self.twoStarsBarView.bottomAnchor, constant: bottomSpacing),
            self.oneStarsBarView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.oneStarsBarView.leftAnchor.constraint(equalTo: self.ratingsCountLabel.rightAnchor, constant: horizontalMargin),
            self.oneStarsBarView.heightAnchor.constraint(equalToConstant: height),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var reviewCount: Int = 0 {
        didSet {
            self.ratingsCountLabel.text = String(describing: self.reviewCount)
        }
    }
}

class ReputationBarView: UIView {
    private lazy var numberLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.greyTextColor
        label.font = Theme.medium(size: 13)
        label.text = "5"

        return label
    }()

    private lazy var starImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "gray-star"))
        imageView.translatesAutoresizingMaskIntoConstraints = false

        return imageView
    }()

    private lazy var barView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.ratingTint
        view.layer.cornerRadius = 2.0

        return view
    }()

    lazy var barWidthAnchor: NSLayoutConstraint = {
        return self.barView.widthAnchor.constraint(equalToConstant: self.totalWidth)
    }()

    let totalWidth: CGFloat = 180

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.numberLabel)
        self.addSubview(self.starImageView)
        self.addSubview(self.barView)

        NSLayoutConstraint.activate([
            self.numberLabel.topAnchor.constraint(equalTo: self.topAnchor),
            self.numberLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.numberLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.numberLabel.widthAnchor.constraint(equalToConstant: 8),

            self.starImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 2),
            self.starImageView.leftAnchor.constraint(equalTo: self.numberLabel.rightAnchor, constant: 5),

            self.barView.topAnchor.constraint(equalTo: self.topAnchor),
            self.barView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.barView.leftAnchor.constraint(equalTo: self.starImageView.rightAnchor, constant: 8),
        ])

        self.barWidthAnchor.isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var numberOfStars: Int = 0 {
        didSet {
            self.numberLabel.text = String(describing: self.numberOfStars)
        }
    }

    var percentage: CGFloat = 0 {
        didSet {
            self.barWidthAnchor.constant = (self.percentage * self.totalWidth)
            self.layoutIfNeeded()
        }
    }
}
