import UIKit

final public class PaymentNavigationController: UINavigationController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.barStyle = .default
        navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navigationBar.shadowImage = UIImage()
        
        let titleTextAttributes: [NSAttributedStringKey: Any] = [
            .font: Theme.preferredRegular(),
            .foregroundColor: Theme.darkTextColor
        ]
        
        navigationBar.titleTextAttributes = titleTextAttributes
    }
}
