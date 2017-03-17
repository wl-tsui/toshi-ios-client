import UIKit
import SweetUIKit

class BackupPhraseEnableController: UIViewController {
    
    let idAPIClient: IDAPIClient
    
    lazy var titleLabel: TitleLabel = {
        let view = TitleLabel("Let’s secure your account")
        
        return view
    }()
    
    lazy var textLabel: UILabel = {
        let view = TextLabel("Storing a backup phrase will allow you to recover your funds if your phone is ever lost or stolen.\n\nIt’s important to store this backup phrase securely where nobody else can access it, such as on a piece of paper or in a password manager.")
        
        return view
    }()
    
    lazy var checkboxControl: CheckboxControl = {
        let text = "I understand that if I lose my backup phrase, I will be unable to recover access to my account."
        
        let view = CheckboxControl(withAutoLayout: true)
        view.title = text
        view.addTarget(self, action: #selector(checked(_:)), for: .touchUpInside)
        
        return view
    }()
    
    private lazy var actionButton: ActionButton = {
        let view = ActionButton(withAutoLayout: true)
        view.title = "Continue"
        view.isEnabled = false
        view.addTarget(self, action: #selector(proceed(_:)), for: .touchUpInside)
        
        return view
    }()
    
    private init() {
        fatalError()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("")
    }
    
    public init(idAPIClient: IDAPIClient) {
        self.idAPIClient = idAPIClient
        
        super.init(nibName: nil, bundle: nil)
        self.title = "Store backup phrase"
        self.hidesBottomBarWhenPushed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Theme.settingsBackgroundColor
        
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.textLabel)
        self.view.addSubview(self.checkboxControl)
        self.view.addSubview(self.actionButton)
        
        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40 + 64),
            self.titleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.titleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),
            
            self.textLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 20),
            self.textLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.textLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),
            
            self.checkboxControl.topAnchor.constraint(equalTo: self.textLabel.bottomAnchor, constant: 30),
            self.checkboxControl.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.checkboxControl.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),
            
            self.actionButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.actionButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30)
            ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        self.navigationItem.backBarButtonItem = backItem
    }
    
    func checked(_ checkboxControl: CheckboxControl) {
        checkboxControl.checkbox.checked = !checkboxControl.checkbox.checked
        self.actionButton.isEnabled = checkboxControl.checkbox.checked
    }
    
    func proceed(_ actionButton: ActionButton) {
        let controller = BackupPhraseCopyController(idAPIClient: self.idAPIClient)
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
