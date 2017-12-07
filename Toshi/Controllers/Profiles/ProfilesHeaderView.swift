import Foundation
import UIKit
import TinyConstraints
import SweetUIKit

final class ProfilesHeaderView: UIView {
    
    private let type: ProfilesViewControllerType
    private let searchBar: UISearchBar?
    private(set) var addedHeader: ProfilesAddedToGroupHeader?
    
    required init(with searchBar: UISearchBar? = nil, type: ProfilesViewControllerType, delegate: ProfilesAddGroupHeaderDelegate?) {
        self.type = type
        self.searchBar = searchBar
        super.init(frame: .zero)
        
        width(UIScreen.main.bounds.width)
        configure(for: type, with: delegate, searchBar: searchBar)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(for type: ProfilesViewControllerType, with delegate: ProfilesAddGroupHeaderDelegate?, searchBar: UISearchBar?) {
        switch type {
        case .favorites:
            if #available(iOS 11, *) {
                // Do nothing, search bar should already be set up
            } else {
                height(searchBar?.frame.height ?? 0)
                addSearchBar(searchBar, bottomPinnedTo: nil)
            }
        case .newChat:
            let addGroupHeader = ProfilesAddGroupHeader(with: delegate)
            addSubview(addGroupHeader)
            
            let groupHeaderHeight: CGFloat = 70
            
            if #available(iOS 11, *) {
                height(groupHeaderHeight)
                addGroupHeader.edgesToSuperview()
            } else {
                height(groupHeaderHeight + (searchBar?.frame.height ?? 0))
                addSearchBar(searchBar, bottomPinnedTo: addGroupHeader)
                addGroupHeader.edgesToSuperview(excluding: .top)
            }
        case .newGroupChat:
            let addedToGroupHeader = ProfilesAddedToGroupHeader(margin: 16)
            addSubview(addedToGroupHeader)
            addedHeader = addedToGroupHeader
            
            if #available(iOS 11, *) {
                addedToGroupHeader.edgesToSuperview()
            } else {
                addSearchBar(searchBar, bottomPinnedTo: addedToGroupHeader)
                addedToGroupHeader.edgesToSuperview(excluding: .top)
            }
        }
    }
    
    private func addSearchBar(_ searchBar: UISearchBar?, bottomPinnedTo view: UIView?) {
        guard let searchBar = searchBar else {
            assertionFailure("Search bar should be passed in for iOS 10!")
            
            return
        }
        
        addSubview(searchBar)
        
        if let viewToPinTo = view {
            searchBar.edgesToSuperview(excluding: .bottom)
            searchBar.bottomToTop(of: viewToPinTo)
        } else {
            searchBar.edgesToSuperview()
        }
    }
}
