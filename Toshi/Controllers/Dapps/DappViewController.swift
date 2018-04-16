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

final class DappViewController: DisappearingNavBarViewController {
    let dappCoverHeaderHeight: CGFloat = 200
    let dappNoCoverHeaderHeight: CGFloat = 44

    private let dapp: Dapp

    override var backgroundTriggerView: UIView {
        return coverImageHeaderView
    }

    override var titleTriggerView: UIView {
        return dappInfoView.titleLabel
    }

    private lazy var coverImageHeaderView: UIImageView = {
        let frame = CGRect(origin: .zero, size: CGSize(width: self.view.bounds.width, height: self.dappCoverHeaderHeight))

        let header = UIImageView(frame: frame)
        header.clipsToBounds = true
        header.contentMode = .scaleAspectFill
        header.image = ImageAsset.dapp_cover_placeholder

        return header
    }()

    private lazy var dappInfoView: DappInfoView = {
        let view = DappInfoView(frame: .zero)
        view.titleLabel.text = dapp.name
        view.descriptionLabel.setSpacedOutText(dapp.description ?? "", lineSpacing: DappInfoView.descriptionLineSpacing)
        view.urlLabel.text = dapp.url.absoluteString
        view.imageViewPath = dapp.avatarPath

        let dappCategoriesInfo = categoriesInfo?.filter { dapp.categories.contains($0.key) }
        view.categoriesInfo = dappCategoriesInfo

        view.delegate = self

        return view
    }()

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = nil
        view.keyboardDismissMode = .interactive
        view.dataSource = self
        view.tableFooterView = UIView()
        view.register(UITableViewCell.self)
        view.rowHeight = UITableViewAutomaticDimension
        view.estimatedRowHeight = .defaultCellHeight
        view.separatorStyle = .none
        view.contentInset.bottom = navigationController?.tabBarController?.tabBar.frame.height ?? 0
        if #available(iOS 11.0, *) {
           view.contentInsetAdjustmentBehavior = .never
        }

        return view
    }()

    private var categoriesInfo: DappCategoryInfo?

    required init(with dapp: Dapp, categoriesInfo: DappCategoryInfo?) {
        self.dapp = dapp
        self.categoriesInfo = categoriesInfo

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        showCover()
        navBar.setTitle(dapp.name)

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear

        view.backgroundColor = Theme.viewBackgroundColor

        automaticallyAdjustsScrollViewInsets = false
    }

    private func showCover() {
        guard let path = dapp.coverUrlString else {
            setupNoCoverImageHeaderView()
            return
        }

        AvatarManager.shared.avatar(for: path) { [weak self] image, _ in
            guard let strongSelf = self else { return }
            guard let fetchedImage = image else {
                strongSelf.setupNoCoverImageHeaderView()
                return
            }

            UIView.transition(with: strongSelf.coverImageHeaderView, duration: 0.3, options: .transitionCrossDissolve, animations: {

                self?.coverImageHeaderView.image = fetchedImage

            }, completion: nil)
        }
    }

    private func setupNoCoverImageHeaderView() {
        coverImageHeaderView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: dappNoCoverHeaderHeight + UIApplication.shared.statusBarFrame.height))
        tableView.tableHeaderView = coverImageHeaderView
    }

    // We do not need to add content to scrollViewContainer used in parent controller,
    // since the scrollView here is tableView
    override func addScrollableContent(to contentView: UIView) { }

    override var scrollingView: UIScrollView {
        return self.tableView
    }

    override func setupNavBarAndScrollingContent() {
        view.addSubview(tableView)
        tableView.tableHeaderView = coverImageHeaderView

        scrollingView.delegate = self
        tableView.edgesToSuperview()

        view.addSubview(navBar)

        navBar.edgesToSuperview(excluding: .bottom)
        updateNavBarHeightIfNeeded()
        navBar.heightConstraint = navBar.height(navBarHeight)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)

        let offsetDivider = scrollView.contentOffset.y / 100
        let alpha = 1 - offsetDivider
        coverImageHeaderView.alpha = alpha
    }
}

extension DappViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
        cell.contentView.addSubview(dappInfoView)
        cell.selectionStyle = .none
        dappInfoView.edgesToSuperview()

        return cell
    }
}

extension DappViewController: DappInfoDelegate {

    func dappInfoViewDidReceiveCategoryDetailsEvent(_ cell: DappInfoView, categoryId: Int, categoryName: String) {
        let categoryDappsViewController = DappsListViewController(categoryId: categoryId, name: categoryName)
        Navigator.push(categoryDappsViewController)
    }

    func dappInfoViewDidReceiveDappDetailsEvent(_ cell: DappInfoView) {
        let sofaWebController = SOFAWebController()
        sofaWebController.load(url: dapp.url)

        Navigator.presentModally(sofaWebController)
    }
}
