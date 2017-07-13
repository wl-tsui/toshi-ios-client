// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

protocol PaymentMessageCellDelegate: class {
    func didTapApprovePaymentCell(_ cell: PaymentMessageCell)
    func didTapRejectPaymentCell(_ cell: PaymentMessageCell)
}

final class PaymentMessageCell: UITableViewCell {

    var delegate: PaymentMessageCellDelegate?

    var isOutgoing = false {
        didSet {
            self.avatarImageView.isHidden = isOutgoing

            self.contentRightSpace.isActive = isOutgoing
            self.contentLeftSpace.isActive = !isOutgoing
        }
    }

    fileprivate lazy var contentLeftSpace: NSLayoutConstraint = {
        return self.container.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 57.0)
    }()

    fileprivate lazy var contentRightSpace: NSLayoutConstraint = {
        return self.errorImageView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16.0)
    }()

    fileprivate lazy var statusBottomConstraint: NSLayoutConstraint = {
        return self.statusLabel.bottomAnchor.constraint(equalTo: self.container.bottomAnchor, constant: -16.0)
    }()

    fileprivate lazy var declineBottomConstraint: NSLayoutConstraint = {
        let declineButton = self.buttons[1]

        return declineButton.bottomAnchor.constraint(equalTo: self.container.bottomAnchor)
    }()

    private(set) lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView(withAutoLayout: true)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 17.0
        imageView.layer.masksToBounds = true

        return imageView
    }()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.tintColor
        label.numberOfLines = 0
        label.font = Theme.regular(size: 18.0)

        return label
    }()

    private(set) lazy var subTitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.mediumTextColor
        label.numberOfLines = 0
        label.font = Theme.regular(size: 13.0)

        return label
    }()

    private(set) lazy var detailsLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.darkTextColor
        label.numberOfLines = 0
        label.font = Theme.regular(size: 14.0)

        return label
    }()

    private(set) lazy var statusLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.textColor = Theme.mediumTextColor
        label.font = Theme.regular(size: 14.0)

        return label
    }()

    private(set) lazy var buttons: [MessageCellButton] = {
        return [MessageCellButton(), MessageCellButton()]
    }()

    fileprivate lazy var container: UIView = {
        let view = UIView(withAutoLayout: true)
        view.backgroundColor = Theme.viewBackgroundColor

        return view
    }()

    fileprivate lazy var errorImageView: UIImageView = {
        let imageView = UIImageView(withAutoLayout: true)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "error")

        return imageView
    }()

    fileprivate lazy var errorMessageLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.font = Theme.regular(size: 13.0)
        label.textColor = Theme.errorColor
        label.textAlignment = .right
        label.text = Localized("Not delivered.")

        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.addSubviewsAndConstrains()
        self.setupButtons()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = nil
        self.subTitleLabel.text = nil
        self.detailsLabel.text = nil
        self.statusLabel.text = nil

        self.statusBottomConstraint.isActive = false
        self.declineBottomConstraint.isActive = true

        self.contentLeftSpace.isActive = false
        self.contentRightSpace.isActive = true

        self.errorImageView.set(width: 0.0)
        self.errorMessageLabel.heightAnchor.constraint(equalToConstant: 0.0).isActive = true
    }

    fileprivate func addSubviewsAndConstrains() {
        self.contentView.backgroundColor = Theme.messageViewBackgroundColor

        self.contentView.addSubview(self.avatarImageView)
        self.avatarImageView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16.0).isActive = true
        self.avatarImageView.set(height: 34.0)
        self.avatarImageView.set(width: 34.0)
        self.avatarImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10.0).isActive = true

        self.contentView.addSubview(self.errorImageView)
        self.errorImageView.set(height: 24.0)
        self.errorImageView.set(width: 0.0)

        self.contentView.addSubview(self.errorMessageLabel)
        self.errorMessageLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -16.0).isActive = true
        self.errorMessageLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        self.errorMessageLabel.heightAnchor.constraint(equalToConstant: 0.0).isActive = true

        self.container.prepareForSuperview()
        self.contentView.addSubview(self.container)
        self.container.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10.0).isActive = true
        self.container.bottomAnchor.constraint(equalTo: self.errorMessageLabel.topAnchor, constant: -10.0).isActive = true
        self.container.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.6).isActive = true
        self.container.rightAnchor.constraint(equalTo: self.errorImageView.leftAnchor).isActive = true

        self.contentLeftSpace.isActive = false
        self.contentRightSpace.isActive = true

        self.errorImageView.centerY(to: self.container).isActive = true

        self.container.layer.cornerRadius = 16.0
        self.container.layer.borderWidth = 1.0
        self.container.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor

        self.titleLabel.prepareForSuperview()
        self.container.addSubview(self.titleLabel)
        self.titleLabel.topAnchor.constraint(equalTo: self.container.topAnchor, constant: 10.0).isActive = true
        self.titleLabel.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 16.0).isActive = true
        self.titleLabel.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -16.0).isActive = true

        self.subTitleLabel.prepareForSuperview()
        self.container.addSubview(self.subTitleLabel)
        self.subTitleLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 16.0).isActive = true
        self.subTitleLabel.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 16.0).isActive = true
        self.subTitleLabel.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -16.0).isActive = true

        self.detailsLabel.prepareForSuperview()
        self.container.addSubview(self.detailsLabel)
        self.detailsLabel.topAnchor.constraint(equalTo: self.subTitleLabel.bottomAnchor, constant: 16.0).isActive = true
        self.detailsLabel.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 16.0).isActive = true
        self.detailsLabel.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -16.0).isActive = true

        self.statusLabel.prepareForSuperview()
        self.container.addSubview(self.statusLabel)
        self.statusLabel.topAnchor.constraint(equalTo: self.detailsLabel.bottomAnchor, constant: 16.0).isActive = true
        self.statusLabel.leftAnchor.constraint(equalTo: self.container.leftAnchor, constant: 16.0).isActive = true
        self.statusLabel.rightAnchor.constraint(equalTo: self.container.rightAnchor, constant: -16.0).isActive = true

        let approveButton = self.buttons[0]
        approveButton.prepareForSuperview()
        self.container.addSubview(approveButton)
        approveButton.topAnchor.constraint(equalTo: self.detailsLabel.bottomAnchor, constant: 16.0).isActive = true
        approveButton.leftAnchor.constraint(equalTo: self.container.leftAnchor).isActive = true
        approveButton.rightAnchor.constraint(equalTo: self.container.rightAnchor).isActive = true

        let declineButton = self.buttons[1]
        declineButton.prepareForSuperview()
        self.container.addSubview(declineButton)
        declineButton.topAnchor.constraint(equalTo: approveButton.bottomAnchor).isActive = true
        declineButton.leftAnchor.constraint(equalTo: self.container.leftAnchor).isActive = true
        declineButton.rightAnchor.constraint(equalTo: self.container.rightAnchor).isActive = true
        declineButton.bottomAnchor.constraint(equalTo: self.container.bottomAnchor).isActive = true

        self.layoutIfNeeded()
    }

    @objc fileprivate func didTapApproveButton() {
        self.delegate?.didTapApprovePaymentCell(self)
    }

    @objc fileprivate func didTapRejectButton() {
        self.delegate?.didTapRejectPaymentCell(self)
    }

    fileprivate func setupButtons() {
        self.buttons[0].addTarget(self, action: #selector(didTapApproveButton), for: .touchUpInside)
        self.buttons[1].addTarget(self, action: #selector(didTapRejectButton), for: .touchUpInside)
    }

    fileprivate func setup(with buttonModels: [MessageButtonModel]?) {
        if let models = buttonModels {
            self.buttons[0].model = models[0]
            self.buttons[1].model = models[1]
        } else {
            self.buttons[0].model = nil
            self.buttons[1].model = nil

            self.statusBottomConstraint.isActive = true
        }
    }

    func setup(with message: MessageModel) {
        guard let paymentState = message.signalMessage?.paymentState as TSInteraction.PaymentState? else { return }

        self.statusLabel.text = paymentState.stateText

        switch paymentState {
        case .failed:
            self.errorMessageLabel.heightAnchor.constraint(equalToConstant: 15.0).isActive = true
            self.errorImageView.set(width: 24.0)

            self.setup(with: nil)
        case .pendingConfirmation, .rejected, .approved:
            self.errorMessageLabel.heightAnchor.constraint(equalToConstant: 0.0).isActive = true
            self.errorImageView.set(width: 0.0)
            
            self.setup(with: nil)
        default:
            self.setup(with: message.buttonModels)
        }
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}

