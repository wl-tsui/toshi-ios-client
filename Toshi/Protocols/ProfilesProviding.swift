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

protocol ProfilesProviding: class {
    func searchProfilesOfType(type: String, searchText: String?, completion: @escaping (([Profile]?, _ type: String?) -> Void))
    func searchProfilesFrontPage(completion: @escaping (([ProfilesFrontPageSection]?) -> Void))
}

extension ProfilesProviding {

    func searchProfilesOfType(type: String, searchText: String?, completion: @escaping (([Profile]?, _ type: String?) -> Void)) {
        IDAPIClient.shared.searchProfilesOfType(type, for: searchText) { [weak self] profiles, type, error in
            guard let strongSelf = self else { return }
            guard error == nil else {
                strongSelf.showErrorAlert(error!)
                completion(nil, type)
                return
            }

            completion(profiles, type)
        }
    }

    func searchProfilesFrontPage(completion: @escaping (([ProfilesFrontPageSection]?) -> Void)) {
        IDAPIClient.shared.fetchProfilesFrontPage { [weak self] sections, error in
            guard let strongSelf = self else { return }
            guard error == nil else {
                strongSelf.showErrorAlert(error!)
                completion(nil)
                return
            }

            completion(sections)
        }
    }

    private func showErrorAlert(_ error: ToshiError) {
        let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.alert_ok_action_title, style: .default, handler: nil))
        Navigator.presentModally(alert)
    }
}
