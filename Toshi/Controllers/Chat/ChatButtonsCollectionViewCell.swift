import Foundation
import UIKit
import TinyConstraints

final class ChatButtonsViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "ChatButtonsViewCell"
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var shouldShowArrow: Bool = false {
        didSet {
            arrowImageView.isHidden = !shouldShowArrow
            
            if shouldShowArrow {
                titleToContentConstraint?.isActive = false
                titleToArrowConstraint?.isActive = true
            } else {
                titleToArrowConstraint?.isActive = false
                titleToContentConstraint?.isActive = true
            }
        }
    }
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.regular(size: 17)
        view.textColor = Theme.tintColor
        
        return view
    }()
    
    private lazy var arrowImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "chat-buttons-arrow")?.withRenderingMode(.alwaysTemplate)
        view.tintColor = Theme.tintColor
        
        return view
    }()
    
    private var titleToContentConstraint: NSLayoutConstraint?
    private var titleToArrowConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.borderColor = Theme.tintColor.cgColor
        contentView.layer.borderWidth = 1
        contentView.layer.cornerRadius = 18
        contentView.clipsToBounds = true
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(arrowImageView)
        
        titleLabel.top(to: contentView, offset: 8)
        titleLabel.left(to: contentView, offset: 15)
        titleLabel.bottom(to: contentView, offset: -8)
        
        titleToContentConstraint = titleLabel.right(to: contentView, offset: -15)
        titleToArrowConstraint = titleLabel.rightToLeft(of: arrowImageView, offset: -5, isActive: false)
        
        arrowImageView.centerY(to: contentView)
        arrowImageView.right(to: contentView, offset: -15)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        title = nil
        shouldShowArrow = false
    }
}
