import UIKit
import SweetUIKit

open class ProfileController: UIViewController {

    lazy var avatar: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.clipsToBounds = true

        return view
    }()

    lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.textAlignment = .center

        return view
    }()

    lazy var editProfileButton: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setTitle("Edit Profile", for: .normal)
        view.setTitleColor(Theme.darkTextColor, for: .normal)

        view.layer.cornerRadius = 4.0
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = 1.0

        return view
    }()

    lazy var aboutSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var aboutTitleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.text = "About"
        view.textColor = Theme.darkTextColor

        return view
    }()

    lazy var aboutContentLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)

        return view
    }()

    lazy var locationSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    lazy var locationTitleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.text = "Location"
        view.textColor = Theme.darkTextColor

        return view
    }()

    lazy var locationContentLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)

        return view
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = .white
        self.tabBarItem = UITabBarItem(title: "Profile", image: #imageLiteral(resourceName: "Profile"), tag: 2)
        self.title = "Profile"
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    open override func loadView() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true

        self.view = scrollView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.automaticallyAdjustsScrollViewInsets = false
        self.addSubviewsAndConstraints()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.nameLabel.text = User.current?.username
        self.avatar.image = User.current?.avatar ?? #imageLiteral(resourceName: "igor")
    }

    func addSubviewsAndConstraints() {

        // debug
        [avatar].forEach { (view) in
            view.backgroundColor = Theme.randomColor
        }
        
        self.view.addSubview(self.avatar)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.editProfileButton)

        self.view.addSubview(self.aboutSeparatorView)
        self.view.addSubview(self.aboutTitleLabel)
        self.view.addSubview(self.aboutContentLabel)

        self.view.addSubview(self.locationSeparatorView)
        self.view.addSubview(self.locationTitleLabel)
        self.view.addSubview(self.locationContentLabel)

        let height: CGFloat = 40.0
        let margin: CGFloat = 20.0

        self.avatar.set(height: 166)
        self.avatar.set(width: 166)
        self.avatar.layer.cornerRadius = 166/2

        self.avatar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: margin).isActive = true
        self.avatar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true

        self.nameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.nameLabel.topAnchor.constraint(equalTo: self.avatar.bottomAnchor, constant: margin).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: margin).isActive = true
        self.nameLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -margin).isActive = true

        self.editProfileButton.set(height: height)
        self.editProfileButton.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: margin).isActive = true
        self.editProfileButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: margin).isActive = true
        self.editProfileButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -margin).isActive = true

        // We set the view and separator width cosntraints to be the same, to force the scrollview content size to conform to the window
        // otherwise no view is requiring a width of the window, and the scrollview contentSize will shrink to the smallest 
        // possible width that satisfy all other constraints.
        self.aboutSeparatorView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.aboutSeparatorView.set(height: 1.0)
        self.aboutSeparatorView.topAnchor.constraint(equalTo: self.editProfileButton.bottomAnchor, constant: margin).isActive = true
        self.aboutSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.aboutSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.aboutTitleLabel.set(height: 32)
        self.aboutTitleLabel.topAnchor.constraint(equalTo: self.aboutSeparatorView.bottomAnchor, constant: margin).isActive = true
        self.aboutTitleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: margin).isActive = true
        self.aboutTitleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -margin).isActive = true

        self.aboutContentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        self.aboutContentLabel.topAnchor.constraint(equalTo: self.aboutTitleLabel.bottomAnchor, constant: margin).isActive = true
        self.aboutContentLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: margin).isActive = true
        self.aboutContentLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -margin).isActive = true

        self.locationSeparatorView.set(height: 1.0)
        self.locationSeparatorView.topAnchor.constraint(equalTo: self.aboutContentLabel.bottomAnchor, constant: margin).isActive = true
        self.locationSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.locationSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.locationTitleLabel.set(height: 32)
        self.locationTitleLabel.topAnchor.constraint(equalTo: self.locationSeparatorView.bottomAnchor, constant: margin).isActive = true
        self.locationTitleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: margin).isActive = true
        self.locationTitleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -margin).isActive = true

        self.locationContentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.locationContentLabel.topAnchor.constraint(equalTo: self.locationTitleLabel.bottomAnchor, constant: margin).isActive = true
        self.locationContentLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.locationContentLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        // TODO: figure out a way to abstract the -49pts from the tabbar height.
        self.locationContentLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -69).isActive = true
    }
}
