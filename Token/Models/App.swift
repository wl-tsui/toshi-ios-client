import Foundation
import UIKit

struct App {
    let displayName: String
    let avatarURL: URL?
    let image: UIImage?
    var category: String
    var ranking: Int?

    init(json: [String: Any]) {
        self.displayName = json["username"] as! String
        self.avatarURL = URL(string: json["avatar"] as? String ?? "")
        self.image = nil
        self.category = "Unknown"
    }

    init(displayName: String, image: UIImage) {
        self.displayName = displayName
        self.image = image
        self.avatarURL = nil
        self.category = "Unknown"
    }
}
