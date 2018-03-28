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

import UIKit

final class SearchDappTableView: UITableView {

    // We dequeue separate cells for generic UITableViewCell with text and one which has added custom subview
    // so we do not have to remove those subview on reuse of a UITableViewCell instance
    private let buttonCellReuseIdentifier = "ButtonCellReuseIdentifier"
    private let genericCellReuseIdentifier = "GenericCellReuseIdentifier"

    private lazy var searchDataSource: DappsDataSource = {
        let dataSource = DappsDataSource(mode: .allOrFiltered)
        dataSource.delegate = self

        return dataSource
    }()


    override init(frame: CGRect, style: UITableViewStyle = .grouped) {
        super.init(frame: frame, style: style)

        self.translatesAutoresizingMaskIntoConstraints = false

        BasicTableViewCell.register(in: self)
        self.register(RectImageTitleSubtitleTableViewCell.self)
        self.register(UITableViewCell.self, forCellReuseIdentifier: buttonCellReuseIdentifier)
        self.register(UITableViewCell.self, forCellReuseIdentifier: genericCellReuseIdentifier)
        
        self.backgroundColor = Theme.viewBackgroundColor
        self.sectionFooterHeight = 0.0
        self.contentInset.bottom = -21
        self.scrollIndicatorInsets.bottom = -21
        self.estimatedRowHeight = 98
        self.alwaysBounceVertical = true
        self.separatorStyle = .none
        self.delegate = self
        self.dataSource = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func adjustToSearchText(_ string: String) {
        searchDataSource.adjustToSearchText(string)
    }
}

extension SearchDappTableView: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return searchDataSource.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchDataSource.numberOfItems(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let item = searchDataSource.itemAtIndexPath(indexPath) else {
            fatalError("Can't find an item while dequeuing cell")
        }

        switch item.type {
        case .goToUrl:
            let cell = tableView.dequeueReusableCell(withIdentifier: genericCellReuseIdentifier, for: indexPath)

            cell.selectionStyle = .none
            cell.textLabel?.text = item.displayTitle
            cell.textLabel?.textColor = Theme.tintColor
            return cell
        case .searchWithGoogle:
            let cell = tableView.dequeueReusableCell(withIdentifier: genericCellReuseIdentifier, for: indexPath)

            cell.selectionStyle = .none

            let googleText = " – \(Localized.dapps_search_with_google_section_title)"
            let text = (item.displayTitle ?? "") + googleText
            let attributedString = NSMutableAttributedString(string: text)

            attributedString.addAttribute(.font, value: Theme.preferredRegularTiny(), range: NSRange(location: 0, length: attributedString.length))
            if let range = text.range(of: googleText) {
                attributedString.addAttribute(.foregroundColor, value: Theme.placeholderTextColor, range: NSRange(location: range.lowerBound.encodedOffset, length: googleText.count))
            }

            cell.textLabel?.attributedText = attributedString

            return cell
        case .dappFront:
            let cell = tableView.dequeue(RectImageTitleSubtitleTableViewCell.self, for: indexPath)
            cell.titleLabel.text = item.displayTitle
            cell.subtitleLabel.text = item.displayDetails
            cell.leftImageView.image = ImageAsset.collectible_placeholder
            cell.imageViewPath = item.itemIconPath

            setCustomSeparators(for: indexPath, on: cell)

            return cell
        case .dappSearched:
            let cellData = TableCellData(title: item.displayTitle, subtitle: item.dapp?.url.absoluteString, leftImagePath: item.itemIconPath)
            let configurator = CellConfigurator()
            guard let cell = tableView.dequeueReusableCell(withIdentifier: configurator.cellIdentifier(for: cellData.components), for: indexPath) as? BasicTableViewCell else { return UITableViewCell() }

            configurator.configureCell(cell, with: cellData)
            cell.leftImageView.layer.cornerRadius = 5

            return cell
        case .seeAll:
            let cell = tableView.dequeueReusableCell(withIdentifier: buttonCellReuseIdentifier, for: indexPath)
            // this cant happen
            return cell
        }
    }

    private func setCustomSeparators(for indexPath: IndexPath, on cell: RectImageTitleSubtitleTableViewCell) {
        if searchDataSource.numberOfItems(in: indexPath.section) == (indexPath.row + 1) {
            cell.sectionSeparator.alpha = 1
        } else {
            cell.customSeparator.alpha = 1
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionData = searchDataSource.section(at: section) else { return nil }

        let header = DappsSectionHeaderView(delegate: self)
        header.backgroundColor = searchDataSource.mode == .frontPage ? Theme.viewBackgroundColor : Theme.lighterGreyTextColor
        header.titleLabel.textColor = searchDataSource.mode == .frontPage ? Theme.greyTextColor : Theme.lightGreyTextColor
        header.actionButton.setTitle(Localized.dapps_see_more_button_title, for: .normal)
        header.tag = section

        header.titleLabel.text = sectionData.name?.uppercased()
        header.actionButton.isHidden = sectionData.categoryId == nil

        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return DappsSectionHeaderView.searchedResultsSectionHeaderHeight
    }
}

extension SearchDappTableView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        guard let item = searchDataSource.itemAtIndexPath(indexPath) else { return }

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

        case .dappFront:
            guard let dapp = item.dapp else { return }
            let controller = DappViewController(with: dapp, categoriesInfo: searchDataSource.categoriesInfo)
            Navigator.push(controller)
        case .dappSearched:
            guard let dapp = item.dapp else { return }
                // navigate
        case .searchWithGoogle:
            guard
                    let searchText = item.displayTitle,
                    let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                    let url = URL(string: searchBaseUrl.appending(escapedSearchText))
                    else { return }

            let sofaController = SOFAWebController()
            sofaController.load(url: url)

            Navigator.presentModally(sofaController)
        case .seeAll:
            // We ignore selection as the cell contains action button which touch event do we process
            break
        }
    }
}

extension SearchDappTableView: DappsDataSourceDelegate {

    func dappsDataSourcedidReload(_ dataSource: DappsDataSource) {
//        hideActivityIndicator()

        self.reloadData()
    }
}


extension SearchDappTableView: DappsSectionHeaderViewDelegate {
    func dappsSectionHeaderViewDidReceiveActionButtonEvent(_ sectionHeaderView: DappsSectionHeaderView) {

    }
}