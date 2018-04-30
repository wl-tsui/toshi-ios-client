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

final class CollectibleCell: BasicTableViewCell {

    override func prepareForReuse() {
        super.prepareForReuse()

        leftImageView.image = nil
        titleTextField.text = nil
        subtitleLabel.text = nil
    }

    override func addSubviewsAndConstraints() {
        contentView.addSubview(leftImageView)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(titleTextField)

        setupLeftImageView()
        setupTitleTextField()
        setupSubtitleLabel()
    }

    private func setupLeftImageView() {
        leftImageView.layer.cornerRadius = 0
        leftImageView.size(CGSize(width: BasicTableViewCell.largeImageSize, height: BasicTableViewCell.largeImageSize))
        leftImageView.centerY(to: contentView)
        leftImageView.left(to: contentView, offset: BasicTableViewCell.horizontalMargin)
        leftImageView.top(to: contentView, offset: BasicTableViewCell.imageMargin, relation: .equalOrGreater, priority: .defaultLow)
        leftImageView.bottom(to: contentView, offset: -BasicTableViewCell.imageMargin, relation: .equalOrGreater, priority: .defaultLow)
    }

    private func setupSubtitleLabel() {
        subtitleLabel.height(18, relation: .equalOrGreater)
        subtitleLabel.topToBottom(of: titleTextField)
        subtitleLabel.leftToRight(of: leftImageView, offset: BasicTableViewCell.largeInterItemMargin)
        subtitleLabel.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin)
        subtitleLabel.bottom(to: contentView, offset: -.hugeInterItemSpacing)
    }

    private func setupTitleTextField() {
        titleTextField.top(to: contentView, offset: .hugeInterItemSpacing)
        titleTextField.leftToRight(of: leftImageView, offset: BasicTableViewCell.largeInterItemMargin)
        titleTextField.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin)
    }
}
