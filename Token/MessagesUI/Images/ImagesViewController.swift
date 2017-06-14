import UIKit
import TinyConstraints

typealias ImagesViewControllerDismiss = (IndexPath) -> Void

class ImagesViewController: UIViewController {

    var messages: [MessageModel] = []
    var initialIndexPath: IndexPath!
    var prepareBeforeDismiss: ImagesViewControllerDismiss?

    lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal

        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        view.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .white
        view.delaysContentTouches = false
        view.isPagingEnabled = true

        return view
    }()

    lazy var navigationBar: UINavigationBar = {
        let view = UINavigationBar()
        view.barStyle = .default

        return view
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let view = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        view.tintColor = Theme.tintColor

        return view
    }()

    convenience init(messages: [MessageModel], initialIndexPath: IndexPath) {
        self.init()
        self.messages = messages
        self.initialIndexPath = initialIndexPath

        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.navigationBar)
        self.navigationBar.top(to: self.view)
        self.navigationBar.left(to: self.view)
        self.navigationBar.right(to: self.view)
        self.navigationBar.height(64)

        self.view.addSubview(self.collectionView)
        self.collectionView.topToBottom(of: self.navigationBar)
        self.collectionView.left(to: self.view)
        self.collectionView.bottom(to: self.view)
        self.collectionView.right(to: self.view)

        self.navigationBar.setItems([UINavigationItem(title: self.title!)], animated: false)
        self.navigationBar.topItem?.leftBarButtonItem = self.doneButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.view.layoutIfNeeded()
        self.collectionView.reloadData()

        guard let initialIndexPath = initialIndexPath else { return }
        self.collectionView.scrollToItem(at: initialIndexPath, at: .centeredHorizontally, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let currentIndexPath = self.currentIndexPath {
            self.prepareBeforeDismiss?(currentIndexPath)
        }
    }

    func done(_: UIBarButtonItem) {
        if let currentIndexPath = self.currentIndexPath {
            self.prepareBeforeDismiss?(currentIndexPath)
        }

        self.dismiss(animated: true, completion: nil)
    }

    var currentIndexPath: IndexPath? {
        let indexPath = self.collectionView.indexPathForItem(at: CGPoint(x: self.collectionView.contentOffset.x + (self.collectionView.bounds.width / 2), y: self.collectionView.bounds.height / 2))
        return indexPath
    }
}

extension ImagesViewController: UICollectionViewDataSource {

    func collectionView(_: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt _: IndexPath) {
        guard cell is ImageCell else { return }
        // cell.imageUrl = messages[indexPath.row].imageUrl
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath)
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return self.messages.count
    }
}

extension ImagesViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        if self.messages[indexPath.row].image != nil {
            return CGSize(width: self.view.bounds.width, height: self.view.bounds.height - 64)
        }

        return CGSize(width: 0, height: self.view.bounds.height - 64)
    }
}

extension ImagesViewController: UICollectionViewDelegate {

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didSelectItemAt:\(indexPath)")
    }
}

extension ImagesViewController: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source _: UIViewController) -> UIPresentationController? {
        return presented == self ? ImagesViewControllerPresentationController(presentedViewController: presented, presenting: presenting) : nil
    }

    func animationController(forPresented presented: UIViewController, presenting _: UIViewController, source _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presented == self ? ImagesViewControllerTransition(operation: .present) : nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dismissed == self ? ImagesViewControllerTransition(operation: .dismiss) : nil
    }
}
