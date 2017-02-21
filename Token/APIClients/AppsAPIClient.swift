import Foundation
import Teapot
import UIKit

class AppsAPIClient {
    static let shared: AppsAPIClient = AppsAPIClient()

    private var teapot: Teapot

    private var imageCache = NSCache<NSString, UIImage>()

    init() {
        self.teapot = Teapot(baseURL: URL(string: "https://token-directory-service.herokuapp.com")!)
    }

    func getApps(completion: @escaping(_ apps: [App], _ error: Error?) -> Void) {
        self.teapot.get("/v1/apps") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                guard let json = json?.dictionary else { fatalError("No apps json!") }

                let appsJSON = json["apps"] as! [[String: Any]]
                let apps = appsJSON.map { json in
                    App(json: json)
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

        Teapot(baseURL: avatarURL).get() { (result: NetworkImageResult) in
            switch result {
            case .success(let image, let response):
                print(response)
                self.imageCache.setObject(image, forKey: path as NSString)
                completion(image)
            case .failure(let response, let error):
                print(response)
                print(error)
                completion(nil)
            }
        }
    }

    func search(_ searchTerm: String, completion: @escaping (_ apps: [App], _ error: Error?) -> Void) {
        guard searchTerm.length > 0 else {
            completion([App](), nil)
            return
        }

        self.teapot.get("/v1/search/apps/?query=\(searchTerm)") { (result: NetworkResult) in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary else { fatalError("No apps json!") }

                guard let appsJSON = json["apps"] as? [[String: Any]] else {
                    completion([App](), nil)
                    return
                }

                let apps = appsJSON.map { json in
                    App(json: json)
                }

                completion(apps, nil)
            case .failure(_, _, let error):
                completion([App](), error)
            }
        }
    }
}
