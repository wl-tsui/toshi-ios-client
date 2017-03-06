import UIKit
import UICollectionViewLeftAlignedLayout

protocol ControlViewActionDelegate {
    func controlsCollectionViewDidSelectControl(at index: Int)
}

class ControlsViewDelegateDatasource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateLeftAlignedLayout, ControlCellDelegate {
    var items: [SofaMessage.Button] = [] {
        didSet {
            self.controlsCollectionView?.isUserInteractionEnabled = true
        }
    }

    var controlsCollectionView: ControlsCollectionView?

    var actionDelegate: ControlViewActionDelegate?

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.items.count == 0 ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ControlCell = collectionView.dequeue(ControlCell.self, for: indexPath)
        cell.buttonItem = self.items[indexPath.row]
        cell.delegate = self

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = ControlCell(frame: .zero)
        cell.buttonItem = self.items[indexPath.row]

        let size = cell.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: 38))

        return size
    }

    func didTapButton(for cell: ControlCell) {
        guard let indexPath = self.controlsCollectionView?.indexPath(for: cell) else { return }
        let normalizedIndexPath = self.reversedControlIndexPath(indexPath)

        self.actionDelegate?.controlsCollectionViewDidSelectControl(at: normalizedIndexPath.row)
    }

    func reversedControlIndexPath(_ indexPath: IndexPath) -> IndexPath {
        let row = (self.items.count - 1) - indexPath.item
        return IndexPath(row: row, section: indexPath.section)
    }
}
