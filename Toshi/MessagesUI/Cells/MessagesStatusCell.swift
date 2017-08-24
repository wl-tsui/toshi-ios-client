import Foundation
import UIKit
import TinyConstraints

class MessagesStatusCell: MessagesBasicCell {

    static let reuseIdentifier = "MessagesStatusCell"
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
