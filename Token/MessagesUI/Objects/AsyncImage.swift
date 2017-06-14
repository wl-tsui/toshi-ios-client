import Foundation
import UIKit

typealias AsyncImageCompletion = (UIImage?) -> Void

extension UIImageView {

    func setImage(from url: AsyncImageURL, withPlaceholder placeholder: UIImage? = nil) {

        if let image = url.cachedImage {
            self.image = image
            return
        }

        self.image = placeholder

        url.fetchImage { image in
            if let image = image {
                self.image = image
            } else {
                url.downloadImage { image in
                    self.image = image
                }
            }
        }
    }
}

struct AsyncImageURL {
    let url: URL
    var task: URLSessionDataTask?

    init(url: URL) {
        self.url = url
    }
}

extension AsyncImageURL {

    var imageName: String {
        let lastPathComponent = url.deletingPathExtension().lastPathComponent
        return lastPathComponent.substring(from: lastPathComponent.index(lastPathComponent.startIndex, offsetBy: 0))
    }

    var cachedImage: UIImage? {
        return ImageCache.shared.object(forKey: imageName as NSString)
    }

    func prefetchImage() {
        if self.cachedImage == nil {
            self.fetchImage { image in
                if image == nil {
                    self.downloadImage { _ in }
                }
            }
        }
    }

    func fetchImage(_ completion: @escaping AsyncImageCompletion) {

        DispatchQueue.global(qos: .userInteractive).async {
            ImageStorage(in: "images").fetch(self.imageName) { image in
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
    }

    func downloadImage(_ completion: @escaping AsyncImageCompletion) {

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }

            ImageCache.shared.setObject(image, forKey: self.imageName as NSString, cost: data.count)
            ImageStorage(in: "images").save(image, fileName: self.imageName)

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }

    func cancelImage() {
        task?.cancel()
    }

    func removeImage() {
        ImageCache.shared.removeObject(forKey: imageName as NSString)
        ImageStorage(in: "images").remove(fileName: self.imageName)
    }
}

struct ImageStorage {
    let system = FileManager.default
    let folder: String
    let path: URL

    init(in folder: String) {
        self.folder = folder
        self.path = try! self.system.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        try? self.system.createDirectory(at: self.path.appendingPathComponent(folder), withIntermediateDirectories: true, attributes: nil)
    }

    func fetchAllImages() -> [UIImage]? {
        guard let files = try? system.contentsOfDirectory(at: path.appendingPathComponent(folder), includingPropertiesForKeys: nil), files.count > 0 else { return nil }
        return files.flatMap { file in try? Data(contentsOf: file) }.flatMap { data in UIImage(data: data) }
    }

    func fetch(_ imageName: String, completion: @escaping AsyncImageCompletion) {
        guard let files = try? system.contentsOfDirectory(at: path.appendingPathComponent(folder), includingPropertiesForKeys: nil), files.count > 0 else {
            completion(nil)
            return
        }
        guard let image = files.map({ file in AsyncImageURL(url: file) }).filter({ url in url.imageName == imageName }).flatMap({ url in try? Data(contentsOf: url.url) }).flatMap({ data in UIImage(data: data) }).last else {
            completion(nil)
            return
        }

        completion(image)

        guard let data = UIImagePNGRepresentation(image) else { return }
        ImageCache.shared.setObject(image, forKey: imageName as NSString, cost: data.count)
    }

    func save(_ image: UIImage, fileName: String) {
        let data = UIImagePNGRepresentation(image)
        try? data?.write(to: self.path.appendingPathComponent(self.folder).appendingPathComponent(fileName))
    }

    func remove(fileName: String) {
        let url = self.path.appendingPathComponent(self.folder).appendingPathComponent(fileName)
        try? self.system.removeItem(at: url)
    }
}

class ImageCache {

    private static let maxSizeInMegaBytes = 50 * 1024 * 1024
    private static let maxNumberOfImages = 20

    static let shared: NSCache = { () -> NSCache<NSString, UIImage> in
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = maxSizeInMegaBytes
        cache.countLimit = maxNumberOfImages

        return cache
    }()
}
