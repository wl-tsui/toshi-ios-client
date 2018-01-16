// Copyright (c) 2018 Token Browser, Inc
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

import TinyConstraints
import SweetUIKit
import UIKit

/// A protocol to centralize the logic of showing the disappearing navigation bar when the user scrolls.
/// NOTE: Almost anything implementing this will want to be a UIScrollViewDelegate.
protocol DisappearingNavBarScrollable: class {
    
    /// The nav bar to adjust
    var navBar: DisappearingBackgroundNavBar { get }
    
    /// The parent view of both the nav bar and the scroll view
    var navAndScrollParent: UIView { get }
    
    /// The height of the navigation bar. Defaults to the class's default height.
    var navBarHeight: CGFloat { get }
    
    /// The height of the top spacer which can be scrolled under the nav bar. Defaults to the nav bar height.
    var topSpacerHeight: CGFloat { get }
    
    /// The scroll view the nav bar should scroll underneath
    var scrollView: UIScrollView { get }
    
    /// The view to use as the trigger to show or hide. When the top of this view crosses the bottom of
    /// of the nav bar when scrolling, the nav bar will show.
    var triggerView: UIView { get }
    
    /// True if a nav bar animation is in progress, false if not
    var navBarAnimationInProgress: Bool { get set }
    
    /// Called when scrollable content should be programmatically added to the given container view.
    /// The size of the views added to the container will determine the scrollable area of the scroll view.
    ///
    /// - Parameter contentView: The content view to add scrollable content to.
    func addScrollableContent(to contentView: UIView)
    
    /// Updates the nav bar's hidden state based on whether the top of the target view has been scrolled past the bottom of the nav bar.
    /// NOTE: This should generally be called from `scrollViewDidScroll`.
    func updateNavBarHiddenState()
}

// MARK: - Default implementation for all types

extension DisappearingNavBarScrollable {
    
    var navBarHeight: CGFloat {
        return DisappearingBackgroundNavBar.defaultHeight
    }
    
    var topSpacerHeight: CGFloat {
        return navBarHeight
    }
}

// MARK: - Default implementation for UIViewControllers

extension DisappearingNavBarScrollable where Self: UIViewController, Self: UIScrollViewDelegate {
    
    var navAndScrollParent: UIView {
        return view
    }
}

// MARK: - Default Implementation for anything conforming to UIScrollViewDelegate

extension DisappearingNavBarScrollable where Self: UIScrollViewDelegate {
    
    /// Sets up the navigation bar and all scrolling content.
    func setupNavBarAndScrollingContent() {
        navAndScrollParent.addSubview(scrollView)
        
        scrollView.edgesToSuperview()
        scrollView.delegate = self
        
        navAndScrollParent.addSubview(navBar)
        
        navBar.edgesToSuperview(excluding: .bottom)
        navBar.height(navBarHeight)

        setupContentView(in: scrollView)
    }
    
    private func setupContentView(in scrollView: UIScrollView) {
        let contentView = UIView(withAutoLayout: false)
        scrollView.addSubview(contentView)
        
        contentView.edgesToSuperview()
        contentView.width(to: scrollView)
        
        addScrollableContent(to: contentView)
    }
    
    /// Adds and returns a spacer view to the top of the scroll view's content view the same height as the nav bar (so content can scroll under it)
    ///
    /// - Parameter contentView: The content view to add the spacer to
    /// - Returns: The spacer view so other views can be constrained to it.
    func addTopSpacer(to contentView: UIView) -> UIView {
        let spacer = UIView(withAutoLayout: false)
        spacer.backgroundColor = Theme.viewBackgroundColor
        contentView.addSubview(spacer)
        spacer.edgesToSuperview(excluding: .bottom)
        spacer.height(topSpacerHeight)
        
        return spacer
    }
    
    func updateNavBarHiddenState() {
        guard !scrollView.frame.equalTo(.zero) else {
            // View hasn't been set up yet
            
            return
        }
        
        guard !navBarAnimationInProgress else {
            // Let the animation finish.
            
            return
        }

        let updatedBounds = triggerView.convert(triggerView.bounds, to: navAndScrollParent)
        let centerYOfTarget = updatedBounds.midY
        
        let shouldBeShowing = (centerYOfTarget < navBarHeight)
        let isShowing = navBar.isBackgroundShowing
        
        guard shouldBeShowing != isShowing else {
            // Nothing more to do here.
            
            return
        }
        
        navBarAnimationInProgress = true
        navBar.showTitleAndBackground(shouldBeShowing, animated: true) { [weak self] _ in
            self?.navBarAnimationInProgress = false
            
            // Update the state one more time in case the user kept scrolling after the animation.
            self?.updateNavBarHiddenState()
        }
    }
}
