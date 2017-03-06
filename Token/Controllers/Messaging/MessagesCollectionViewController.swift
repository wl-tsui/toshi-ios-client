import UIKit
import NoChat

class MessagesCollectionViewController: NOCChatViewController {

    var buttons: [SofaMessage.Button] = [] {
        didSet {
            // Ensure we're dealing with layout inside the main queue.
            DispatchQueue.main.async {
                self.controlsViewHeightConstraint.constant = self.view.frame.height
                self.controlsViewDelegateDatasource.items = self.buttons.reversed()
                self.controlsView.reloadData()

                // Re-enqueues this back to the main queue to ensure the collection view
                // has filled in its cells. Thanks UIKit. 
                DispatchQueue.main.async {
                    var height: CGFloat = 0
                    for cell in self.controlsView.visibleCells {
                        height = max(height, cell.frame.maxY)
                    }

                    self.controlsViewHeightConstraint.constant = height
                    // if topY is different from 0, add 16pt margin.
                    // TODO: clean this up
                    self.additionalContentInsets.bottom = height == 0 ? 0 : (height + 16)
                }
            }
        }
    }

    lazy var controlsViewDelegateDatasource: ControlsViewDelegateDatasource = {
        let controlsViewDelegateDatasource = ControlsViewDelegateDatasource()
        controlsViewDelegateDatasource.actionDelegate = self

        return controlsViewDelegateDatasource
    }()

    lazy var controlsViewHeightConstraint: NSLayoutConstraint = {
        return self.controlsView.heightAnchor.constraint(equalToConstant: self.view.frame.height)
    }()

    lazy var controlsView: ControlsCollectionView = {
        let view = ControlsCollectionView()

        // Upside down collection views!
        view.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        view.register(ControlCell.self)
        view.delegate = self.controlsViewDelegateDatasource
        view.dataSource = self.controlsViewDelegateDatasource

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.controlsView)

        self.controlsViewHeightConstraint.isActive = true
        self.controlsView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16).isActive = true
        self.controlsView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16).isActive = true
        self.controlsView.bottomAnchor.constraint(equalTo: self.inputPanel!.topAnchor, constant: -16).isActive = true

        self.controlsViewDelegateDatasource.controlsCollectionView = self.controlsView
    }
}

extension MessagesCollectionViewController: ControlViewActionDelegate {
    func controlsCollectionViewDidSelectControl(at index: Int) {
        let button = self.buttons[index]
        print("Did tap \(button.label)")
    }
}
