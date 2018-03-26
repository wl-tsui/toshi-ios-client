import Foundation
import UIKit

enum MessagesCornerType {
    case cornerMiddleOutgoing
    case cornerMiddleOutlineOutgoing
    case cornerMiddleOutline
    case cornerMiddle
    case cornerTopOutgoing
    case cornerTopOutlineOutgoing
    case cornerTopOutline
    case cornerTop
}

class MessagesCornerView: UIImageView {

    private lazy var cornerMiddleOutgoingImage = ImageAsset.corner_middle_outgoing.messageStretchable
    private lazy var cornerMiddleOutlineOutgoingImage = ImageAsset.corner_middle_outline_outgoing.messageStretchable
    private lazy var cornerMiddleOutlineImage = ImageAsset.corner_middle_outline.messageStretchable
    private lazy var cornerMiddleImage = ImageAsset.corner_middle.messageStretchable
    private lazy var cornerTopOutgoingImage = ImageAsset.corner_top_outgoing.messageStretchable
    private lazy var cornerTopOutlineOutgoingImage = ImageAsset.corner_top_outline_outgoing.messageStretchable
    private lazy var cornerTopOutlineImage = ImageAsset.corner_top_outline.messageStretchable
    private lazy var cornerTopImage = ImageAsset.corner_top.messageStretchable

    var type: MessagesCornerType? {
        didSet {
            guard let type = type else {
                image = nil
                return
            }

            switch type {
            case .cornerMiddleOutgoing:
                image = cornerMiddleOutgoingImage
            case .cornerMiddleOutlineOutgoing:
                image = cornerMiddleOutlineOutgoingImage
            case .cornerMiddleOutline:
                image = cornerMiddleOutlineImage
            case .cornerMiddle:
                image = cornerMiddleImage
            case .cornerTopOutgoing:
                image = cornerTopOutgoingImage
            case .cornerTopOutlineOutgoing:
                image = cornerTopOutlineOutgoingImage
            case .cornerTopOutline:
                image = cornerTopOutlineImage
            case .cornerTop:
                image = cornerTopImage
            }
        }
    }

    func setImage(for positionType: MessagePositionType, isOutGoing: Bool, isPayment: Bool) {

        if isPayment {
            switch positionType {
            case .single, .top:
                type = isOutGoing ? .cornerTopOutlineOutgoing : .cornerTopOutline
            case .middle, .bottom:
                type = isOutGoing ? .cornerMiddleOutlineOutgoing : .cornerMiddleOutline
            }
        } else {
            switch positionType {
            case .single, .top:
                type = isOutGoing ? .cornerTopOutgoing : .cornerTop
            case .middle, .bottom:
                type = isOutGoing ? .cornerMiddleOutgoing : .cornerMiddle
            }
        }
    }
}

private extension UIImage {

    var messageStretchable: UIImage {
        return self.stretchableImage(withLeftCapWidth: 18, topCapHeight: 18)
    }
}
