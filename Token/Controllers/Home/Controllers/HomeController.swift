import UIKit
import SweetUIKit

class HomeController: SweetCollectionController {
    var appsAPIClient: AppsAPIClient
    var ethererumAPIClient: EthereumAPIClient

    var apps = [TokenContact]() {
        didSet {
            self.collectionView.reloadData()
        }
    }

    init(appsAPIClient: AppsAPIClient = .shared, ethererumAPIClient: EthereumAPIClient = .shared) {
        self.appsAPIClient = appsAPIClient
        self.ethererumAPIClient = ethererumAPIClient

        let layout = HomeLayout()

        super.init(collectionViewLayout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Home"
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = Theme.viewBackgroundColor

        self.collectionView.register(HomeItemCell.self)
        self.collectionView.register(HomeHeaderView.self, ofKind: HomeLayout.headerKind)

        self.appsAPIClient.getFeaturedApps { apps, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            }

            self.apps = apps
        }
    }
}

extension HomeController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.apps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(HomeItemCell.self, for: indexPath)
        let app = self.apps[indexPath.row]
        cell.app = app

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeue(HomeHeaderView.self, ofKind: HomeLayout.headerKind, for: indexPath)!

        self.ethererumAPIClient.getBalance(address: Cereal().paymentAddress) { balance, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            } else {
                view.balance = balance
            }
        }

        return view
    }
}

extension HomeController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let app = self.apps[indexPath.row]
        let appController = AppController(app: app)
        self.navigationController?.pushViewController(appController, animated: true)
    }
}
