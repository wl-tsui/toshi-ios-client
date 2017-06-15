import UIKit
import TinyConstraints

protocol ImagesViewControllerDismissDelegate {
    func imagesAreDismissed(from indexPath: IndexPath)
}

class ImagesViewController: UIViewController {

    var messages: [MessageModel] = []
    var initialIndexPath: IndexPath!
    var dismissDelegate: ImagesViewControllerDismissDelegate?
    var isInitialScroll: Bool = true

    var interactiveTransition: UIPercentDrivenInteractiveTransition?

    fileprivate lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
    }()

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

    lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.borderColor

        return view
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let view = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        view.tintColor = Theme.tintColor

        return view
    }()

    var currentIndexPath: IndexPath {
        let collectionViewCenter = CGPoint(x: self.collectionView.contentOffset.x + (self.collectionView.bounds.width / 2), y: self.collectionView.bounds.height / 2)
        let indexPath = self.collectionView.indexPathForItem(at: collectionViewCenter)
        return indexPath ?? self.initialIndexPath
    }

    convenience init(messages: [MessageModel], initialIndexPath: IndexPath) {
        self.init()
        self.messages = messages
        self.initialIndexPath = initialIndexPath

        self.modalPresentationStyle = .custom
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.navigationBar)
        self.navigationBar.top(to: self.view)
        self.navigationBar.left(to: self.view)
        self.navigationBar.right(to: self.view)
        self.navigationBar.height(64)

        self.navigationBar.addSubview(self.separatorView)
        self.separatorView.bottom(to: self.navigationBar)
        self.separatorView.left(to: self.navigationBar)
        self.separatorView.right(to: self.navigationBar)
        self.separatorView.height(Theme.borderHeight)

        self.view.addSubview(self.collectionView)
        self.collectionView.topToBottom(of: self.navigationBar)
        self.collectionView.left(to: self.view)
        self.collectionView.bottom(to: self.view)
        self.collectionView.right(to: self.view)

        self.navigationBar.setItems([UINavigationItem(title: self.title ?? "")], animated: false)
        self.navigationBar.topItem?.leftBarButtonItem = self.doneButton

        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
        self.panGestureRecognizer.delegate = self
        view.addGestureRecognizer(self.panGestureRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.view.layoutIfNeeded()
        self.collectionView.reloadData()

        guard let initialIndexPath = initialIndexPath else { return }
        self.collectionView.scrollToItem(at: initialIndexPath, at: .centeredHorizontally, animated: false)
        self.isInitialScroll = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.dismissDelegate?.imagesAreDismissed(from: self.currentIndexPath)
    }

    func done(_: UIBarButtonItem) {
        self.dismissDelegate?.imagesAreDismissed(from: self.currentIndexPath)

        self.dismiss(animated: true, completion: nil)
    }

    func pan(_ gestureRecognizer: UIPanGestureRecognizer) {

        switch gestureRecognizer.state {
        case .began:
            self.interactiveTransition = UIPercentDrivenInteractiveTransition()
            dismiss(animated: true, completion: nil)
        case .changed:
            let translation = gestureRecognizer.translation(in: view)
            let progress = max(translation.y / view.bounds.height, 0)
            self.interactiveTransition?.update(progress)
        case .ended:
            let translation = gestureRecognizer.translation(in: view)
            let velocity = gestureRecognizer.velocity(in: view)
            let shouldComplete = translation.y > 50 && velocity.y >= 0

            if shouldComplete {
                self.interactiveTransition?.finish()
            } else {
                self.interactiveTransition?.update(0)
                self.interactiveTransition?.cancel()
                self.interactiveTransition = nil
            }
        case .cancelled:
            self.interactiveTransition?.cancel()
            self.interactiveTransition = nil
        default: break
        }
    }
}

extension ImagesViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        if gestureRecognizer == panGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
            return translation.y > translation.x
        }

        return true
    }
}

extension ImagesViewController: UICollectionViewDataSource {

    func collectionView(_: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ImageCell else { return }
        cell.imageView.image = self.messages[indexPath.row].image
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath)
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return self.messages.count
    }

    func scrollViewDidScroll(_: UIScrollView) {
        if !self.isInitialScroll {
            self.dismissDelegate?.imagesAreDismissed(from: self.currentIndexPath)
        }
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
