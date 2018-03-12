// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import SweetFoundation
import UIKit
import SweetUIKit

final class DappViewController: UIViewController {
    let dappConverHeaderHeight: CGFloat = 200

    private let dapp: Dapp

    private lazy var coverImageHeadrView: UIImageView = {
        let frame = CGRect(origin: .zero, size: CGSize(width: self.view.bounds.width, height: self.dappConverHeaderHeight))

        let header = UIImageView(frame: frame)
        header.clipsToBounds = true
        header.contentMode = .scaleAspectFill
        header.image = #imageLiteral(resourceName: "dapp-cover-placeholder")

        return header
    }()

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = nil
        view.keyboardDismissMode = .interactive
        BasicTableViewCell.register(in: view)
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.alwaysBounceVertical = true
        view.register(DappInfoCell.self)
        view.rowHeight = UITableViewAutomaticDimension
        view.estimatedRowHeight = 44

        return view
    }()

    private var categoriesInfo: DappCategoryInfo?

    required init(with dapp: Dapp, categoriesInfo: DappCategoryInfo?) {
        self.dapp = dapp
        self.categoriesInfo = categoriesInfo

        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = Theme.viewBackgroundColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubviewsAndConstraints()
        showCover()

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(tableView)

        tableView.tableHeaderView = coverImageHeadrView
    }

    private func showCover() {
        guard let path = dapp.coverUrlString else { return }
        AvatarManager.shared.avatar(for: path) { [weak self] image, _ in

            guard let strongSelf = self, let fetchedImage = image else { return }

            UIView.transition(with: strongSelf.coverImageHeadrView, duration: 0.3, options: .transitionCrossDissolve, animations: {

                self?.coverImageHeadrView.image = fetchedImage

            }, completion: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

extension DappViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeue(DappInfoCell.self, for: indexPath)
        cell.titleLabel.text = dapp.name
        cell.descriptionLabel.text = dapp.description
        cell.urlLabel.text = dapp.url.absoluteString
        cell.imageViewPath = dapp.avatarPath

        let dappCategoriesInfo = categoriesInfo?.filter { dapp.categories.contains($0.key) }
        cell.categoriesInfo = dappCategoriesInfo

        cell.delegate = self

        return cell
    }
}

extension DappViewController: DappInfoDelegate {

    func dappInfoCellDidReceiveCategoryDetailsEvent(_ cell: DappInfoCell, categoryId: Int, categoryName: String) {
        let categoryDappsViewController = DappsCategoryViewController(categoryId: categoryId, name: categoryName)
        Navigator.push(categoryDappsViewController)
    }

    func dappInfoCellDidReceiveDappDetailsEvent(_ cell: DappInfoCell) {
        let sofaWebController = SOFAWebController()
        sofaWebController.load(url: dapp.url)

        Navigator.presentModally(sofaWebController)
    }
}

extension DappViewController: UITableViewDelegate {

}
