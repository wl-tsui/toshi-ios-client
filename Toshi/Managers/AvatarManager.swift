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
import Teapot
import Haneke

final class AvatarManager: NSObject {

    @objc static let shared = AvatarManager()

    private let cache = Shared.imageCache

    func refreshAvatar(at path: String) {
        cache.remove(key: path)
    }

    @objc func cleanCache() {
        cache.removeAll()
    }

    @objc func startDownloadContactsAvatars() {
        if let currentUserAvatarPath = Profile.current?.avatar {
           downloadAvatar(for: currentUserAvatarPath)
        }

        for path in SessionManager.shared.profilesManager.profilesAvatarPaths {
            downloadAvatar(for: path)
        }
    }

    private func baseURL(from url: URL) -> String? {
        if url.baseURL == nil {
            guard let scheme = url.scheme, let host = url.host else { return nil }
            return "\(scheme)://\(host)"
        }

        return url.baseURL?.absoluteString
    }

    func downloadAvatar(for key: String, completion: ((UIImage?, String?) -> Void)? = nil) {

        if key.hasAddressPrefix {

            cache.fetch(key: key).onSuccess { image in
                completion?(image, key)
                }.onFailure({ _ in
                    IDAPIClient.shared.findContact(name: key) { [weak self] profile, _ in

                        guard let avatarPath = profile?.avatar else {
                            completion?(nil, key)
                            return
                        }

                        UserDefaults.standard.set(avatarPath, forKey: key)
                        self?.downloadAvatar(path: avatarPath, completion: completion)
                    }
                })
        } else {

            cache.fetch(key: key).onSuccess { image in
                completion?(image, key)
                return
                }.onFailure { [weak self] _ in
                    guard let strongSelf = self else { return }
                    strongSelf.downloadAvatar(path: key)
            }
        }
    }

    private func downloadAvatar(path: String, completion: ((UIImage?, String?) -> Void)? = nil) {
        cache.fetch(key: path).onSuccess { image in

            completion?(image, path)

            }.onFailure({ _ in

                guard let url = URL(string: path) else {
                    DispatchQueue.main.async {
                        completion?(nil, path)
                    }

                    return
                }

                URLSession.shared.dataTask(with: url, completionHandler: { [weak self] data, _, _ in

                    guard let strongSelf = self else { return }
                    guard let retrievedData = data else { return }

                    guard let image = UIImage(data: retrievedData) else { return }
                    strongSelf.cache.set(value: image, key: path)

                    DispatchQueue.main.async {
                        completion?(image, path)
                    }
                }).resume()
            })
    }

    /// Downloads or finds avatar for given key.
    ///
    /// - Parameters:
    ///   - key: token_id/address or resource url path.
    ///   - completion: The completion closure to fire when the request completes or image is found in cache.
    ///                 - image: Found in cache or fetched image.
    ///                 - path: Path for found in cache or fetched image.
    func avatar(for key: String, completion: @escaping ((UIImage?, String?) -> Void)) {
        if key.hasAddressPrefix {
            if let avatarPath = UserDefaults.standard.object(forKey: key) as? String {
                _avatar(for: avatarPath, completion: completion)
            } else {
                downloadAvatar(for: key, completion: completion)
            }
        }

        _avatar(for: key, completion: completion)
    }

    /// Downloads or finds avatar for the resource url path.
    ///
    /// - Parameters:
    ///   - path: An resource url path.
    ///   - completion: The completion closure to fire when the request completes or image is found in cache.
    ///                 - image: Found in cache or fetched image.
    ///                 - path: Path for found in cache or fetched image.
    private func _avatar(for path: String, completion: @escaping ((UIImage?, String?) -> Void)) {
        cache.fetch(key: path).onSuccess { image in
            completion(image, path)
            }.onFailure { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.downloadAvatar(path: path, completion: completion)
        }
    }

    /// Finds avatar for the given key.
    ///
    /// - Parameters:
    ///   - key: token_id/address or resource url path.
    /// - Returns:
    ///   - found image or nil if not present

    @objc func cachedAvatar(for key: String) -> UIImage? {
        guard !key.hasAddressPrefix else {
            guard let avatarPath = UserDefaults.standard.object(forKey: key) as? String else { return nil }
            return cachedAvatar(for: avatarPath)
        }

        var image: UIImage?

        cache.fetch(key: key).onSuccess { cachedImage in
            image = cachedImage
        }

        return image
    }
}
