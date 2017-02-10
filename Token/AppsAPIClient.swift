import Foundation
import Networking
import UIKit

class AppsAPIClient {
    static let shared: AppsAPIClient = AppsAPIClient()

    private var networking: Networking
    private var imageNetworking: Networking

    init() {
        self.networking = Networking(baseURL: "https://token-directory-service.herokuapp.com")
        self.imageNetworking = Networking(baseURL: "http://icons.iconarchive.com")
    }

    func getApps(completion: @escaping(_ apps: [App], _ error: Error?) -> Void) {
        self.networking.get("/v1/apps") { result in
            switch result {
            case .success(let response):
                let json = response.dictionaryBody

                var apps = [App]()
                let appsJSON = json["apps"] as! [[String: Any]]
                for appJSON in appsJSON {
                    apps.append(App(json: appJSON))
                }

                completion(apps, nil)
            case .failure(let response):
                completion([App](), response.error)
            }
        }
    }

    func downloadImage(for app: App, completion: @escaping(_ result: ImageResult) -> Void) {
        if let avatarURL = app.avatarURL {
            let (_, path) = Networking.splitBaseURLAndRelativePath(for: avatarURL)
            self.imageNetworking.downloadImage(path, completion: completion)
        }
    }
}
