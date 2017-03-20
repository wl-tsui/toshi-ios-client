import UIKit

protocol ControlCellDelegate {
    func didTapButton(for cell: ControlCell)
}

class SubcontrolCell: ControlCell {

    override var buttonInsets: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 64)
        }
    }

    lazy var separatorView: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.borderColor

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.separatorView)

        self.separatorView.set(height: 1)
        self.separatorView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 12).isActive = true
        self.separatorView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: 12).isActive = true
        self.separatorView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true

        self.contentView.layer.cornerRadius = 0.0
        self.contentView.layer.borderColor = nil
        self.contentView.layer.borderWidth = 0.0

        self.button.setTitleColor(Theme.darkTextColor, for: .normal)
        self.button.setTitleColor(Theme.actionButtonTitleColor, for: .highlighted)
        self.button.titleLabel?.font = Theme.regular(size: 15)
        self.button.contentHorizontalAlignment = .left

        self.button.fillSuperview(with: self.buttonInsets)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

class ControlCell: UICollectionViewCell {
    var delegate: ControlCellDelegate?

    var buttonInsets: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        }
    }

    var buttonItem: SofaMessage.Button? {
        didSet {
            let title = self.buttonItem?.label
            self.button.setTitle(title, for: .normal)
            self.button.titleLabel?.lineBreakMode = .byTruncatingTail
        }
    }

    lazy var button: UIButton = {
        let view = UIButton(withAutoLayout: true)
        view.setTitleColor(Theme.actionButtonTitleColor, for: .normal)
        view.titleLabel?.font = Theme.medium(size: 15)
        view.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)

        view.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)

        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.backgroundColor = Theme.incomingMessageBackgroundColor
        self.contentView.layer.cornerRadius = 8.0
        self.contentView.layer.borderColor = Theme.borderColor.cgColor
        self.contentView.layer.borderWidth = Theme.borderHeight

        self.contentView.addSubview(self.button)

        self.button.fillSuperview(with: self.buttonInsets)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func didTapButton() {
        self.delegate?.didTapButton(for: self)
    }
}
