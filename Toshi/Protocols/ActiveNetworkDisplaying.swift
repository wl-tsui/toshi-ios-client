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
import UIKit
import SweetUIKit

protocol ActiveNetworkDisplaying: class {
    var activeNetworkView: ActiveNetworkView { get }
    var activeNetworkViewConstraints: [NSLayoutConstraint] { get }
    var activeNetworkObserver: NSObjectProtocol? { get set }

    func defaultActiveNetworkView() -> ActiveNetworkView
    func setupActiveNetworkView()
    func showActiveNetworkViewIfNeeded()
    func hideActiveNetworkViewIfNeeded()

    func switchedNetworkChanged()

    func removeActiveNetworkObserver()

    func requestLayoutUpdate()
}

extension ActiveNetworkDisplaying where Self: UIViewController {

    func defaultActiveNetworkView() -> ActiveNetworkView {
        return ActiveNetworkView(withAutoLayout: true)
    }
    
    var activeNetworkViewConstraints: [NSLayoutConstraint] {
        return [
            activeNetworkView.bottomAnchor.constraint(equalTo: layoutGuide().bottomAnchor),
            activeNetworkView.leftAnchor.constraint(equalTo: view.leftAnchor),
            activeNetworkView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
    }

    func setupActiveNetworkView() {
        view.addSubview(activeNetworkView)
        NSLayoutConstraint.activate(activeNetworkViewConstraints)

        updateActiveNetworkView()
        addNotificationListener()
    }

    func showActiveNetworkViewIfNeeded() {
        guard !activeNetworkView.isAtFullHeight else {
            // Already showing
            return
        }

        activeNetworkView.setFullHeight()
        requestLayoutUpdate()
    }

    func hideActiveNetworkViewIfNeeded() {
        guard !activeNetworkView.isAtZeroHeight else {
            // Already hidden
            return
        }

        activeNetworkView.setZeroHeight()
        requestLayoutUpdate()
    }

    func requestLayoutUpdate() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    func addNotificationListener() {
        activeNetworkObserver = NotificationCenter
            .default
            .addObserver(forName: .SwitchedNetworkChanged,
                         object: nil,
                         queue: .main,
                         using: { [weak self] _ in
                            self?.switchedNetworkChanged()
                         })
    }

    func removeActiveNetworkObserver() {
        guard let observer = activeNetworkObserver else { return }

        NotificationCenter.default.removeObserver(observer)
    }

    func switchedNetworkChanged() {
        updateActiveNetworkView()
    }

    func updateActiveNetworkView() {
        switch NetworkSwitcher.shared.activeNetwork {
        case .mainNet:
            hideActiveNetworkViewIfNeeded()
        case .ropstenTestNetwork,
             .toshiTestNetwork:
            showActiveNetworkViewIfNeeded()
            activeNetworkView.updateTitle()
        }
    }
}
