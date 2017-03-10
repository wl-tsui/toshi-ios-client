import SweetUIKit

open class SettingsController: SweetTableController {
    
    public var chatAPIClient: ChatAPIClient
    public var idAPIClient: IDAPIClient
    
    let numberOfSections = 3
    let numberOfRows = [1, 2, 4]
    let cellTypes: [BaseCell.Type] = [ProfileCell.self, SecurityCell.self, SettingsCell.self]
    let sectionTitles = ["Your profile", "Security", "Settings"]

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
        let view = UIView()
        
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.greyTextColor
        label.font = Theme.regular(size: 14)
        label.text = self.sectionTitles[section]
        view.addSubview(label)
        
        let margin: CGFloat = 16
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 5),
            label.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -margin)
            ])
        
        return view
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }

}

extension SettingsController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let cell = cell as? BaseCell {
            cell.selectionStyle = .none
            cell.setIndex(indexPath.row, from: tableView.numberOfRows(inSection: indexPath.section))
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected:\(indexPath)")
    }
}
