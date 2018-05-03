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

protocol PushedSearchHeaderDelegate: class {
    func searchHeaderWillBeginEditing(_ headerView: PushedSearchHeaderView)
    func searchHeaderWillEndEditing(_ headerView: PushedSearchHeaderView)
    func searchHeaderDidReceiveRightButtonEvent(_ headerView: PushedSearchHeaderView)
    func searchHeaderViewDidReceiveBackEvent(_ headerView: PushedSearchHeaderView)
    func searchHeaderViewDidUpdateSearchText(_ headerView: PushedSearchHeaderView, _ searchText: String)
}

final class PushedSearchHeaderView: UIView {
    static let headerHeight: CGFloat = 56

    weak var delegate: PushedSearchHeaderDelegate?

    var rightButtonTitle: String = Localized.cancel_action_title {
        didSet {
            rightButton.setTitle(rightButtonTitle, for: .normal)
        }
    }

    var hidesBackButtonOnSearch: Bool = true

    private let searchTextFieldBackgroundViewHeight: CGFloat = 36

    var searchPlaceholder: String? {
        didSet {
            searchTextField.placeholder = searchPlaceholder
        }
    }

    func setButtonEnabled(_ enabled: Bool) {
        rightButton.isEnabled = enabled
    }

    private lazy var backButton: UIButton = {
        let view = UIButton()
        view.setTitleColor(Theme.tintColor, for: .normal)
        view.size(CGSize(width: .defaultButtonHeight, height: .defaultButtonHeight))
        view.setImage(ImageAsset.web_back.withRenderingMode(.alwaysTemplate), for: .normal)
        view.tintColor = Theme.tintColor
        view.addTarget(self, action: #selector(self.didTapBackButton), for: .touchUpInside)
        view.contentHorizontalAlignment = .left

        return view
    }()

    private(set) lazy var searchTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.delegate = self
        textField.layer.cornerRadius = 5
        textField.tintColor = Theme.tintColor
        textField.returnKeyType = .go

        textField.leftView = magnifyingGlassImageView
        textField.leftViewMode = .always

        return textField
    }()

    private lazy var magnifyingGlassImageView: UIImageView = {
        let magnifyingGlassImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: searchTextFieldBackgroundViewHeight, height: searchTextFieldBackgroundViewHeight))
        magnifyingGlassImageView.image = ImageAsset.search_users
        magnifyingGlassImageView.contentMode = .center

        return magnifyingGlassImageView
    }()

    private lazy var searchTextFieldBackgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = Theme.searchBarColor
        backgroundView.layer.cornerRadius = 5

        return backgroundView
    }()

    private lazy var rightButton: UIButton = {
        let rightButton = UIButton()
        rightButton.setTitleColor(Theme.tintColor, for: .normal)
        rightButton.setTitleColor(Theme.greyTextColor, for: .disabled)
        rightButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        rightButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightButton.setContentHuggingPriority(.required, for: .horizontal)

        return rightButton
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally

        return stackView
    }()

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = Theme.viewBackgroundColor
        addSubviewsAndConstraints()
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return searchTextField.becomeFirstResponder()
    }

    private func addSubviewsAndConstraints() {
        addSubview(stackView)
        stackView.left(to: self)
        stackView.right(to: self)
        stackView.bottom(to: self)
        stackView.height(PushedSearchHeaderView.headerHeight)
        stackView.alignment = .center

        stackView.addSpacerView(with: .defaultMargin)
        stackView.addArrangedSubview(backButton)
        stackView.addArrangedSubview(searchTextFieldBackgroundView)
        searchTextFieldBackgroundView.height(searchTextFieldBackgroundViewHeight)
        searchTextFieldBackgroundView.addSubview(searchTextField)
        searchTextField.leftToSuperview()
        searchTextField.topToSuperview()
        searchTextField.bottomToSuperview()
        searchTextField.right(to: searchTextFieldBackgroundView, offset: -.smallInterItemSpacing)

        stackView.addSpacing(.smallInterItemSpacing, after: searchTextFieldBackgroundView)

        stackView.addArrangedSubview(rightButton)
        stackView.addSpacerView(with: .defaultMargin)

        let separator = BorderView()
        addSubview(separator)
        separator.leftToSuperview()
        separator.rightToSuperview()
        separator.bottomToSuperview()
        separator.addHeightConstraint()

        rightButton.isHidden = true
    }

    private func adjustToSearching(isSearching: Bool) {
        layoutIfNeeded()
        rightButton.isHidden = !isSearching

        guard hidesBackButtonOnSearch else { return }

        backButton.isHidden = isSearching
        UIView.animate(withDuration: 0.3) {
            self.backButton.alpha = isSearching ? 0 : 1
            self.layoutIfNeeded()
        }
    }

    @objc private func didTapCancelButton() {
        searchTextField.resignFirstResponder()
        searchTextField.text = nil
        delegate?.searchHeaderDidReceiveRightButtonEvent(self)
    }

    @objc private func didTapBackButton() {
        delegate?.searchHeaderViewDidReceiveBackEvent(self)
    }
}

extension PushedSearchHeaderView: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        adjustToSearching(isSearching: true)
        delegate?.searchHeaderWillBeginEditing(self)

        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        adjustToSearching(isSearching: false)
        delegate?.searchHeaderWillEndEditing(self)

        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text,
            let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange,
                                                       with: string)

            delegate?.searchHeaderViewDidUpdateSearchText(self, updatedText)
        }

        return true
    }
}
