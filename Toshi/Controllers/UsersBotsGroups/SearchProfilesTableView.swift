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

protocol ProfileTypeSelectionDelegate: class {
    func searchProfilesTableViewDidChangeProfileType(_ tableView: SearchProfilesTableView)
}

final class SearchProfilesTableView: UITableView {

    weak var profileTypeSelectionDelegate: ProfileTypeSelectionDelegate?
    private(set) var selectedProfileType = ProfileType.user

    private lazy var segmentedHeaderView: SegmentedHeaderView = {
        let searchItemTitles = [ProfileType.user.title, ProfileType.bot.title, ProfileType.group.title]
        let headerView = SegmentedHeaderView(segmentNames: searchItemTitles, delegate: self)
        headerView.backgroundColor = Theme.viewBackgroundColor

        return headerView
    }()

    // MARK: - Initialization

    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)

        backgroundColor = Theme.viewBackgroundColor

        estimatedRowHeight = .defaultCellHeight

        alwaysBounceVertical = true
        showsVerticalScrollIndicator = true
        tableFooterView = UIView(frame: .zero)

        tableHeaderView = segmentedHeaderView
        tableHeaderView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)

        BasicTableViewCell.register(in: self)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchProfilesTableView: SegmentedHeaderDelegate {

    func segmentedHeader(_: SegmentedHeaderView, didSelectSegmentAt index: Int) {
        guard let searchTab = ProfileType(rawValue: index) else { return }

        selectedProfileType = searchTab
        profileTypeSelectionDelegate?.searchProfilesTableViewDidChangeProfileType(self)
    }
}
