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

protocol WalletPickerControllerDelegate: class {
    func didSelectWallet(_ wallet: Wallet)
}

final class WalletPickerController: UIViewController {
    weak var delegate: WalletPickerControllerDelegate?
    private var dataSource: WalletPickerDataSource?

    private lazy var tableView: UITableView = {
        let view = UITableView(frame: CGRect.zero, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = Theme.viewBackgroundColor
        view.register(WalletPickerCell.self)
        view.sectionFooterHeight = 0.0
        view.estimatedRowHeight = 50
        view.alwaysBounceVertical = true
        view.tableFooterView = UIView()
        view.separatorInset = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: .spacingx3)

        return view
    }()

    init(delegate: WalletPickerControllerDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = WalletPickerDataSource(tableView: tableView)

        addSubviewsAndConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(false)
    }

    private func addSubviewsAndConstraints() {
        view.addSubview(tableView)
        tableView.edges(to: view)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard isMovingFromParentViewController else { return }
        guard let wallet = dataSource?.selectedWallet else { return }

        delegate?.didSelectWallet(wallet)
    }
}

extension WalletPickerController: NavBarColorChanging {
    var navTintColor: UIColor? { return Theme.tintColor }
    var navBarTintColor: UIColor? { return Theme.navigationBarColor }
    var navTitleColor: UIColor? { return Theme.darkTextColor }
    var navShadowImage: UIImage? { return nil }
}
