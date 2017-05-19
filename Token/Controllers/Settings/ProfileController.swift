// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit
import SweetUIKit
import CoreImage

open class ProfileController: UIViewController {

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    fileprivate lazy var avatarImageView: AvatarImageView = {
        let view = AvatarImageView(withAutoLayout: true)

        return view
    }()

    fileprivate lazy var nameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.font = Theme.regular(size: 24)

        return view
    }()

    fileprivate lazy var usernameLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.numberOfLines = 0
        view.font = Theme.regular(size: 16)
        view.textColor = Theme.greyTextColor

        return view
    }()

    fileprivate lazy var editProfileButton: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setAttributedTitle(NSAttributedString(string: "Edit Profile", attributes: [NSFontAttributeName: Theme.regular(size: 17), NSForegroundColorAttributeName: Theme.tintColor]), for: .normal)
        view.setAttributedTitle(NSAttributedString(string: "Edit Profile", attributes: [NSFontAttributeName: Theme.regular(size: 17), NSForegroundColorAttributeName: Theme.lightGreyTextColor]), for: .highlighted)
        view.addTarget(self, action: #selector(didTapEditProfileButton), for: .touchUpInside)

        return view
    }()

    fileprivate lazy var editSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor
        view.set(height: 1.0 / UIScreen.main.scale)

        return view
    }()

    fileprivate lazy var aboutContentLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 17)
        view.numberOfLines = 0

        return view
    }()

    fileprivate lazy var locationContentLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.font = Theme.regular(size: 16)
        view.textColor = Theme.lightGreyTextColor
        view.numberOfLines = 0

        return view
    }()

    fileprivate lazy var contentBackgroundView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.viewBackgroundColor

        return view
    }()

    fileprivate lazy var topSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.settingsBackgroundColor
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = 1.0 / UIScreen.main.scale
        view.set(height: 1.0 / UIScreen.main.scale)

        return view
    }()

    fileprivate lazy var reputationSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.settingsBackgroundColor
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = 1.0 / UIScreen.main.scale
        view.set(height: 1.0 / UIScreen.main.scale)

        return view
    }()

    fileprivate lazy var bottomSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.settingsBackgroundColor
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = 1.0 / UIScreen.main.scale
        view.set(height: 1.0 / UIScreen.main.scale)

        return view
    }()

    fileprivate lazy var reputationView: ReputationView = {
        let view = ReputationView(withAutoLayout: true)

        return view
    }()

    fileprivate lazy var reputationBackgroundView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.viewBackgroundColor

        return view
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)

        self.edgesForExtendedLayout = .bottom
        self.title = "Profile"
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    open override func loadView() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true

        self.view = scrollView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = Theme.settingsBackgroundColor

        self.addSubviewsAndConstraints()

        NotificationCenter.default.addObserver(self, selector: #selector(self.avatarDidUpdate), name: .CurrentUserDidUpdateAvatarNotification, object: nil)

        self.reputationView.setScore(.zero)
        self.updateReputation()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let name = TokenUser.current?.name, !name.isEmpty, let username = TokenUser.current?.displayUsername {
            self.nameLabel.text = name
            self.usernameLabel.text = username
        } else if let username = TokenUser.current?.displayUsername {
            self.usernameLabel.text = nil
            self.nameLabel.text = username
        }

        self.aboutContentLabel.text = TokenUser.current?.about
        self.locationContentLabel.text = TokenUser.current?.location
        self.avatarImageView.image = TokenUser.current?.avatar
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    fileprivate func addSubviewsAndConstraints() {
        self.view.addSubview(self.reputationBackgroundView)
        self.view.addSubview(self.contentBackgroundView)

        self.view.addSubview(self.avatarImageView)
        self.view.addSubview(self.nameLabel)
        self.view.addSubview(self.usernameLabel)
        self.view.addSubview(self.aboutContentLabel)
        self.view.addSubview(self.locationContentLabel)

        self.view.addSubview(self.editSeparatorView)
        self.view.addSubview(self.editProfileButton)

        self.view.addSubview(self.topSeparatorView)

        self.view.addSubview(self.reputationSeparatorView)
        self.view.addSubview(self.reputationView)
        self.view.addSubview(self.bottomSeparatorView)

        let height: CGFloat = 26.0
        let marginHorizontal: CGFloat = 16.0
        let marginVertical: CGFloat = 14.0
        let itemSpacing: CGFloat = 8.0
        let avatarSize: CGFloat = 60.0

        self.avatarImageView.set(height: avatarSize)
        self.avatarImageView.set(width: avatarSize)
        self.avatarImageView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 28).isActive = true
        self.avatarImageView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true

        self.nameLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        self.nameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 22).isActive = true
        self.nameLabel.topAnchor.constraint(equalTo: self.avatarImageView.topAnchor).isActive = true
        self.nameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: marginHorizontal).isActive = true
        self.nameLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.usernameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16).isActive = true
        self.usernameLabel.topAnchor.constraint(equalTo: self.nameLabel.bottomAnchor, constant: itemSpacing).isActive = true
        self.usernameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: marginHorizontal).isActive = true
        self.usernameLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.aboutContentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.aboutContentLabel.topAnchor.constraint(equalTo: self.avatarImageView.bottomAnchor, constant: marginVertical).isActive = true
        self.aboutContentLabel.leftAnchor.constraint(equalTo: self.avatarImageView.leftAnchor).isActive = true
        self.aboutContentLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.locationContentLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        self.locationContentLabel.topAnchor.constraint(equalTo: self.aboutContentLabel.bottomAnchor, constant: itemSpacing).isActive = true
        self.locationContentLabel.leftAnchor.constraint(equalTo: self.avatarImageView.leftAnchor).isActive = true
        self.locationContentLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.locationContentLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -marginVertical).isActive = true

        self.editSeparatorView.topAnchor.constraint(equalTo: self.locationContentLabel.bottomAnchor, constant: marginVertical).isActive = true
        self.editSeparatorView.leftAnchor.constraint(equalTo: self.avatarImageView.leftAnchor).isActive = true
        self.editSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.editSeparatorView.bottomAnchor.constraint(equalTo: self.editProfileButton.topAnchor, constant: -marginVertical).isActive = true

        self.editProfileButton.set(height: 22)
        self.editProfileButton.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.editProfileButton.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.contentBackgroundView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.contentBackgroundView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.contentBackgroundView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.contentBackgroundView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.contentBackgroundView.bottomAnchor.constraint(equalTo: self.topSeparatorView.topAnchor).isActive = true

        // We set the view and separator width cosntraints to be the same, to force the scrollview content size to conform to the window
        // otherwise no view is requiring a width of the window, and the scrollview contentSize will shrink to the smallest
        // possible width that satisfy all other constraints.
        self.topSeparatorView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.topSeparatorView.topAnchor.constraint(equalTo: self.editProfileButton.bottomAnchor, constant: marginVertical).isActive = true
        self.topSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.topSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.reputationSeparatorView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.reputationSeparatorView.topAnchor.constraint(equalTo: self.topSeparatorView.bottomAnchor, constant: 66.0).isActive = true
        self.reputationSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.reputationSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.reputationView.topAnchor.constraint(equalTo: self.reputationSeparatorView.bottomAnchor, constant: marginVertical).isActive = true
        self.reputationView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: marginHorizontal).isActive = true
        self.reputationView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -marginHorizontal).isActive = true

        self.bottomSeparatorView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.bottomSeparatorView.topAnchor.constraint(equalTo: self.reputationView.bottomAnchor, constant: marginVertical).isActive = true
        self.bottomSeparatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.bottomSeparatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.reputationBackgroundView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        self.reputationBackgroundView.topAnchor.constraint(equalTo: self.reputationSeparatorView.bottomAnchor).isActive = true
        self.reputationBackgroundView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.reputationBackgroundView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.reputationBackgroundView.bottomAnchor.constraint(equalTo: self.bottomSeparatorView.topAnchor).isActive = true
    }

    fileprivate func updateReputation() {
        RatingsClient.shared.scores(for: TokenUser.current!.address) { ratingScore in
            self.reputationView.setScore(ratingScore)
        }
    }

    @objc
    fileprivate func avatarDidUpdate() {
        let avatar = TokenUser.current?.avatar
        self.avatarImageView.image = avatar
    }

    @objc
    fileprivate func didTapEditProfileButton() {
        let editController = ProfileEditController()
        self.navigationController?.pushViewController(editController, animated: true)
    }
}
