import Foundation
import Teapot
import UIKit

class AppsAPIClient {
    static let shared: AppsAPIClient = AppsAPIClient()

    private var teapot: Teapot

    private var imageTeapot: Teapot

    private var imageCache = NSCache<NSString, UIImage>()

    init() {
        self.teapot = Teapot(baseURL: URL(string: "https://token-directory-service.herokuapp.com")!)
        self.imageTeapot = Teapot(baseURL: URL(string: "http://icons.iconarchive.com")!)
    }

    func getApps(completion: @escaping(_ apps: [App], _ error: Error?) -> Void) {
        self.teapot.get("/v1/apps") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                guard let json = json?.dictionary else { fatalError("No apps json!") }

                var apps = [App]()
                let appsJSON = json["apps"] as! [[String: Any]]
                for appJSON in appsJSON {
                    apps.append(App(json: appJSON))
                }

                completion(apps, nil)
            case .failure(let json, let response, let error):
                print(json ?? "")
                print(response)
                completion([App](), error)
            }
        }
    }

    func downloadImage(for app: App, completion: @escaping(_ image: UIImage?) -> Void) {
        guard let avatarURL = app.avatarURL else { return }

        let path = avatarURL.path
        if let image = self.imageCache.object(forKey: path as NSString) {
            completion(image)

            return
        }

        self.imageTeapot.get(path) { (result: NetworkImageResult) in
            switch result {
            case .success(let image, _):
                self.imageCache.setObject(image, forKey: path as NSString)
                completion(image)
            case .failure(_, let error):
                print(error)
                completion(nil)
            }
        }
    }
}
