import Foundation
import UIKit

struct App {
    let displayName: String
    let avatarURL: String?
    let image: UIImage?
    var category: String
    var ranking: Int?

    init(json: [String: Any]) {
        self.displayName = json["displayName"] as! String
        self.avatarURL = json["avatarUrl"] as? String
        self.image =  nil
        self.category = "Unknown"
    }

    init(displayName: String, image: UIImage) {
        self.displayName = displayName
        self.image = image
        self.avatarURL =  nil
        self.category = "Unknown"
    }
}
