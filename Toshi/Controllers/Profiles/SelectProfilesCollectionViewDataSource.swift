// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import SweetUIKit
import UIKit

protocol ProfileSearchDelegate: class {
    
    // Called when the user has entered text to search for a username
    func enteredText(_ text: String?)
}

// MARK: - Select Profiles Collection View Data Source

/// Data source for type-ahead header allowing selection of users similar to iMessage
final class SelectProfilesCollectionViewDataSource: NSObject {
    
    private enum SelectProfilesSection: Int, CountableIntEnum {
        case
        alreadySelectedProfiles,
        textEntry
    }
    
    private let headerPrefix = "To:"
    
    private(set) var selectedProfiles = [TokenUser]()
    
    private weak var collectionView: UICollectionView?
    private weak var searchDelegate: ProfileSearchDelegate?
    
    private var currentlySelectedProfile: TokenUser?
    private weak var textField: UITextField?
    
    private var cachedHeaderSize: CGSize?
    
    init(with collectionView: UICollectionView, searchDelegate: ProfileSearchDelegate) {
        super.init()
        self.searchDelegate = searchDelegate
        self.collectionView = collectionView
        
        collectionView.register(UserNameCell.self)
        collectionView.register(PrefixHeader.self, ofKind: UICollectionElementKindSectionHeader)
        collectionView.register(TextInputCell.self)
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    // MARK: - Updating
    
    func update(with selectedProfiles: [TokenUser]) {
        self.selectedProfiles = selectedProfiles
        collectionView?.reloadData()
        collectionView?.invalidateIntrinsicContentSize()
    }
}

// MARK: - Collection View Data Source

extension SelectProfilesCollectionViewDataSource: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return SelectProfilesSection.AllCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch SelectProfilesSection.forIndex(section) {
        case .alreadySelectedProfiles:
            return selectedProfiles.count
        case .textEntry:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch SelectProfilesSection.forIndex(indexPath.section) {
        case .alreadySelectedProfiles:
            return profileCellAtIndexPath(indexPath, in: collectionView)
        case .textEntry:
            return cellForTextInput(in: collectionView)
        }
    }
        
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeue(PrefixHeader.self, ofKind: UICollectionElementKindSectionHeader, for: indexPath) else {
            fatalError("No prefix header for you!")
        }
        header.prefix = headerPrefix
        
        return header
    }
    
    private func cellForTextInput(in collectionView: UICollectionView) -> TextInputCell {
        let inputIndexPath = IndexPath(item: 0, section: SelectProfilesSection.textEntry.rawValue)
        
        let cell = collectionView.dequeue(TextInputCell.self, for: inputIndexPath)
        
        cell.textField.delegate = self
        textField = cell.textField
        
        return cell
    }

    private func profileCellAtIndexPath(_ indexPath: IndexPath, in collectionView: UICollectionView) -> UserNameCell {
        let profile = selectedProfiles[indexPath.row]
        let name = profile.nameOrDisplayName
        
        let cell = collectionView.dequeue(UserNameCell.self, for: indexPath)
        cell.name = name
        
        return cell
    }
}

// MARK: - Collection View Delegate

extension SelectProfilesCollectionViewDataSource: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch SelectProfilesSection.forIndex(indexPath.section) {
        case .alreadySelectedProfiles:
            currentlySelectedProfile = selectedProfiles[indexPath.row]
        case .textEntry:
            textField?.becomeFirstResponder()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        switch SelectProfilesSection.forIndex(indexPath.section) {
        case .alreadySelectedProfiles:
            currentlySelectedProfile = nil
        case .textEntry:
            //TODO: Figure out what needs to be done here
            break
        }
    }
}

// MARK: - Collection View Delegate for Flow Layout

extension SelectProfilesCollectionViewDataSource: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch SelectProfilesSection.forIndex(indexPath.section) {
        case .alreadySelectedProfiles:
            let sizingCell = UserNameCell.sizingCell
            let profile = self.selectedProfiles[indexPath.row]
            sizingCell.name = profile.nameOrDisplayName
            
            return sizingCell.layoutAndPredictSize(for: .compressed)
        case .textEntry:
            let sizingCell = TextInputCell.sizingCell
            sizingCell.textField.text = textField?.text
            
            return sizingCell.layoutAndPredictSize(for: .compressed)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section == SelectProfilesSection.alreadySelectedProfiles.rawValue else { return .zero }
        
        if let headerSize = cachedHeaderSize {
            
            return headerSize
        } else {
            let sizingHeader = PrefixHeader.sizingHeader
            sizingHeader.prefix = headerPrefix
            let headerSize = sizingHeader.layoutAndPredictSize(for: .compressed)
            cachedHeaderSize = headerSize
            
            return headerSize
        }
    }
}

// MARK: - Text Field Delegate

extension SelectProfilesCollectionViewDataSource: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updatedText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        searchDelegate?.enteredText(updatedText)
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let margin: CGFloat = 16
        return UIEdgeInsets(top: margin,
                            left: margin,
                            bottom: -margin,
                            right: -margin)
    }
}

// MARK: - Text Field Delete Delegate

extension SelectProfilesCollectionViewDataSource: TextFieldDeleteDelegate {
    
    func backspacedOnEmptyField() {
        // TODO: deselect most recently selected and put it in the text field
    }
    
}
