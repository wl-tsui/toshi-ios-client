//
//  DappViewController.swift
//  Debug
//
//  Created by Ellen Shapiro (Work) on 12/19/17.
//  Copyright © 2017 Bakken&Baeck. All rights reserved.
//

import SweetUIKit
import UIKit
import TinyConstraints

final class DappViewController: UIViewController {
    
    private let dapp: Dapp
    
    // MARK: Views
    
    private lazy var avatarImageView = AvatarImageView()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.preferredDisplayName()
        label.textAlignment = .center
        
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var urlLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.lightGreyTextColor

        return label
    }()
    
    private lazy var enterButton: ActionButton = {
        let button = ActionButton(margin: .defaultMargin)
        button.title = Localized("dapp_button_enter")
        button.addTarget(self,
                         action: #selector(didTapEnterButton(_:)),
                         for: .touchUpInside)
        
        return button
    }()
    
    // MARK: Non-computed properties for DisappearingNavBarScrollable
    
    var navBarAnimationInProgress: Bool = false
    
    lazy var navBar: DisappearingBackgroundNavBar = {
        let navBar = DisappearingBackgroundNavBar(delegate: self)
        navBar.setupLeftAsBackButton()
        
        return navBar
    }()
    
    lazy var scrollView = UIScrollView()
    
    // MARK: - Initialization
    
    required init(with dapp: Dapp) {
        self.dapp = dapp
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = Theme.viewBackgroundColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarAndScrollingContent()
        configure(for: dapp)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    // MARK: - View setup
    
    private func setupPrimaryStackView(in containerView: UIView, below viewToPinToBottomOf: UIView) {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .vertical
        
        let margin = CGFloat.defaultMargin
        
        containerView.addSubview(stackView)
        stackView.topToBottom(of: viewToPinToBottomOf)
        stackView.leftToSuperview(offset: margin)
        stackView.rightToSuperview(offset: margin)
        stackView.bottomToSuperview()
        
        stackView.addWithCenterConstraint(view: avatarImageView)
        avatarImageView.height(.defaultAvatarHeight)
        avatarImageView.width(.defaultAvatarHeight)
        stackView.addSpacing(margin, after: avatarImageView)

        stackView.addWithDefaultConstraints(view: titleLabel)
        stackView.addSpacing(.giantInterItemSpacing, after: titleLabel)
        
        stackView.addWithDefaultConstraints(view: descriptionLabel)
        stackView.addSpacing(.mediumInterItemSpacing, after: descriptionLabel)
        
        stackView.addWithDefaultConstraints(view: urlLabel)
        stackView.addSpacing(.largeInterItemSpacing, after: urlLabel)
        
        stackView.addWithDefaultConstraints(view: enterButton, margin: margin)
        enterButton.heightConstraint.constant = .defaultButtonHeight
        
        stackView.addSpacerView(with: .largeInterItemSpacing)
    }
    
    // MARK: - Configuration
    
    private func configure(for dapp: Dapp) {
        navBar.setTitle(dapp.name)
        titleLabel.text = dapp.name
        descriptionLabel.text = dapp.description
        
        //TODO: Remove temp for loop
        for _ in 0..<3 {
            descriptionLabel.text = descriptionLabel.text! + "\n\n\(dapp.description)"
        }
        
        urlLabel.text = dapp.url.absoluteString
        
        AvatarManager.shared.avatar(for: dapp.avatarUrlString, completion: { [weak self] image, _ in
            self?.avatarImageView.image = image
        })
    }
    
    // MARK: - Action Targets
    
    @objc private func didTapEnterButton(_ sender: UIButton) {
        let sofaWebController = SOFAWebController()
        sofaWebController.load(url: dapp.url)
        
        navigationController?.pushViewController(sofaWebController, animated: true)
        preferLargeTitleIfPossible(false)
    }
}

extension DappViewController: DisappearingNavBarScrollable {
    
    var triggerView: UIView {
        return avatarImageView
    }
    
    func addScrollableContent(to contentView: UIView) {
        let spacer = addTopSpacer(to: contentView)
        setupPrimaryStackView(in: contentView, below: spacer)
    }
}

extension DappViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavBarHiddenState()
    }
}

extension DappViewController: DisappearingBackgroundNavBarDelegate {
    
    func didTapLeftButton(in navBar: DisappearingBackgroundNavBar) {
        navigationController?.popViewController(animated: true)
    }
    
    func didTapRightButton(in navBar: DisappearingBackgroundNavBar) {
        assertionFailure("Nothing should be happening here")
    }
}
