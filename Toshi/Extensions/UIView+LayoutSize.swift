//
//  UIView+LayoutSize.swift
//  Debug
//
//  Created by Ellen Shapiro (Work) on 12/13/17.
//  Copyright © 2017 Bakken&Baeck. All rights reserved.
//

import UIKit

// MARK: - Layout Size

// Wraps `UILayoutFitting` in an enum since those are returned as CGSizes rather than enum values.
enum LayoutSize {
    case
    compressed,
    expanded
    
    // The system value represented by the current case
    var systemSize: CGSize {
        switch self {
        case .compressed:
            return UILayoutFittingCompressedSize
        case .expanded:
            return UILayoutFittingExpandedSize
        }
    }
}

// MARK: - UIView Extension

extension UIView {
    
    /// Uses autolayout to configure the view, then determines its predicted size.
    /// Particularly useful for offscreen "sizing" UICollectionView cells.
    ///
    /// - Parameter for: The system layout size to fit.
    /// - Returns: The predicted layout size for the laid out view
    func layoutAndPredictSize(for layoutSize: LayoutSize) -> CGSize {
        self.setNeedsLayout()
        self.layoutIfNeeded()
        return self.systemLayoutSizeFitting(layoutSize.systemSize)
    }
}
