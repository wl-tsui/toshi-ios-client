// Copyright (c) 2017 Token Browser, Inc
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

import UIKit
import SweetUIKit

class LaunchAppButton: UIControl {
    fileprivate lazy var titleLabel: UILabel = {
        return UILabel(withAutoLayout: true)
    }()

    fileprivate lazy var chevron: UIImageView = {
        let view = UIImageView(withAutoLayout: true)
        view.image = #imageLiteral(resourceName: "chevron")

        return view
    }()

    required init?(coder _: NSCoder) {
        fatalError()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.titleLabel)
        self.addSubview(self.chevron)

        let margin: CGFloat = 12.0

        self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: margin).isActive = true
        self.titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: margin).isActive = true
        self.titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -margin).isActive = true
        self.titleLabel.rightAnchor.constraint(equalTo: self.chevron.leftAnchor, constant: margin).isActive = true

        self.chevron.set(height: 14)
        self.chevron.set(width: 14)
        self.chevron.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.chevron.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -margin).isActive = true
    }

    func setAttributedTitle(_ attributedText: NSAttributedString?) {
        self.titleLabel.attributedText = attributedText
    }
}

class BrowseController: SearchableCollectionController {
    static let cellHeight = CGFloat(220)
    static let cellWidth = CGFloat(90)

    var featuredApps = [TokenUser]() {
        didSet {
            self.collectionView.reloadData()
        }
    }

    var searchResult = [TokenUser]() {
        didSet {
            self.collectionView.reloadData()
        }
    }

    fileprivate lazy var openURLButton: LaunchAppButton = {
        let view = LaunchAppButton(withAutoLayout: true)
        view.addTarget(self, action: #selector(self.didTapOpenURLButton), for: .touchUpInside)
        view.isHidden = true

        return view
    }()

    fileprivate lazy var openButtonAttributes: [String: Any] = {
        let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraph.alignment = .left

        return [NSForegroundColorAttributeName: Theme.tintColor, NSFontAttributeName: Theme.regular(size: 14)]
    }()

    fileprivate var openURLButtonTopAnchor: NSLayoutConstraint!

    var appsAPIClient: AppsAPIClient

    init(appsAPIClient: AppsAPIClient = .shared) {
        self.appsAPIClient = appsAPIClient

        super.init()

        self.loadViewIfNeeded()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.showsVerticalScrollIndicator = true
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.backgroundColor = Theme.viewBackgroundColor

        self.searchController.delegate = self

        self.searchBar.delegate = self
        self.searchBar.barTintColor = Theme.viewBackgroundColor
        self.searchBar.tintColor = Theme.tintColor

        let searchField = self.searchBar.value(forKey: "searchField") as? UITextField
        searchField?.backgroundColor = Theme.inputFieldBackgroundColor

        self.collectionView.register(AppCell.self)

        self.collectionView.addSubview(self.openURLButton)
        self.openURLButton.set(height: 44)
        self.openURLButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.openURLButton.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.openURLButtonTopAnchor = self.openURLButton.topAnchor.constraint(equalTo: self.collectionView.topAnchor)
        self.openURLButtonTopAnchor.constant = -self.searchBar.frame.maxY
        self.openURLButtonTopAnchor.isActive = true

        self.title = "Browse"

        self.appsAPIClient.getFeaturedApps { apps, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                self.present(alertController, animated: true, completion: nil)
            }

            self.featuredApps = apps
        }
    }

    @objc
    fileprivate func reload(searchText: String) {
        if searchText.isURL {
            let title = NSAttributedString(string: searchText, attributes: self.openButtonAttributes)
            self.openURLButton.setAttributedTitle(title)
            self.showOpenURLButton()

        } else {
            self.appsAPIClient.search(searchText) { apps, error in
                if let error = error {
                    let alertController = UIAlertController.errorAlert(error as NSError)
                    self.present(alertController, animated: true, completion: nil)
                }

                self.searchResult = apps
            }
        }
    }

    fileprivate func showOpenURLButton() {
        self.openURLButton.isHidden = false
        self.openURLButtonTopAnchor.constant = self.searchBar.frame.minY - 20 // 20pt statusbar
        UIView.animate(withDuration: 0.25) {
            self.collectionView.layoutIfNeeded()
        }
    }

    fileprivate func hideOpenURLButtonIfNeeded() {
        guard self.openURLButtonTopAnchor.constant == 0 else { return }

        self.openURLButton.isHidden = true
        self.openURLButtonTopAnchor.constant = -self.searchBar.frame.maxY
        UIView.animate(withDuration: 0.25) {
            self.collectionView.layoutIfNeeded()
            self.openURLButton.setAttributedTitle(nil)
        }
    }

    @objc
    fileprivate func didTapOpenURLButton() {
        guard let string = self.searchController.searchBar.text, let url = URL(string: string) else { return }

        let sofaController = SOFAWebController()

        sofaController.load(url: url)
        self.navigationController?.pushViewController(sofaController, animated: true)
    }
}

extension BrowseController {

    override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        if self.searchController.isActive {
            return self.searchResult.count
        }

        return self.featuredApps.count
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(AppCell.self, for: indexPath)

        if self.searchController.isActive {
            let app = self.searchResult[indexPath.row]
            cell.app = app
        } else {
            let app = self.featuredApps[indexPath.row]
            cell.app = app
        }

        return cell
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.searchController.isActive {
            let app = self.searchResult[indexPath.row]
            let appController = ContactController(contact: app)
            self.navigationController?.pushViewController(appController, animated: true)
        } else {
            let app = self.featuredApps[indexPath.row]
            let appController = ContactController(contact: app)
            self.navigationController?.pushViewController(appController, animated: true)
        }
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return 10
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return CGSize(width: 120, height: 140)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        return 10
    }
}

extension BrowseController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange searchText: String) {

        if searchText.isEmpty {
            self.searchResult = [TokenUser]()
            self.hideOpenURLButtonIfNeeded()
        }

        // Throttles search to delay performing a search while the user is typing.
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reload(searchText:)), object: searchText)
        self.perform(#selector(self.reload(searchText:)), with: searchText, afterDelay: 0.5)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        self.hideOpenURLButtonIfNeeded()
    }
}

extension BrowseController {
    override func didDismissSearchController(_ searchController: UISearchController) {
        super.didDismissSearchController(searchController)

        self.collectionView.reloadData()
    }

    override func willPresentSearchController(_ searchController: UISearchController) {
        super.willPresentSearchController(searchController)

        self.collectionView.reloadData()
    }
}

extension BrowseController: SearchResultsViewDelegate {

    func searchResultsView(_: SearchResultsView, didTapApp app: TokenUser) {
        let appController = ContactController(contact: app)
        self.navigationController?.pushViewController(appController, animated: true)
    }
}
