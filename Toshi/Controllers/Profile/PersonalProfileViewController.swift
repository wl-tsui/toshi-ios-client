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

open class PersonalProfileViewController: UIViewController {

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    private var personalProfileView: ProfileView? { return view as? ProfileView }

    public init() {
        super.init(nibName: nil, bundle: nil)

        edgesForExtendedLayout = .bottom
        title = "Profile"
    }

    public required init?(coder _: NSCoder) {
        fatalError("")
    }

    open override func loadView() {
        view = ProfileView(viewType: .personalProfile)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.lightGrayBackgroundColor
        personalProfileView?.personalProfileDelegate = self
        
        updateReputation()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(false)

        if let currentUser = TokenUser.current {
            personalProfileView?.setContact(currentUser)

            AvatarManager.shared.avatar(for: currentUser.avatarPath) { [weak self] image, _ in
                self?.personalProfileView?.avatarImageView.image = image
            }
        }
    }

    fileprivate func updateReputation() {
        guard let currentUser = TokenUser.current else {
            CrashlyticsLogger.log("No current user during session", attributes: [.occured: "Profile Controller"])
            fatalError("No current user on Profile controller")
        }
        
        RatingsClient.shared.scores(for: currentUser.address) { [weak self] ratingScore in
            self?.personalProfileView?.reputationView.setScore(ratingScore)
        }
    }
}

extension PersonalProfileViewController: PersonalProfileViewDelegate {
    func didTapEditProfileButton(in view: ProfileView) {
        let editController = ProfileEditController()
        navigationController?.pushViewController(editController, animated: true)
    }
}
