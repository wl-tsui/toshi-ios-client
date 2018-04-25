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

final class AvatarTitleDescriptionCell: BasicTableViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()

        leftImageView.image = nil
        descriptionLabel.text = nil
        subtitleLabel.text = nil
    }

    override func addSubviewsAndConstraints() {
        contentView.addSubview(leftImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(titleTextField)

        setupLeftImageView()
        setupTitleTextField()
        setupDescriptionLabel()
    }

    private func setupLeftImageView() {
        leftImageView.size(CGSize(width: BasicTableViewCell.largeImageSize, height: BasicTableViewCell.largeImageSize))
        leftImageView.centerY(to: contentView)
        leftImageView.left(to: contentView, offset: BasicTableViewCell.horizontalMargin)
        leftImageView.top(to: contentView, offset: BasicTableViewCell.imageMargin, relation: .equalOrGreater, priority: .defaultLow)
        leftImageView.bottom(to: contentView, offset: -BasicTableViewCell.imageMargin, relation: .equalOrGreater, priority: .defaultLow)

        leftImageView.layer.cornerRadius = 0
    }

    private func setupTitleTextField() {
        titleTextField.setDynamicFontBlock = {
            self.titleTextField.font = Theme.preferredSemibold()
        }

        titleTextField.top(to: contentView, offset: BasicTableViewCell.verticalMargin)
        titleTextField.leftToRight(of: leftImageView, offset: BasicTableViewCell.interItemMargin)
        titleTextField.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin)
    }

    private func setupDescriptionLabel() {
        descriptionLabel.height(32, relation: .equalOrGreater)
        descriptionLabel.topToBottom(of: titleTextField, offset: BasicTableViewCell.smallVerticalMargin)
        descriptionLabel.leftToRight(of: leftImageView, offset: BasicTableViewCell.interItemMargin)
        descriptionLabel.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin)
        descriptionLabel.bottom(to: contentView, offset: -BasicTableViewCell.verticalMargin)
    }
}
