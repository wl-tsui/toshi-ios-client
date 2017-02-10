import UIKit
import SweetUIKit

class AppsController: UIViewController {
    static let cellHeight = CGFloat(220)
    static let cellWidth = CGFloat(90)

    enum Section: Int {
        case latest, recommended
    }

    func constructLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: AppsController.cellWidth, height: AppsController.cellHeight)
        layout.sectionInset = UIEdgeInsets(top: 0, left: HomeLayout.horizontalMargin, bottom: 0, right: HomeLayout.horizontalMargin)
        layout.minimumLineSpacing = 15

        return layout
    }

    func constructCollectionView() -> UICollectionView {
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.constructLayout())
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false

        return view
    }

    lazy var latestTitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = "Recommended"
        label.font = Theme.regular(size: 14)
        label.textColor = UIColor(hex: "A4A4AB")

        return label
    }()

    lazy var recommendedTitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = "Latest"
        label.font = Theme.regular(size: 14)
        label.textColor = UIColor(hex: "A4A4AB")

        return label
    }()

    lazy var latestCollectionView: UICollectionView = {
        let view = self.constructCollectionView()

        return view
    }()

    lazy var recommendedCollectionView: UICollectionView = {
        let view = self.constructCollectionView()

        return view
    }()

    var latestApps = [App]() {
        didSet {
            self.latestCollectionView.reloadData()
        }
    }

    var recommendedApps = [App]() {
        didSet {
            self.recommendedCollectionView.reloadData()
        }
    }

    var appsAPIClient: AppsAPIClient

    init(appsAPIClient: AppsAPIClient = .shared) {
        self.appsAPIClient = appsAPIClient

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Apps"

        let separatorView = UIView(withAutoLayout: true)
        separatorView.backgroundColor = UIColor.gray

        self.view.addSubview(separatorView)
        self.view.addSubview(self.latestCollectionView)
        self.view.addSubview(self.recommendedCollectionView)
        self.view.addSubview(self.latestTitleLabel)
        self.view.addSubview(self.recommendedTitleLabel)

        self.latestCollectionView.backgroundColor = Theme.viewBackgroundColor
        self.latestCollectionView.dataSource = self
        self.latestCollectionView.delegate = self
        self.latestCollectionView.register(AppCell.self)

        self.recommendedCollectionView.backgroundColor = Theme.viewBackgroundColor
        self.recommendedCollectionView.dataSource = self
        self.recommendedCollectionView.delegate = self
        self.recommendedCollectionView.register(AppCell.self)

        self.recommendedTitleLabel.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor, constant: 20).isActive = true
        self.recommendedTitleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 15).isActive = true
        self.recommendedTitleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -15).isActive = true

        self.recommendedCollectionView.topAnchor.constraint(equalTo: self.recommendedTitleLabel.bottomAnchor, constant: 20).isActive = true
        self.recommendedCollectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.recommendedCollectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.recommendedCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: AppsController.cellHeight).isActive = true

        separatorView.topAnchor.constraint(equalTo: self.recommendedCollectionView.bottomAnchor, constant: -15).isActive = true
        separatorView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 15).isActive = true
        separatorView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -15).isActive = true

        self.latestTitleLabel.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: -15).isActive = true
        self.latestTitleLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 15).isActive = true
        self.latestTitleLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -15).isActive = true

        self.latestCollectionView.topAnchor.constraint(equalTo: self.latestTitleLabel.bottomAnchor, constant: 20).isActive = true
        self.latestCollectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.latestCollectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.latestCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: AppsController.cellHeight).isActive = true

        self.appsAPIClient.getApps { apps, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            }

            self.latestApps = apps
            self.recommendedApps = apps
        }
    }
}

extension AppsController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = collectionView == self.latestCollectionView ? Section.latest : Section.recommended

        switch section {
        case .latest:
            return self.latestApps.count
        case .recommended:
            return self.recommendedApps.count
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = collectionView == self.latestCollectionView ? Section.latest : Section.recommended
        let cell = collectionView.dequeue(AppCell.self, for: indexPath)

        let app: App
        switch section {
        case .latest:
            app = self.latestApps[indexPath.row]
        case .recommended:
            app = self.recommendedApps[indexPath.row]
        }

        cell.app = app

        return cell
    }
}

extension AppsController: UICollectionViewDelegate {
}
