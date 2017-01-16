import UIKit
import SweetUIKit

class MessagesEthereumView: UIView {
    lazy var balanceLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)

        return label
    }()

    lazy var requestButton: UIButton = {
        let button = UIButton()

        return button
    }()

    lazy var payButton: UIButton = {
        let button = UIButton(withAutoLayout: true)

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.balanceLabel)
        self.addSubview(self.requestButton)
        self.addSubview(self.payButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
