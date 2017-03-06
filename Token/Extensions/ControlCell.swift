import UIKit

protocol ControlCellDelegate {
    func didTapButton(for cell: ControlCell)
}

class ControlCell: UICollectionViewCell {
    var delegate: ControlCellDelegate?

    var buttonItem: SofaMessage.Button? {
        didSet {
            let title = self.buttonItem?.label
            self.button.setTitle(title, for: .normal)
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
        self.contentView.layer.borderWidth = 1.0

        self.contentView.addSubview(self.button)

        let insets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        self.button.fillSuperview(with: insets)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    func didTapButton() {
        guard let type = self.buttonItem?.type else { return }

        switch type {
        case .button:
            self.delegate?.didTapButton(for: self)
        case .group:
            // show options UI
            print("Show options")
        }
    }
}

