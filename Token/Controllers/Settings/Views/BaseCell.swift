import SweetUIKit

enum BaseCellPosition {
    case single
    case first
    case middle
    case last
}

class BaseCell: UITableViewCell {
    
    var position: BaseCellPosition = .first {
        didSet {
            switch position {
            case .single:
                self.topSeparatorView.isHidden = false
                self.shortBottomSeparatorView.isHidden = true
                self.bottomSeparatorView.isHidden = false
            case .first:
                self.topSeparatorView.isHidden = false
                self.shortBottomSeparatorView.isHidden = false
                self.bottomSeparatorView.isHidden = true
            case .middle:
                self.topSeparatorView.isHidden = true
                self.shortBottomSeparatorView.isHidden = false
                self.bottomSeparatorView.isHidden = true
            case .last:
                self.topSeparatorView.isHidden = true
                self.shortBottomSeparatorView.isHidden = true
                self.bottomSeparatorView.isHidden = false
            }
        }
    }
    
    lazy var topSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor
        
        return view
    }()
    
    lazy var shortBottomSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor
        
        return view
    }()
    
    lazy var bottomSeparatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor
        
        return view
    }()
    
    lazy var disclosureIndicator: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = UIImage(named: "disclosure_indicator")
        
        return view
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.topSeparatorView)
        self.contentView.addSubview(self.shortBottomSeparatorView)
        self.contentView.addSubview(self.bottomSeparatorView)
        self.contentView.addSubview(self.disclosureIndicator)
        
        self.topSeparatorView.set(height: 1 / UIScreen.main.scale)
        NSLayoutConstraint.activate([
            self.topSeparatorView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.topSeparatorView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.topSeparatorView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor)
            ])
        
        self.shortBottomSeparatorView.set(height: 1 / UIScreen.main.scale)
        NSLayoutConstraint.activate([
            self.shortBottomSeparatorView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16),
            self.shortBottomSeparatorView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.shortBottomSeparatorView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor)
            ])
        
        self.bottomSeparatorView.set(height: 1 / UIScreen.main.scale)
        NSLayoutConstraint.activate([
            self.bottomSeparatorView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor),
            self.bottomSeparatorView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            self.bottomSeparatorView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor)
            ])
        
        NSLayoutConstraint.activate([
            self.disclosureIndicator.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            self.disclosureIndicator.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -18)
            ])
    }
    
    func setIndex(_ index: Int, from total: Int) {
        
        if total == 1 {
            self.position = .single
        } else if index == 0 {
            self.position = .first
        } else if index == total - 1 {
            self.position = .last
        } else {
            self.position = .middle
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
