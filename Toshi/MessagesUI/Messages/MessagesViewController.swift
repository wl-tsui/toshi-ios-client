import UIKit
import TinyConstraints

// Protocol to be implemented by the MessagesViewController subclass
// to provide it with message models.
protocol MessagesDataSource {
    func models() -> [MessageModel]
}

struct IndexPathSizes {
    var sizes: [IndexPath: CGSize] = [:]

    subscript(indexPath: IndexPath) -> CGSize? {
        get {
            return self.sizes[indexPath]
        } set {
            self.sizes[indexPath] = newValue
        }
    }
}

class MessagesViewController: OverlayController {

    var calculatedSizeCache = IndexPathSizes()

    var messagesDataSource: MessagesDataSource?

    lazy var layout: BouncyLayout = {
        let layout = BouncyLayout(style: .subtle)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 10

        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        view.register(MessageCell.self, forCellWithReuseIdentifier: MessageCell.reuseIdentifier)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .white
        view.delaysContentTouches = false
        view.alwaysBounceVertical = true

        return view
    }()

    lazy var protoTypeCell: MessageCell = {
        MessageCell()
    }()

    var additionalInsets: UIEdgeInsets = .zero {
        didSet {
            view.layoutIfNeeded()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(self.collectionView)
        self.collectionView.edges(to: view, priority: .high)

        self.updateInsets()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        self.updateInsets()
    }

    func updateInsets() {
        let extraVerticalContentInset: CGFloat = 10

        self.collectionView.contentInset = UIEdgeInsets(top: extraVerticalContentInset + self.additionalInsets.top, left: 0, bottom: extraVerticalContentInset + self.additionalInsets.bottom, right: 0)
        self.collectionView.scrollIndicatorInsets = UIEdgeInsets(top: self.additionalInsets.top, left: 0, bottom: self.additionalInsets.bottom, right: 0)
    }

    func calculateSize(for indexPath: IndexPath) -> CGSize {
        guard let messages = self.messagesDataSource?.models() else { return .zero }

        self.protoTypeCell.message = messages[indexPath.item]
        return self.protoTypeCell.size(for: self.collectionView.bounds.width)
    }

    func scrollToBottom(animated: Bool = true) {

        let contentHeight = self.collectionView.collectionViewLayout.collectionViewContentSize.height
        let boundsHeight = self.collectionView.bounds.size.height

        if !(contentHeight >= 0 && contentHeight < CGFloat.greatestFiniteMagnitude && boundsHeight >= 0) {
            return
        }

        let offsetY = max(-self.collectionView.contentInset.top, contentHeight - boundsHeight + self.collectionView.contentInset.bottom)
        let contentOffset = CGPoint(x: self.collectionView.contentOffset.x, y: offsetY)

        self.collectionView.setContentOffset(contentOffset, animated: animated)
    }
}

extension MessagesViewController: UICollectionViewDataSource {

    func collectionView(_: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let messages = self.messagesDataSource?.models() else { return }
        guard let cell = cell as? MessageCell else { return }
        cell.indexPath = indexPath

        let message = messages[indexPath.item]
        cell.message = message

        cell.setNeedsLayout()
        cell.layoutIfNeeded()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeue(MessageCell.self, for: indexPath)
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        guard let messages = self.messagesDataSource?.models() else { return 0 }
        return messages.count
    }
}

extension MessagesViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        if self.calculatedSizeCache[indexPath] == nil {
            self.calculatedSizeCache[indexPath] = self.calculateSize(for: indexPath)
        }

        return self.calculatedSizeCache[indexPath]!
    }
}
