import UIKit
import UICollectionViewLeftAlignedLayout

class ControlsCollectionView: UICollectionView {

    convenience init() {
        self.init(frame: .zero, collectionViewLayout: UICollectionViewLeftAlignedLayout())
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for cell in self.visibleCells {
            if cell.frame.contains(point) {
                return super.point(inside: point, with: event)
            }
        }

        return false
    }
}
