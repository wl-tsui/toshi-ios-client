//
//  PrefixHeader.swift
//  Debug
//
//  Created by Ellen Shapiro (Work) on 12/13/17.
//  Copyright © 2017 Bakken&Baeck. All rights reserved.
//

import TinyConstraints
import UIKit

/// A header to support showing a prefix ust be
final class PrefixHeader: UICollectionReusableView {
    
    static let sizingHeader = PrefixHeader(frame: .zero)
    
    private lazy var prefixLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.darkTextColor
        return label
    }()
    
    var prefix: String? {
        get {
            return prefixLabel.text
        }
        set {
            prefixLabel.text = newValue
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Setup
    
    private func setupLabel() {
        addSubview(prefixLabel)
        prefixLabel.edgesToSuperview()
    }
}
