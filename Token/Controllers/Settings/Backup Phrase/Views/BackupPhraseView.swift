import UIKit
import SweetUIKit

typealias Word = String
typealias Words = [Word]


protocol AddDelegate {
    func add(_ wordView: BackupPhraseWordView)
}

protocol RemoveDelegate {
    func remove(_ wordView: BackupPhraseWordView)
}


class BackupPhraseView: UIView {
    
    private var words: Words = []
    let maxWidth = UIScreen.main.bounds.width - 30
    
    var addDelegate: AddDelegate?
    var removeDelegate: RemoveDelegate?
    
    var wordViews: [BackupPhraseWordView] = []
    var wordViewsContainers: [UIView] = []
    
    convenience init(with words: Words?) {
        self.init(withAutoLayout: true)
        
        if let words = words {
            self.words = words
            self.addWordViews()
        }
    }
    
    func add(_ word: Word) {
        self.words.append(word)
        
        self.removeAllSubviews()
        self.addWordViews()
    }
    
    func remove(_ word: Word) {
        self.words = self.words.filter { currentWord in
            currentWord != word
        }
        
        self.removeAllSubviews()
        self.addWordViews()
    }
    
    func reset(_ word: Word) {
        
        self.wordViews.filter { wordView in
            wordView.word == word
            }.forEach { wordView in
                wordView.isAddedForVerification = false
                wordView.isEnabled = true
        }
    }
    
    private func removeAllSubviews() {
        
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
        
        self.wordViewsContainers.removeAll()
    }
    
    func wordViews(for words: Words) -> [BackupPhraseWordView] {
        
        return words.map { word -> BackupPhraseWordView in
            let wordView = BackupPhraseWordView(with: word)
            wordView.isAddedForVerification = false
            wordView.addTarget(self, action: #selector(toggleAddedState(for:)), for: .touchUpInside)
            
            return wordView
        }
    }
    
    func newContainer(withOffset offset: CGFloat) -> UIView {
        let container = UIView(withAutoLayout: true)
        self.wordViewsContainers.append(container)
        self.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            container.topAnchor.constraint(equalTo: self.topAnchor, constant: offset)
            ])
        
        return container
    }
    
    private func addWordViews() {
        let margin: CGFloat = 10
        var origin = CGPoint(x: 0, y: margin)
        
        self.wordViews = self.wordViews(for: self.words)
        
        var container = self.newContainer(withOffset: origin.y)
        var previousWordView: UIView?
        
        for wordView in self.wordViews {
            let size = wordView.getSize()
            let newWidth = origin.x + size.width + margin
            
            if newWidth > self.maxWidth {
                origin.y += BackupPhraseWordView.height + margin
                origin.x = 0
                
                previousWordView?.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -margin).isActive = true
                
                container = self.newContainer(withOffset: origin.y)
                
                previousWordView = nil
            }
            
            container.addSubview(wordView)
            
            wordView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            wordView.leftAnchor.constraint(equalTo: previousWordView?.rightAnchor ?? container.leftAnchor, constant: margin).isActive = true
            wordView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
            
            if let lastWordView = self.wordViews.last, lastWordView == wordView {
                wordView.rightAnchor.constraint(equalTo: container.rightAnchor, constant: -margin).isActive = true
            }
            
            previousWordView = wordView
            
            origin.x += size.width + margin
        }
        
        container.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -margin).isActive = true
    }
    
    func toggleAddedState(for wordView: BackupPhraseWordView) {
        wordView.isAddedForVerification = !wordView.isAddedForVerification
        
        if wordView.isAddedForVerification {
            self.addDelegate?.add(wordView)
            self.removeDelegate?.remove(wordView)
        }
    }
}
