import UIKit
import NoChat

class MessagesCollectionViewController: NOCChatViewController {

    enum DisplayState {
        case hide
        case show
        case hideAndShow
        case doNothing
    }

    var buttons: [SofaMessage.Button] = [] {
        didSet {
            // Ensure we're dealing with layout inside the main queue.
            DispatchQueue.main.async {
                self.controlsView.isHidden = true
                self.updateSubcontrols(with: nil)
                self.controlsViewHeightConstraint.constant = self.view.frame.height
                self.controlsViewDelegateDatasource.items = self.buttons.reversed()
                self.controlsView.reloadData()

                // Re-enqueues this back to the main queue to ensure the collection view
                // has filled in its cells. Thanks UIKit.
                DispatchQueue.main.asyncAfter(seconds: 0.1) {
                    var height: CGFloat = 0
                    (self.controlsView.visibleCells as? [ControlCell])?.forEach{ (cell) in
                        height = max(height, cell.frame.maxY)
                    }

                    self.controlsViewHeightConstraint.constant = 0
                    self.view.layoutIfNeeded()

                    self.additionalContentInsets.bottom = height
                    self.controlsViewHeightConstraint.constant = height
                    self.controlsView.isHidden = false
                    UIView.animate(withDuration: 0.15) {
                        self.view.layoutIfNeeded()
                    }
                }
            }
        }
    }

    lazy var controlsViewDelegateDatasource: ControlsViewDelegateDatasource = {
        let controlsViewDelegateDatasource = ControlsViewDelegateDatasource()
        controlsViewDelegateDatasource.actionDelegate = self

        return controlsViewDelegateDatasource
    }()

    lazy var subcontrolsViewDelegateDatasource: SubcontrolsViewDelegateDatasource = {
        let subcontrolsViewDelegateDatasource = SubcontrolsViewDelegateDatasource()
        subcontrolsViewDelegateDatasource.actionDelegate = self

        return subcontrolsViewDelegateDatasource
    }()

    lazy var controlsViewHeightConstraint: NSLayoutConstraint = {
        return self.controlsView.heightAnchor.constraint(equalToConstant: self.view.frame.height)
    }()

    lazy var subcontrolsViewHeightConstraint: NSLayoutConstraint = {
        return self.subcontrolsView.heightAnchor.constraint(equalToConstant: self.view.frame.height)
    }()

    lazy var subcontrolsViewWidthConstraint: NSLayoutConstraint = {
        return self.subcontrolsView.widthAnchor.constraint(equalToConstant: self.view.frame.width)
    }()

    lazy var controlsView: ControlsCollectionView = {
        let view = ControlsCollectionView()

        view.clipsToBounds = true

        // Upside down collection views!
        view.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        view.register(ControlCell.self)
        view.delegate = self.controlsViewDelegateDatasource
        view.dataSource = self.controlsViewDelegateDatasource

        return view
    }()

    lazy var subcontrolsView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.layer.borderColor = Theme.borderColor.cgColor
        view.layer.borderWidth = 1.0


        // Upside down collection views!
        view.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        view.register(SubcontrolCell.self)
        view.delegate = self.subcontrolsViewDelegateDatasource
        view.dataSource = self.subcontrolsViewDelegateDatasource

        return view
    }()

    var currentButton: SofaMessage.Button?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.controlsView)
        self.view.addSubview(self.subcontrolsView)

        // menus
        self.subcontrolsViewHeightConstraint.isActive = true
        self.subcontrolsViewWidthConstraint.isActive = true
        self.subcontrolsView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16).isActive = true
        self.subcontrolsView.bottomAnchor.constraint(equalTo: self.controlsView.topAnchor, constant: -16).isActive = true

        self.subcontrolsViewDelegateDatasource.subcontrolsCollectionView = self.subcontrolsView

        // buttons
        self.controlsViewHeightConstraint.isActive = true
        self.controlsView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 16).isActive = true
        self.controlsView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -16).isActive = true
        self.controlsView.bottomAnchor.constraint(equalTo: self.inputPanel!.topAnchor, constant: -6).isActive = true

        self.controlsViewDelegateDatasource.controlsCollectionView = self.controlsView

        self.hideSubcontrolsMenu()
    }

    func didTapControlButton(_ button: SofaMessage.Button) {
        // to be implemented by subclass
    }


    // TODO: simplify and better document?
    // also more testing.
    func displayState(for button: SofaMessage.Button?) -> DisplayState {
        if let button = button, let currentButton = self.currentButton {
            if button == currentButton {
                return .hide
            } else {
                return .hideAndShow
            }
        }

        if button == nil && self.currentButton == nil {
            return .doNothing
        } else if button == nil && self.currentButton != nil {
            return .hide
        } else { //  if button != nil && self.currentButton == nil
            return .show
        }
    }
}

extension MessagesCollectionViewController: ControlViewActionDelegate {
    func controlsCollectionViewDidSelectControl(_ button: SofaMessage.Button) {
        switch button.type {
        case .button:
            self.didTapControlButton(button)
        case .group:
            self.updateSubcontrols(with: button)
        }
    }

    func updateSubcontrols(with button: SofaMessage.Button?) {
        switch self.displayState(for: button) {
        case .show:
            self.showSubcontrolsMenu(button: button!)
        case .hide:
            self.hideSubcontrolsMenu()
        case .hideAndShow:
            self.hideSubcontrolsMenu {
                self.showSubcontrolsMenu(button: button!)
            }
        case .doNothing:
            break
        }
    }

    func hideSubcontrolsMenu(completion: (() -> Void)? = nil) {
        self.subcontrolsViewDelegateDatasource.items = []
        self.currentButton = nil

        // ✨ Animate that beauty in! ✨
        self.subcontrolsViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.15, animations: {
            self.view.layoutIfNeeded()
        }, completion: { success in
            self.subcontrolsView.backgroundColor = .clear

            completion?()
        })
    }

    func showSubcontrolsMenu(button: SofaMessage.Button, completion: (() -> Void)? = nil) {
        // ensure we have enough height to fill in all the views
        self.subcontrolsViewHeightConstraint.constant = self.view.frame.height
        // ensure we won't be flashing unfinished content
        self.subcontrolsView.isHidden = true

        let controlCell = SubcontrolCell(frame: .zero)
        var maxWidth: CGFloat = 0.0

        // gets width of widest cell
        button.subcontrols.forEach { button in
            controlCell.button.setTitle(button.label, for: .normal)
            let bounds = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 38)
            maxWidth = max(maxWidth, controlCell.button.titleLabel!.textRect(forBounds: bounds, limitedToNumberOfLines: 1).width + controlCell.buttonInsets.left + controlCell.buttonInsets.right)
        }

        // reverse the order of the buttons because the collection view is upside-down
        self.subcontrolsViewDelegateDatasource.items = button.subcontrols.reversed()
        // adds some margins
        self.subcontrolsViewWidthConstraint.constant = maxWidth
        self.currentButton = button

        self.subcontrolsView.reloadData()

        // Re-enqueues this back to the main queue to ensure the collection view
        // has filled in its cells. Thanks UIKit.
        DispatchQueue.main.asyncAfter(seconds: 0.1) {
            var height: CGFloat = 0

            // calculates the new menu height
            for cell in self.subcontrolsView.visibleCells {
                height += cell.frame.height
            }

            // let's prepare for animating! First set the height to 0.
            self.subcontrolsViewHeightConstraint.constant = 0
            // reset the background colour to the design.
            self.subcontrolsView.backgroundColor = Theme.viewBackgroundColor
            // force it to update it's size with 0 height.
            // also remember that layoutIfNeeded is called on the superview.
            self.view.layoutIfNeeded()
            // now that it's too small to see, we can unset hidden
            self.subcontrolsView.isHidden = false
            
            // ✨ Animate that beauty in! ✨
            self.subcontrolsViewHeightConstraint.constant = height
            UIView.animate(withDuration: 0.15) {
                self.view.layoutIfNeeded()

                completion?()
            }
        }
    }
}
