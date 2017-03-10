import SweetUIKit

class SecurityCell: BaseCell {
    
    lazy var checkbox: Checkbox = {
        let view = Checkbox(withAutoLayout: true)
        view.checked = false
        
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.darkTextColor
        view.font = Theme.semibold(size: 15)
        view.numberOfLines = 0
        view.text = ""
        
        return view
    }()
    
    var title: String? {
        didSet {
            self.titleLabel.text = title
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let margin = CGVector(dx: 46, dy: 16)
        
        self.contentView.addSubview(self.checkbox)
        self.contentView.addSubview(self.titleLabel)
        
        NSLayoutConstraint.activate([
            self.checkbox.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: (margin.dx / 2) - (Checkbox.size / 2)),
            self.checkbox.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
            ])
        
        self.titleLabel.text = "Store backup phrase"
        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin.dy),
            self.titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin.dx),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin.dy),
            self.titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -40)
            ])
    }
}
