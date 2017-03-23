import UIKit

class ControlsCollectionView: UICollectionView {

    convenience init() {
        self.init(frame: .zero, collectionViewLayout: UICollectionViewRightAlignedLayout())
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for cell in self.visibleCells {
            if cell.frame.contains(point) {
                return super.point(inside: point, with: event)
            }
        }

        return false
    }

    func deselectButtons() {
        self.visibleCells.forEach { cell in
            (cell as? ControlCell)?.button.isSelected = false
        }
    }
}
