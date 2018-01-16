//
//  DisappearingNavBarScrollable.swift
//  Debug
//
//  Created by Ellen Shapiro (Work) on 1/16/18.
//  Copyright © 2018 Bakken&Baeck. All rights reserved.
//

import TinyConstraints
import SweetUIKit
import UIKit

protocol DisappearingNavBarScrollable: class {
    
    /// The nav bar to adjust
    var navBar: DisappearingBackgroundNavBar { get }
    
    /// The parent view of both the nav bar and the scroll view
    var navAndScrollParent: UIView { get }
    
    /// The height of the navigation bar
    var navBarHeight: CGFloat { get }
    
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
    func updateNavBarHiddenState()
}

// MARK: - Default implementation for UIViewControllers

extension DisappearingNavBarScrollable where Self: UIViewController, Self: UIScrollViewDelegate {
    
    var navAndScrollParent: UIView {
        return view
    }
}

// MARK: - Default Implementation for anything conforming to UIScrollViewDelegate

extension DisappearingNavBarScrollable where Self: UIScrollViewDelegate {
    
    var navBarHeight: CGFloat {
        return DisappearingBackgroundNavBar.defaultHeight
    }
    
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
    func addTopSpacerForNavBarHeight(to contentView: UIView) -> UIView {
        let spacer = UIView(withAutoLayout: false)
        contentView.addSubview(spacer)
        spacer.edgesToSuperview(excluding: .bottom)
        spacer.height(navBarHeight)
        
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
