import Foundation
import UIKit
import TinyConstraints
import SweetUIKit

final class ProfilesHeaderView: UIView {
    
    private let searchBar: UISearchBar?

    required init(with searchBar: UISearchBar? = nil) {
        self.searchBar = searchBar
        super.init(frame: .zero)
                
        if #available(iOS 11, *) {
            // Search bar should already be set up
            width(UIScreen.main.bounds.width)
        } else {
            frame = CGRect(origin: .zero, size: (searchBar?.frame.size ?? .zero))
            addSearchBar(searchBar)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSearchBar(_ searchBar: UISearchBar?) {
        guard let searchBar = searchBar else {
            assertionFailure("Search bar should be passed in for iOS 10!")
            
            return
        }
        
        searchBar.frame.origin = .zero
        
        // Note: Autolayout does not play nicely with the search bar.
        addSubview(searchBar)
    }
}
