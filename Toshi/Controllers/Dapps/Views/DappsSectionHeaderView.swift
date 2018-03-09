// Copyright (c) 2018 Token Browser, Inc
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

import UIKit

protocol DappsSectionHeaderViewDelegate: class {
    func dappsSectionHeaderViewDidReceiveActionButtonEvent(_ sectionHeaderView: DappsSectionHeaderView)
}

final class DappsSectionHeaderView: UIView {

    private weak var delegate: DappsSectionHeaderViewDelegate?

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.greyTextColor
        label.font = Theme.proTextBold(size: 13)
        label.set(height: 20)

        return label
    }()

    private(set) lazy var actionButton: UIButton = {
        let button = UIButton()
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setTitleColor(Theme.tintColor, for: .normal)
        button.titleLabel?.font = Theme.proTextBold(size: 13)
        button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)

        return button
    }()

    @objc private func actionButtonTapped(_ button: UIButton) {
        delegate?.dappsSectionHeaderViewDidReceiveActionButtonEvent(self)
    }

    deinit {
        print("Header deinitialised")
    }

    // MARK: - Initialization

    /// Designated initializer
    ///
    /// - Parameters:
    ///   - delegate: The delegate to notify of changes.
    init(delegate: DappsSectionHeaderViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)

        backgroundColor = Theme.viewBackgroundColor

        setupMainStackView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup

    private func setupMainStackView() {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        addSubview(stackView)

        stackView.leftToSuperview(offset: .defaultMargin)
        stackView.rightToSuperview(offset: .defaultMargin)
        stackView.topToSuperview(offset: .smallInterItemSpacing)
        stackView.bottomToSuperview()

        stackView.addArrangedSubview(titleLabel)
        stackView.addSpacing(.mediumInterItemSpacing, after: titleLabel)
        stackView.addWithDefaultConstraints(view: actionButton)
    }
}
