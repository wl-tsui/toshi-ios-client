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

import Foundation
import SweetFoundation
import UIKit

protocol SearchSelectionDelegate: class {

    func didSelectSearchResult(user: TokenUser)
    func isSearchResultSelected(user: TokenUser) -> Bool
}

extension SearchSelectionDelegate {
    func isSearchResultSelected(user: TokenUser) -> Bool { return false }
}

class ProfileSearchResultView: UITableView {
    var isMultipleSelectionMode = false

    var searchResults: [TokenUser] = [] {
        didSet {
            reloadData()
        }
    }

    weak var searchDelegate: SearchSelectionDelegate?

    override var canBecomeFirstResponder: Bool {
        return true
    }

    // MARK: - Initialization

    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)

        backgroundColor = Theme.viewBackgroundColor

        dataSource = self
        delegate = self
        alwaysBounceVertical = true
        showsVerticalScrollIndicator = true
        tableFooterView = UIView(frame: .zero)

        BasicTableViewCell.register(in: self)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileSearchResultView: UITableViewDelegate {

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = searchResults.element(at: indexPath.row) else { return }

        searchDelegate?.didSelectSearchResult(user: item)
        reloadData()
    }
}

extension ProfileSearchResultView: UITableViewDataSource {
	
    func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let profile = searchResults.element(at: indexPath.row) else {
            assertionFailure("Could not get profile at indexPath: \(indexPath)")
            return UITableViewCell()
        }

        var showCheckmark = false
        if isMultipleSelectionMode {
            showCheckmark = true
        }

        let tableData = TableCellData(title: profile.name,
                                      subtitle: profile.isApp ? profile.descriptionForSearch : profile.username,
                                      leftImagePath: profile.avatarPath,
                                      showCheckmark: showCheckmark)
        let cellConfigurator = CellConfigurator()
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellConfigurator.cellIdentifier(for: tableData.components), for: indexPath) as? BasicTableViewCell else {
            assertionFailure("Could not dequeue basic table view cell")
            return UITableViewCell()
        }

        cell.checkmarkView.checked = searchDelegate?.isSearchResultSelected(user: profile) ?? false
        cell.selectionStyle = isMultipleSelectionMode ? .none : .default
        cellConfigurator.configureCell(cell, with: tableData)

        return cell
    }
}
