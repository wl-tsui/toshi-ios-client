import Foundation
import AwesomeCache
import Teapot
import UIKit

public class AppsAPIClient: NSObject, CacheExpiryDefault {
    static let shared: AppsAPIClient = AppsAPIClient()

    private var teapot: Teapot

    private var imageCache = try! Cache<UIImage>(name: "appImageCache")

    override init() {
        self.teapot = Teapot(baseURL: URL(string: TokenDirectoryServiceBaseURLPath)!)
    }

    func getFeaturedApps(completion: @escaping (_ apps: [TokenContact], _ error: Error?) -> Void) {
        self.teapot.get("/v1/apps/featured") { (result: NetworkResult) in
            switch result {
            case .success(let json, let response):
                print(response)
                guard let json = json?.dictionary else { fatalError("No apps json!") }

                let appsJSON = json["results"] as! [[String: Any]]
                let apps = appsJSON.map { json -> TokenContact in
                    let app = TokenContact(json: json)
                    app.isApp = true

                    return app
                }

                completion(apps, nil)
            case .failure(let json, let response, let error):
                print(json ?? "")
                print(response)
                completion([TokenContact](), error)
            }
        }
    }

    func downloadImage(for app: TokenContact, completion: @escaping (_ image: UIImage?) -> Void) {
        guard let pathURL = URL(string: app.avatarPath) else { return }
        self.imageCache.setObject(forKey: app.avatarPath, cacheBlock: { success, failure in
            Teapot(baseURL: pathURL).get { (result: NetworkImageResult) in
                switch result {
                case .success(let image, let response):
                    print(response)
                    success(image, self.cacheExpiry)
                case .failure(let response, let error):
                    print(response)
                    print(error)
                    failure(error as NSError)
                }
            }
        }) { image, _, _ in
            completion(image)
        }
    }

    func search(_ searchTerm: String, completion: @escaping (_ apps: [TokenContact], _ error: Error?) -> Void) {
        guard searchTerm.length > 0 else {
            completion([TokenContact](), nil)
            return
        }

        self.teapot.get("/v1/search/apps/?query=\(searchTerm)") { (result: NetworkResult) in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary else {
                    completion([], nil)

                    return
                }

                guard let appsJSON = json["results"] as? [[String: Any]] else {
                    completion([TokenContact](), nil)
                    return
                }

                let apps = appsJSON.map { json -> TokenContact in
                    let app = TokenContact(json: json)
                    app.isApp = true

                    return app
                }

                completion(apps, nil)
            case .failure(_, _, let error):
                completion([TokenContact](), error)
            }
        }
    }
}
