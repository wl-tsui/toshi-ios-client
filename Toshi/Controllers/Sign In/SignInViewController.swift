import Foundation
import UIKit
import TinyConstraints

final class SignInViewController: UIViewController {

    fileprivate var signInView: SignInView? { return view as? SignInView }
    fileprivate var typed: [String] = [""]
    fileprivate var itemCount: Int = 1
    static let maxItemCount: Int = 12
    fileprivate var shouldDeselectWord = false

    var activeIndexPath: IndexPath? {
        guard let selectedCell = signInView?.collectionView.visibleCells.first(where: { $0.isSelected }) else { return nil }
        return signInView?.collectionView.indexPath(for: selectedCell)
    }

    var activeCell: SignInCell? {
        guard let activeIndexPath = activeIndexPath else { return nil }
        return signInView?.collectionView.cellForItem(at: activeIndexPath) as? SignInCell
    }

    var passwords: [String]? = nil {
        didSet {
            signInView?.collectionView.reloadData()
        }
    }

    override func loadView() {
        view = SignInView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false

        signInView?.collectionView.delegate = self
        signInView?.collectionView.dataSource = self
        signInView?.textField.delegate = self
        signInView?.textField.deleteDelegate = self

        loadPasswords { [weak self] in
            self?.passwords = $0
            self?.signInView?.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .top)
        }

        signInView?.footerView.explanationButton.addTarget(self, action: #selector(showExplanation(_:)), for: .touchUpInside)
        signInView?.footerView.signInButton.addTarget(self, action: #selector(signIn(_:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        signInView?.textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        signInView?.textField.resignFirstResponder()
    }
    
    @objc private func showExplanation(_ button: UIButton) {
        let explanationViewController = SignInExplanationViewController()
        navigationController?.pushViewController(explanationViewController, animated: true)
    }

    @objc private func signIn(_ button: ActionButton) {
        guard let collectionView = signInView?.collectionView else { return }

        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: false)
        }

        let indexPaths = collectionView.indexPathsForVisibleItems.sorted {$0.item < $1.item}
        let cells = indexPaths.flatMap { collectionView.cellForItem(at: $0) as? SignInCell }
        let passphrase = cells.flatMap { $0.match }

        signInWithPasshphrase(passphrase)
    }

    private func signInWithPasshphrase(_ passphrase: [String]) {
        
        guard let cereal = Cereal(words: passphrase) else {
            let alertController = UIAlertController.dismissableAlert(title: Localized("passphrase_signin_error_title"), message: Localized("passphrase_signin_error_verification"))
            present(alertController, animated: true)

            return
        }

        Cereal.shared = cereal

        let idClient = IDAPIClient.shared
        idClient.retrieveUser(username: cereal.address) { [weak self] user in
            if let user = user {

                UserDefaults.standard.set(false, forKey: RequiresSignIn)

                TokenUser.createCurrentUser(with: user.dict)
                idClient.migrateCurrentUserIfNeeded()

                TokenUser.current?.updateVerificationState(true)

                ChatAPIClient.shared.registerUser()

                guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
                delegate.signInUser()

                self?.navigationController?.dismiss(animated: true, completion: nil)
            } else {
                let alertController = UIAlertController.dismissableAlert(title: Localized("passphrase_signin_error_title"), message: Localized("passphrase_signin_error_verification"))
                self?.present(alertController, animated: true)
            }
        }
    }

    private func loadPasswords(_ completion: @escaping ([String]) -> Void) {
        guard let path = Bundle.main.path(forResource: "passwords-library", ofType: "txt") else { return }
        
        do {
            let data = try String(contentsOfFile: path, encoding: .utf8)
            completion(data.components(separatedBy: .newlines))
        } catch {
            fatalError("Can't load data from file.")
        }
    }

    fileprivate func libraryComparison(for text: String) -> (match: String?, isSingleOccurrence: Bool) {
        guard !text.isEmpty else { return (nil, false) }

        let filtered = passwords?.filter {
            $0.range(of: text, options: [.caseInsensitive, .anchored]) != nil
        }

        return (filtered?.first, filtered?.count == 1)
    }

    fileprivate func acceptItem(at indexPath: IndexPath, completion: ((Bool) -> Swift.Void)? = nil) {
        signInView?.textField.text = nil

        let newIndexPath = IndexPath(item: itemCount, section: 0)
        UIView.performWithoutAnimation {
            addItem(at: newIndexPath, completion: { [weak self] _ in
                UIView.performWithoutAnimation {
                    self?.cleanUp(after: newIndexPath, completion: { [weak self] _ in
                        guard let itemCount = self?.itemCount else { return }
                        let newIndexPath = IndexPath(item: itemCount - 1, section: 0)
                        self?.signInView?.collectionView.selectItem(at: newIndexPath, animated: false, scrollPosition: .top)
                        UIView.performWithoutAnimation {
                            self?.cleanUp(after: newIndexPath, completion: completion)
                        }
                    })
                }
            })
        }
    }

    fileprivate func addItem(at indexPath: IndexPath, completion: ((Bool) -> Swift.Void)? = nil) {

        if itemCount == SignInViewController.maxItemCount, let activeIndexPath = activeIndexPath {
            signInView?.collectionView.deselectItem(at: activeIndexPath, animated: false)
            
            cleanUp(after: IndexPath(item: SignInViewController.maxItemCount, section: 0), completion: { [weak self] _ in
                guard let itemCount = self?.itemCount, itemCount < SignInViewController.maxItemCount else { return }
                self?.acceptItem(at: IndexPath(item: SignInViewController.maxItemCount, section: 0))
            })
            
            return
        }

        UIView.animate(withDuration: 0) {
            self.signInView?.collectionView.performBatchUpdates({
                self.signInView?.collectionView.insertItems(at: [indexPath])
                self.itemCount += 1
                self.typed.append("")
            }, completion: { finished in
                self.signInView?.layoutIfNeeded()
                completion?(finished)
            })
        }
    }

    fileprivate func cleanUp(after indexPath: IndexPath, completion: ((Bool) -> Swift.Void)? = nil) {

        UIView.animate(withDuration: 0) {
            self.signInView?.collectionView.performBatchUpdates({
                self.signInView?.collectionView.indexPathsForVisibleItems.forEach {

                    if $0 != indexPath, let string = self.typed.element(at: $0.item), string.isEmpty {
                        self.typed.remove(at: $0.item)
                        self.signInView?.collectionView.deleteItems(at: [$0])
                        self.itemCount -= 1
                    }
                }
            }, completion: { finished in
                self.signInView?.layoutIfNeeded()
                completion?(finished)
            })
        }
    }
}

extension SignInViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let activeIndexPath = activeIndexPath, indexPath == activeIndexPath else { return true }
        
        shouldDeselectWord = true
        acceptItem(at: indexPath, completion: { [weak self] _ in
            guard let indexPath = self?.activeIndexPath else { return }
            self?.cleanUp(after: indexPath)
        })
        
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if let cell = activeCell, !shouldDeselectWord {
            signInView?.textField.text = cell.text
            cleanUp(after: indexPath)
        } else if itemCount == SignInViewController.maxItemCount, let activeIndexPath = activeIndexPath {
            signInView?.collectionView.deselectItem(at: activeIndexPath, animated: false)
        }

        shouldDeselectWord = false
    }
}

extension SignInViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SignInCell.reuseIdentifier, for: indexPath)

        if let cell = cell as? SignInCell {
            cell.setText(typed[indexPath.item], isFirstAndOnly: itemCount == 1)
        }

        return cell
    }
}

extension SignInViewController: UITextFieldDelegate {

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let indexPath = activeIndexPath else { return false }
        guard let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else { return false }

        if string == " " || string == "\n" {
            acceptItem(at: indexPath)

            return false
        }

        typed[indexPath.item] = text
        
        let comparison = libraryComparison(for: text)
        
        if let match = comparison.match {
            activeCell?.setText(text, with: match)
            
            if comparison.isSingleOccurrence {
                acceptItem(at: indexPath)
                return false
            }
        } else {
            activeCell?.setText(text, isFirstAndOnly: itemCount == 1)
        }
        
        signInView?.collectionView.collectionViewLayout.invalidateLayout()
        signInView?.layoutIfNeeded()
        
        return true
    }
}

extension SignInViewController: TextFieldDeleteDelegate {

    func backspacedOnEmptyField() {
        guard let indexPath = activeIndexPath, indexPath.item != 0 else { return }

        let newIndexPath = IndexPath(item: indexPath.item - 1, section: 0)
        signInView?.collectionView.selectItem(at: newIndexPath, animated: false, scrollPosition: .top)

        if let cell = activeCell {
            signInView?.textField.text = cell.text
        }

        cleanUp(after: newIndexPath)
    }
}
