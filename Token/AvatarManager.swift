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

import Foundation
import Teapot
import AwesomeCache

final class AvatarManager: NSObject, CacheExpiryDefault {

    static let shared = AvatarManager()

    private var imageCache = try! Cache<UIImage>(name: "imageCache")

    private lazy var downloadOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Download avatars queue"

        return queue
    }()

    func avatar(for path: String, completion: @escaping ((UIImage?) -> Void)) {
        let avatar = self.imageCache.object(forKey: path)

        guard avatar != nil else {
            self.downloadAvatar(path: path) { image in
                completion(image)
            }

            return
        }

        completion(avatar)
    }

    func cachedAvatar(for path: String) -> UIImage? {
        return self.imageCache.object(forKey: path)
    }

    func refreshAvatar(at path: String) {
        self.imageCache.removeObject(forKey: path)
    }

    func cleanCache() {
        self.imageCache.removeAllObjects()
    }

    func startDownloadContactsAvatars() {
        self.downloadOperationQueue.cancelAllOperations()
        
        let operation = BlockOperation()
        operation.addExecutionBlock {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let contactsManager = appDelegate.contactsManager as ContactsManager? else { return }
            
            let avatarPaths = contactsManager.tokenContacts.flatMap { contact in
                contact.avatarPath as String
            }
            if let currentUserAvatarPath = TokenUser.current?.avatarPath as String? {
                self.downloadAvatar(for: currentUserAvatarPath)
            }
            
            for path in avatarPaths {
                if operation.isCancelled { return }
                self.downloadAvatar(for: path)
            }
        }

        self.downloadOperationQueue.addOperation(operation)
    }

    private func downloadAvatar(for path: String) {
        guard self.imageCache.object(forKey: path) == nil else {
            print(" v --- Found the object, continuing")
            return
        }

        print(">>> Downloading for :\(path)")

        self.downloadAvatar(path: path) { _ in
            print(" *****  Downloaded for :\(path)")
        }
    }

    func downloadAvatar(path: String, completion: @escaping (_ image: UIImage?) -> Void) {
        self.imageCache.setObject(forKey: path, cacheBlock: { success, failure in

            DispatchQueue.global(qos: .userInitiated).async {
                let teapot = Teapot(baseURL: URL(string: path)!)
                teapot.get { (result: NetworkImageResult) in
                    switch result {
                    case .success(let image, _):
                        success(image, self.cacheExpiry)
                    case .failure(let response, let error):
                        print(response)
                        print(error)
                        failure(error as NSError)
                    }
                }
            }
        }) { image, _, _ in
            completion(image)
        }
    }
}
