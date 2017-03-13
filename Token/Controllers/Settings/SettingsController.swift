import UIKit
import SweetUIKit

open class SettingsController: SweetTableController {

    public var chatAPIClient: ChatAPIClient
    public var idAPIClient: IDAPIClient

    let numberOfSections = 3
    let numberOfRows = [1, 2, 4]
    let cellTypes: [BaseCell.Type] = [ProfileCell.self, SecurityCell.self, SettingsCell.self]
    let sectionTitles = ["Your profile", "Security", "Settings"]
    let sectionErrors = [nil, "Your account is at risk", nil]

    let securityTitles = ["Store backup phrase", "Choose trusted friends"]
    let settingsTitles = ["Local currency", "About", "Sign in on another device", "Sign out"]

    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }

    public init(idAPIClient: IDAPIClient, chatAPIClient: ChatAPIClient) {
        self.idAPIClient = idAPIClient
        self.chatAPIClient = chatAPIClient

        super.init(style: .grouped)

        self.title = "Settings"
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.backgroundColor = Theme.settingsBackgroundColor
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.separatorStyle = .none
        self.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)

        for type in self.cellTypes {
            self.tableView.register(type)
        }
    }
}

extension SettingsController: UITableViewDataSource {

    open func numberOfSections(in tableView: UITableView) -> Int {
        return self.numberOfSections
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows[section]
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeue(cellTypes[indexPath.section], for: indexPath)
    }

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return SettingsSectionHeader(title: sectionTitles[section], error: sectionErrors[section])
    }

    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
}

extension SettingsController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        if let cell = cell as? BaseCell {
            cell.selectionStyle = .none
            cell.setIndex(indexPath.row, from: tableView.numberOfRows(inSection: indexPath.section))
        }

        if let cell = cell as? SecurityCell {
            cell.title = securityTitles[indexPath.row]
        } else if let cell = cell as? SettingsCell {
            cell.title = settingsTitles[indexPath.row]
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            self.navigationController?.pushViewController(ProfileController(idAPIClient: self.idAPIClient), animated: true)
        } else if let cell = tableView.cellForRow(at: indexPath) as? SecurityCell {
            cell.checkbox.checked = !cell.checkbox.checked
        }
    }
}
