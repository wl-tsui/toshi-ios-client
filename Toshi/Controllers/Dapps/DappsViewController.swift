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

enum BrowseContentSection: Int {
    case topRatedApps
    case featuredDapps
    case topRatedPublicUsers
    case latestPublicUsers
    
    var title: String {
        switch self {
        case .topRatedApps:
            return Localized("browse-top-rated-apps")
        case .featuredDapps:
            return Localized("browse-featured-dapps")
        case .topRatedPublicUsers:
            return Localized("browse-top-rated-public-users")
        case .latestPublicUsers:
            return Localized("browse-latest-public-users")
        }
    }
}

protocol BrowseableItem {
    
    var nameForBrowseAndSearch: String { get }
    var descriptionForSearch: String? { get }
    var avatarPath: String { get }
    var shouldShowRating: Bool { get }
    var rating: Float? { get }
}

final class DappsViewController: UIViewController {

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    var statusBarStyle: UIStatusBarStyle = .lightContent {
        didSet {
            UIView.animate(withDuration: 0.5) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    var percentage: CGFloat = 0.0

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }

    let dappsHeaderHefight: CGFloat = 280
    let defaultSectionHeaderHeight: CGFloat = 50
    let searchedResultsSectionHeaderHeight: CGFloat = 24

    private var reloadTimer: Timer?

    private var cacheQueue = DispatchQueue(label: "org.toshi.cacheQueue")

    private lazy var activityView = self.defaultActivityIndicator()

    private lazy var dataSource: DappsDataSource = {
        let dataSource = DappsDataSource(mode: .frontPage)
        dataSource.delegate = self

        return dataSource
    }()

    private lazy var headerView: DappsTableHeaderView = {
        let headerView = DappsTableHeaderView(frame: CGRect.zero, delegate: self)

        return headerView
    }()

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .grouped)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = nil
        view.keyboardDismissMode = .interactive
        BasicTableViewCell.register(in: view)
        view.delegate = self
        view.dataSource = self
        view.layer.borderWidth = .lineHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.contentInset.top = -headerView.sizeRange.lowerBound
        view.scrollIndicatorInsets.top = -headerView.sizeRange.lowerBound
        view.sectionFooterHeight = 0.0
        view.contentInset.bottom = -21
        view.scrollIndicatorInsets.bottom = -21
        view.estimatedRowHeight = 98
        view.alwaysBounceVertical = true
        view.register(RectImageTitleSubtitleTableViewCell.self)
        view.register(UITableViewCell.self)
        view.separatorInset = UIEdgeInsets(top: 0, left: 100, bottom: 0, right: .defaultMargin)

        return view
    }()

    var scrollViewBottomInset: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        registerForKeyboardNotifications()

        addSubviewsAndConstraints()

        showActivityIndicator()
        dataSource.fetchItems()

        setupActivityIndicator()
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(tableView)
        view.addSubview(headerView)

        headerView.top(to: layoutGuide(), offset: -UIApplication.shared.statusBarFrame.height)
        headerView.left(to: view)
        headerView.right(to: view)

        tableView.top(to: layoutGuide(), offset: -UIApplication.shared.statusBarFrame.height)
        tableView.left(to: view)
        tableView.right(to: view)
        tableView.bottom(to: view)

        view.layoutIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func showResults(_ apps: [BrowseableItem]?, in section: BrowseContentSection, _ error: Error? = nil) {
        if let error = error {
            let alertController = UIAlertController.errorAlert(error as NSError)
            Navigator.presentModally(alertController)
        }
    }
    
    private func avatar(for indexPath: IndexPath, completion: @escaping ((UIImage?) -> Void)) {
        guard let item = dataSource.itemAtIndexPath(indexPath), let avatarPath = item.itemIconPath else {
            completion(nil)
            return
        }

        AvatarManager.shared.avatar(for: avatarPath, completion: { image, _ in
            completion(image)
        })
    }

    func rescheduleReload() {
        dataSource.cancelFetch()

        reloadTimer?.invalidate()
        reloadTimer = nil

        reloadTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.dataSource.reloadWithSearchText(strongSelf.headerView.searchTextField.currentOrEmptyText)
        }
    }
}

extension DappsViewController: DappsDataSourceDelegate {

    func dappsDataSourcedidReload(_ dataSource: DappsDataSource) {
        hideActivityIndicator()

        tableView.reloadData()
    }
}

extension DappsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfItems(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let item = dataSource.itemAtIndexPath(indexPath) else {
            fatalError("Can't find an item while dequeuing cell")
        }

        switch item.type {
        case .goToUrl, .searchWithGoogle:
            let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
            cell.textLabel?.text = item.displayTitle
            cell.separatorInset = .zero
            return cell
        case .dappFront, .dappSearched:
            let cell = tableView.dequeue(RectImageTitleSubtitleTableViewCell.self, for: indexPath)
            cell.titleLabel.text = item.displayTitle
            cell.subtitleLabel.text = item.displayDetails
            cell.leftImageView.image = #imageLiteral(resourceName: "collectible_placeholder")
            cell.imageViewPath = item.itemIconPath
            cell.leftImageView.layer.cornerRadius = 10
            return cell
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionData = dataSource.section(at: section) else { return nil }

        let header = DappsSectionHeaderView(delegate: self)
        header.backgroundColor = dataSource.mode == .frontPage ? Theme.viewBackgroundColor : Theme.lighterGreyTextColor
        header.titleLabel.textColor = dataSource.mode == .frontPage ? Theme.greyTextColor : Theme.lightGreyTextColor
        header.actionButton.setTitle(Localized("dapps-see-more-button-title"), for: .normal)
        header.tag = section

        header.titleLabel.text = sectionData.name?.uppercased()
        header.actionButton.isHidden = sectionData.categoryId == nil

        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch dataSource.mode {
        case .frontPage:
            return defaultSectionHeaderHeight
        case .allOrFiltered:
            return searchedResultsSectionHeaderHeight
        }
    }
}

extension DappsViewController: DappsSectionHeaderViewDelegate {
    func dappsSectionHeaderViewDidReceiveActionButtonEvent(_ sectionHeaderView: DappsSectionHeaderView) {
        guard let section = dataSource.section(at: sectionHeaderView.tag) else { return }
        guard let categoryId = section.categoryId else { return }

        let categoryDappsViewController = DappsCategoryViewController(categoryId: categoryId, name: section.name)
        Navigator.push(categoryDappsViewController)
    }
}

extension DappsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        guard let item = dataSource.itemAtIndexPath(indexPath) else { return }

        let searchBaseUrl = "https://www.google.com/search?q="

        switch item.type {
        case .goToUrl:
            guard
                let searchText = item.displayTitle,
                let possibleUrlString = searchText.asPossibleURLString,
                let url = URL(string: possibleUrlString)
                else { return }

            let sofaController = SOFAWebController()
            sofaController.load(url: url)

            Navigator.presentModally(sofaController)

        case .dappFront, .dappSearched:
            guard let dapp = item.dapp else { return }
            let controller = DappViewController(with: dapp, categoriesInfo: dataSource.categoriesInfo)
            Navigator.push(controller)

        case .searchWithGoogle:
            guard
                let searchText = item.displayTitle,
                let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                let url = URL(string: searchBaseUrl.appending(escapedSearchText))
                else { return }

            let sofaController = SOFAWebController()
            sofaController.load(url: url)

            Navigator.presentModally(sofaController)
        }
    }
}

extension DappsViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let percentage = scrollView.contentOffset.y.map(from: headerView.sizeRange, to: 0...1).clamp(to: -2...1)

        guard self.percentage != percentage else { return }

        headerView.didScroll(to: percentage)

        adjustContentSizeOn(scrollView: scrollView)

        self.percentage = percentage
        if percentage < 0.90 {
            statusBarStyle = UIStatusBarStyle.lightContent
        } else {
            statusBarStyle = UIStatusBarStyle.default
        }
    }

    private func adjustContentSizeOn(scrollView: UIScrollView) {
        var safeArea: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeArea = scrollView.safeAreaInsets.bottom
        }

        let height = scrollView.frame.height
        let insetBottom = scrollView.contentInset.bottom

        let contentOffset = headerView.sizeRange.upperBound
        let totalInset = abs(contentOffset - safeArea)
        let contentSpace = height - totalInset - insetBottom

        if scrollView.contentSize.height > 0 && scrollView.contentSize.height < contentSpace {
            scrollView.contentSize.height = contentSpace
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard headerView.sizeRange.contains(targetContentOffset.pointee.y) else { return}

        let centerOfRange = headerView.sizeRange.lowerBound + ((headerView.sizeRange.upperBound - headerView.sizeRange.lowerBound) / 2)
        targetContentOffset.pointee.y = targetContentOffset.pointee.y < centerOfRange ? headerView.sizeRange.lowerBound : headerView.sizeRange.upperBound
    }
}

extension DappsViewController: DappsSearchHeaderViewDelegate {

    func didRequireCollapsedState(_ headerView: DappsTableHeaderView) {
        showActivityIndicator()

        dataSource.queryData.isSearching = true

        if headerView.frame.height > -headerView.sizeRange.upperBound {
            // perform after delay to not have the contentOffset animation interfere with showing the keyboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self.tableView.setContentOffset(CGPoint(x: 0, y: self.headerView.sizeRange.upperBound), animated: true)
            })
        }
    }

    func didRequireDefaultState(_ headerView: DappsTableHeaderView) {
        if dataSource.queryData.isSearching {
            showActivityIndicator()
        }

        dataSource.queryData.isSearching = !headerView.searchTextField.currentOrEmptyText.isEmpty
    }

    func dappsSearchDidUpdateSearchText(_ headerView: DappsTableHeaderView, searchText: String) {
        dataSource.adjustToSearchText(searchText)
        rescheduleReload()
    }
}

extension DappsViewController: SearchSelectionDelegate {

    func didSelectSearchResult(user: TokenUser) {
        Navigator.push(ProfileViewController(profile: user))
    }
}

// MARK: - Keyboard Adjustable

extension DappsViewController: KeyboardAdjustable {
    var scrollView: UIScrollView {
        return tableView
    }

    var keyboardWillShowSelector: Selector {
        return #selector(keyboardShownNotificationReceived(_:))
    }

    var keyboardWillHideSelector: Selector {
        return #selector(keyboardHiddenNotificationReceived(_:))
    }

    @objc private func keyboardShownNotificationReceived(_ notification: NSNotification) {
        keyboardWillShow(notification)
    }

    @objc private func keyboardHiddenNotificationReceived(_ notification: NSNotification) {
        keyboardWillHide(notification)
    }
}

extension DappsViewController: ActivityIndicating {
    var activityIndicator: UIActivityIndicatorView {
        return activityView
    }
}
