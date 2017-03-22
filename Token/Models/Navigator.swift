import UIKit

public class Navigator: NSObject {
    private let navigator = Navigator()

    // Navigation assumes the following structure:
    // TabBar controller contains a messages controller. Messages controller lists chats, and pushes threads.
    public static func navigate(to threadIdentifier: String, animated: Bool) {
        // make sure we don't do UI stuff in a background thread
        DispatchQueue.main.async {
            // get tab controller
            guard let tabController = UIApplication.shared.delegate?.window??.rootViewController as? TabBarController else { return }

            tabController.switch(to: .messaging)
            tabController.messagingController.popToRootViewController(animated: animated)
            tabController.messagingController.openThread(withThreadIdentifier: threadIdentifier, animated: animated)
        }
    }
}
