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

import TinyConstraints
import UIKit

// The cell to display a user's name when adding a user to a list of selected users.
class UserNameCell: UICollectionViewCell {
    
    private let margin: CGFloat = 2
    private lazy var cornerRadius = (margin * 2)
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.tintColor = Theme.tintColor
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                backgroundColor = Theme.tintColor
                nameLabel.textColor = Theme.inputFieldBackgroundColor
            } else {
                nameLabel.textColor = Theme.tintColor
                backgroundColor = Theme.inputFieldBackgroundColor
            }
        }
    }
    
    var name: String? {
        get {
            return nameLabel.text
        }
        set {
            nameLabel.text = newValue
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
        setupNameLabel()
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Subview Setup
    
    private func setupNameLabel() {
        contentView.addSubview(nameLabel)
        
        nameLabel.edgesToSuperview(insets: UIEdgeInsets(top: margin,
                                                        left: margin,
                                                        bottom: margin,
                                                        right: -margin))
    }
    
    // MARK: - Public API

    func labelSize() -> CGSize {
        guard let name = name else { return .zero }
        
        let sizeConstraint = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let frame = (name as NSString).boundingRect(with: sizeConstraint,
                                                    options: [.usesLineFragmentOrigin],
                                                    attributes: [
                                                        .font: nameLabel.font!
                                                    ],
                                                    context: nil)
        return CGSize(width: ceil(frame.width) + (margin * 2),
                      height: ceil(frame.height) + (margin * 2))
    }
}
