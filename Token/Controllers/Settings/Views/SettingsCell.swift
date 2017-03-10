import SweetUIKit

class SettingsCell: BaseCell {
    
    lazy var titleLabel: UILabel = {
        let view = UILabel(withAutoLayout: true)
        view.textColor = Theme.darkTextColor
        view.font = Theme.semibold(size: 15)
        view.numberOfLines = 0
        
        return view
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let margin: CGFloat = 16
        
        self.contentView.addSubview(self.titleLabel)
        
        self.titleLabel.text = "Local currency"
        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: margin),
            self.titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: margin),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -margin),
            self.titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -40)
            ])
    }
}
