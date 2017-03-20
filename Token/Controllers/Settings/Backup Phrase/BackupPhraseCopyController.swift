import UIKit
import SweetUIKit

class BackupPhraseCopyController: UIViewController {
    
    let idAPIClient: IDAPIClient
    
    lazy var titleLabel: TitleLabel = {
        let view = TitleLabel("This is your backup phrase")
        
        return view
    }()
    
    lazy var textLabel: UILabel = {
        let view = TextLabel("Carefully write down the words.\nDon’t email it or screenshot it..")
        view.textAlignment = .center
        
        return view
    }()
    
    private lazy var actionButton: ActionButton = {
        let view = ActionButton(withAutoLayout: true)
        view.title = "Verify phrase"
        view.isEnabled = true
        view.addTarget(self, action: #selector(proceed(_:)), for: .touchUpInside)
        
        return view
    }()
    
    private lazy var phraseView: BackupPhraseView = {
        let view = BackupPhraseView(with: Cereal().mnemonic.words, for: .original)
        
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
        self.view.addSubview(self.phraseView)
        self.view.addSubview(self.actionButton)
        
        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40 + 64),
            self.titleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.titleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),
            
            self.textLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 20),
            self.textLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 30),
            self.textLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -30),
            
            self.phraseView.topAnchor.constraint(equalTo: self.textLabel.bottomAnchor, constant: 60),
            self.phraseView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 15),
            self.phraseView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -15),
            
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
    
    func proceed(_ actionButton: ActionButton) {
        let controller = BackupPhraseVerifyController(idAPIClient: self.idAPIClient)
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
