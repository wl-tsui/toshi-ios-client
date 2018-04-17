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

final class AvatarTitleSubtitleDescriptionCell: BasicTableViewCell {

    override func prepareForReuse() {
        super.prepareForReuse()

        leftImageView.image = nil
        titleTextField.text = nil
        subtitleLabel.text = nil
        descriptionLabel.text = nil
    }

    override func addSubviewsAndConstraints() {
        contentView.addSubview(leftImageView)
        contentView.addSubview(titleTextField)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(descriptionLabel)

        setupLeftImageView()
        setupTitleTextField()
        setupSubtitleLabel()
        setupDescriptionLabel()
    }

    private func setupLeftImageView() {
        leftImageView.size(CGSize(width: BasicTableViewCell.imageSize, height: BasicTableViewCell.imageSize))
        leftImageView.centerY(to: contentView)
        leftImageView.left(to: contentView, offset: BasicTableViewCell.horizontalMargin)
        leftImageView.top(to: contentView, offset: BasicTableViewCell.imageMargin, relation: .equalOrGreater, priority: .defaultLow)
        leftImageView.bottom(to: contentView, offset: -BasicTableViewCell.imageMargin, relation: .equalOrGreater, priority: .defaultLow)
    }

    private func setupTitleTextField() {
        titleTextField.setDynamicFontBlock = {
            self.titleTextField.font = Theme.preferredSemibold()
        }

        titleTextField.top(to: contentView, offset: BasicTableViewCell.horizontalMargin)
        titleTextField.leftToRight(of: leftImageView, offset: BasicTableViewCell.interItemMargin)
        titleTextField.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin)
        titleTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func setupSubtitleLabel() {
        subtitleLabel.topToBottom(of: titleTextField, offset: .smallInterItemSpacing)
        subtitleLabel.leftToRight(of: leftImageView, offset: BasicTableViewCell.interItemMargin)
        subtitleLabel.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func setupDescriptionLabel() {
        descriptionLabel.topToBottom(of: subtitleLabel, offset: .smallInterItemSpacing)
        descriptionLabel.leftToRight(of: leftImageView, offset: BasicTableViewCell.interItemMargin)
        descriptionLabel.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin)
        descriptionLabel.bottom(to: contentView, offset: -BasicTableViewCell.verticalMargin)
        descriptionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
}
