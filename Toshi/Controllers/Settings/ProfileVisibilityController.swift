import UIKit
import SweetUIKit

class ProfileVisibilityController: UITableViewController {

    @IBOutlet private weak var visibilitySwitch: UISwitch!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.visibilitySwitch.isOn = TokenUser.current?.isPublic ?? false
    }

    @IBAction private func publicStateDidChange(_ sender: UISwitch) {
        TokenUser.current?.updatePublicState(to: sender.isOn)
    }
}
