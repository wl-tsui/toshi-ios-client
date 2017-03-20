import UIKit
import SweetUIKit

typealias Word = String
typealias Words = [Word]
typealias Layout = [NSLayoutConstraint]

protocol AddDelegate {
    func add(_ wordView: BackupPhraseWordView)
}

protocol RemoveDelegate {
    func remove(_ wordView: BackupPhraseWordView)
}

enum BackupPhraseType {
    case original
    case shuffled
    case verification
}

class BackupPhraseView: UIView {
    
    var type: BackupPhraseType = .original
    
    private var words: Words = []
    private var addedWords: Words = []
    private var layout: Layout = []
    
    let margin: CGFloat = 10
    let maxWidth = UIScreen.main.bounds.width - 30
    
    var addDelegate: AddDelegate?
    var removeDelegate: RemoveDelegate?
    
    var wordViews: [BackupPhraseWordView] = []
    var containers: [UILayoutGuide] = []
    
    convenience init(with words: Words, for type: BackupPhraseType) {
        self.init(withAutoLayout: true)
        self.type = type

        self.words = Array(words[0..<12])
        self.wordViews = self.wordViews(for: self.words)
        
        for wordView in self.wordViews {
            self.addSubview(wordView)
        }
        
        switch self.type {
        case .original:
            self.isUserInteractionEnabled = false
            self.addedWords.append(contentsOf: self.words)
            self.activateNewLayout()
        case .shuffled:
            self.words.shuffle()
            self.addedWords.append(contentsOf: self.words)
            self.activateNewLayout()
        case .verification:
            self.backgroundColor = UIColor(white: 0.9, alpha: 1)
            self.layer.cornerRadius = 4
            self.clipsToBounds = true
            self.activateNewLayout()
        }
    }
    
    func add(_ word: Word) {
        self.addedWords.append(word)
        
        self.deactivateLayout()
        self.activateNewLayout()
        self.animateLayout()
        
        self.wordViews.filter { wordView in
            self.addedWords.contains(wordView.word!)
            }.forEach { wordView in
                
                if word == wordView.word {
                    self.sendSubview(toBack: wordView)
                    wordView.alpha = 0
                }
                
                UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOut, animations: {
                    wordView.alpha = 1
                }, completion: nil)
        }
        
    }
    
    func remove(_ word: Word) {
        self.addedWords = self.addedWords.filter { currentWord in
            currentWord != word
        }
        
        self.deactivateLayout()
        self.activateNewLayout()
        self.animateLayout()
        
        self.wordViews.filter { wordView in
            !addedWords.contains(wordView.word!)
            }.forEach { wordView in
                wordView.alpha = 0
        }
    }
    
    func reset(_ word: Word) {
        
        self.wordViews.filter { wordView in
            wordView.word == word
            }.forEach { wordView in
                wordView.isAddedForVerification = false
                wordView.isEnabled = true
                wordView.bounce()
        }
    }
    
    func animateLayout(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .easeOut, animations: {
            self.superview?.layoutIfNeeded()
        }, completion: completion)
    }
    
    func deactivateLayout() {
        NSLayoutConstraint.deactivate(self.layout)
        
        for container in self.containers {
            self.removeLayoutGuide(container)
        }
        
        self.layout.removeAll()
    }
    
    func wordViews(for words: Words) -> [BackupPhraseWordView] {
        
        return words.map { word -> BackupPhraseWordView in
            let wordView = BackupPhraseWordView(with: word)
            wordView.isAddedForVerification = false
            wordView.addTarget(self, action: #selector(toggleAddedState(for:)), for: .touchUpInside)
            
            return wordView
        }
    }
    
    func newContainer(withOffset offset: CGFloat) -> UILayoutGuide {
        let container = UILayoutGuide()
        self.containers.append(container)
        self.addLayoutGuide(container)
        
        self.layout.append(container.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        self.layout.append(container.topAnchor.constraint(equalTo: self.topAnchor, constant: offset))
        
        return container
    }
    
    func addedWordViews() -> [BackupPhraseWordView] {
        var views: [BackupPhraseWordView] = []
        
        for addedWord in self.addedWords {
            for wordView in self.wordViews {
                if let word = wordView.word, word == addedWord {
                    views.append(wordView)
                    
                    if case .verification = self.type {
                        wordView.isAddedForVerification = false
                    }
                }
            }
        }
        
        return views
    }
    
    private func activateNewLayout() {
        var origin = CGPoint(x: 0, y: self.margin)
        var container = self.newContainer(withOffset: origin.y)
        let addedWordViews = self.addedWordViews()
        var previousWordView: UIView?
        
        for wordView in addedWordViews {
            let size = wordView.getSize()
            let newWidth = origin.x + size.width + self.margin
            
            if newWidth > self.maxWidth {
                origin.y += BackupPhraseWordView.height + self.margin
                origin.x = 0
                
                if let previousWordView = previousWordView {
                    self.layout.append(previousWordView.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -self.margin))
                }
                
                container = self.newContainer(withOffset: origin.y)
                
                previousWordView = nil
            }
            
            self.layout.append(wordView.topAnchor.constraint(equalTo: container.topAnchor))
            self.layout.append(wordView.leftAnchor.constraint(equalTo: previousWordView?.rightAnchor ?? container.leftAnchor, constant: self.margin))
            self.layout.append(wordView.bottomAnchor.constraint(equalTo: container.bottomAnchor))
            
            if let lastWordView = addedWordViews.last, lastWordView == wordView {
                self.layout.append(wordView.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -self.margin))
            }
            
            previousWordView = wordView
            origin.x += size.width + self.margin
        }
        
        self.prepareHiddenViews(for: origin)
        
        self.layout.append(container.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -self.margin))
        
        NSLayoutConstraint.activate(self.layout)
    }
    
    func prepareHiddenViews(for origin: CGPoint) {
        guard let lastContainer = containers.last else { return }
        
        self.wordViews.filter { wordView in
            !self.addedWords.contains(wordView.word!)
            }.forEach { wordView in
                wordView.alpha = 0
                
                let size = wordView.getSize()
                let newWidth = origin.x + size.width + self.margin
                
                self.layout.append(wordView.topAnchor.constraint(equalTo: lastContainer.topAnchor, constant: newWidth > self.maxWidth ? BackupPhraseWordView.height + self.margin : 0))
                self.layout.append(wordView.centerXAnchor.constraint(equalTo: lastContainer.centerXAnchor))
        }
    }
    
    func toggleAddedState(for wordView: BackupPhraseWordView) {
        wordView.isAddedForVerification = !wordView.isAddedForVerification
        
        if wordView.isAddedForVerification {
            self.addDelegate?.add(wordView)
            self.removeDelegate?.remove(wordView)
        }
    }
}
