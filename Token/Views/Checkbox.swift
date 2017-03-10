import SweetUIKit

class Checkbox: UIView {
    
    static let size: CGFloat = 20
    
    private lazy var unCheckedView: UIView = {
        let view = UIView(withAutoLayout: true)
        
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: Checkbox.size, height: Checkbox.size)).cgPath
        layer.strokeColor = Theme.borderColor.cgColor
        layer.lineWidth = 1
        view.layer.addSublayer(layer)
        
        return view
    }()
    
    private lazy var checkedView: UIView = {
        let view = UIView(withAutoLayout: true)
        
        let layer = CAShapeLayer()
        layer.fillColor = Theme.tintColor.cgColor
        layer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: Checkbox.size, height: Checkbox.size)).cgPath
        layer.strokeColor = Theme.tintColor.cgColor
        layer.lineWidth = 1
        view.layer.addSublayer(layer)
        
        let imageView = UIImageView(withAutoLayout: true)
        imageView.contentMode = .center
        imageView.image = UIImage(named: "checkmark")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Theme.viewBackgroundColor
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
        
        return view
    }()
    
    var checked: Bool = false {
        didSet {
            unCheckedView.isHidden = checked
            checkedView.isHidden = !checked
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.unCheckedView)
        self.addSubview(self.checkedView)
        
        NSLayoutConstraint.activate([
            self.unCheckedView.topAnchor.constraint(equalTo: self.topAnchor),
            self.unCheckedView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.unCheckedView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.unCheckedView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.unCheckedView.widthAnchor.constraint(equalToConstant: Checkbox.size),
            self.unCheckedView.heightAnchor.constraint(equalToConstant: Checkbox.size)
            ])
        
        NSLayoutConstraint.activate([
            self.checkedView.topAnchor.constraint(equalTo: self.topAnchor),
            self.checkedView.leftAnchor.constraint(equalTo: self.leftAnchor),
            self.checkedView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.checkedView.rightAnchor.constraint(equalTo: self.rightAnchor),
            self.checkedView.widthAnchor.constraint(equalToConstant: Checkbox.size),
            self.checkedView.heightAnchor.constraint(equalToConstant: Checkbox.size)
            ])
    }
}
