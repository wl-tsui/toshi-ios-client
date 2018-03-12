//
//  SendConfirmationSection.swift
//  Toshi
//
//  Created by Ellen Shapiro (Work) on 2/15/18.
//  Copyright © 2018 Bakken&Baeck. All rights reserved.
//

import UIKit

final class SendConfirmationSection: UIStackView {

    private lazy var sectionTitleLabel: UILabel = {

        let label = UILabel()
        label.textAlignment = .left
        label.textColor = Theme.darkTextHalfAlpha
        label.font = Theme.preferredRegular()

        return label
    }()

    private lazy var primaryCurrencyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = Theme.darkTextColor

        return label
    }()

    private lazy var secondaryCurrencyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = Theme.darkTextHalfAlpha
        label.font = Theme.preferredFootnote()

        return label
    }()

    // MARK: Initialization

    /// A section in the confirmation screen which can optionally show a secondary currency.
    ///
    /// - Parameters:
    ///   - sectionTitle: The title of the section to display
    ///   - primaryCurrencyString: The string to display for the primary currency
    ///   - secondaryCurrencyString: [optional] The string to show for the secondary currency. The secondary currency label will not be added if this value is nil.
    ///   - primaryCurrencyBold: Whether the primary currency label should be bold or not. Defaults to false.
    init(sectionTitle: String,
         primaryCurrencyBold: Bool = false) {

        super.init(frame: .zero)

        self.axis = .horizontal
        self.alignment = .top
        self.spacing = .smallInterItemSpacing

        setPrimaryCurrencyFont(bold: primaryCurrencyBold)

        sectionTitleLabel.text = sectionTitle

        addArrangedSubview(sectionTitleLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupWith(primaryCurrencyString: String, secondaryCurrencyString: String?) {
        primaryCurrencyLabel.text = primaryCurrencyString

        if let secondaryString = secondaryCurrencyString {
            secondaryCurrencyLabel.text = secondaryString
            addCurrencyStackView(to: self)
        } else {
            addArrangedSubview(primaryCurrencyLabel)
        }
    }

    // MARK: View Setup

    private func setPrimaryCurrencyFont(bold: Bool) {
        if bold {
            primaryCurrencyLabel.font = Theme.preferredRegularBold()
        } else {
            primaryCurrencyLabel.font = Theme.preferredRegular()
        }
    }

    private func addCurrencyStackView(to stackView: UIStackView) {
        let currencyStackView = UIStackView()

        currencyStackView.axis = .vertical
        currencyStackView.alignment = .trailing
        currencyStackView.spacing = .smallInterItemSpacing

        stackView.addArrangedSubview(currencyStackView)

        currencyStackView.addArrangedSubview(primaryCurrencyLabel)
        currencyStackView.addArrangedSubview(secondaryCurrencyLabel)
    }
}
