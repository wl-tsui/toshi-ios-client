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

class DisappearingBackgroundNavBarViewController: UIViewController, DisappearingBackgroundNavBarDelegate {

    /// If disappearing is enabled at present.
    var disappearingEnabled: Bool {
        return true
    }

    var navBarHeight: CGFloat = DisappearingBackgroundNavBar.defaultHeight

    /// The height of the top spacer which can be scrolled under the nav bar. Defaults to the nav bar height.
    var topSpacerHeight: CGFloat {
        return navBarHeight
    }

    /// The view to use as the trigger to show or hide the background.
    var backgroundTriggerView: UIView {
        fatalError("Must be overridden by subclass")
    }

    /// The view to use as the trigger to show or hide the title.
    var titleTriggerView: UIView {
        fatalError("Must be overridden by subclass")
    }

    /// The nav bar to adjust
    lazy var navBar: DisappearingBackgroundNavBar = {
        let navBar = DisappearingBackgroundNavBar(delegate: self)
        navBar.setupLeftAsBackButton()

        return navBar
    }()

    lazy var scrollView = UIScrollView()

    private var navBarTargetHeight: CGFloat {
        if #available(iOS 11, *) {
            return view.safeAreaInsets.top + DisappearingBackgroundNavBar.defaultHeight
        } else {
            return DisappearingBackgroundNavBar.defaultHeight
        }
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBarAndScrollingContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
        // Even though the nav bar is hidden, keep the pop gesture recognizer working
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        updateNavBarHeightIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: animated)

        super.viewWillDisappear(animated)
    }

    // MARK: - View Setup

    /// Sets up the navigation bar and all scrolling content.
    /// NOTE: Should be set up before any other views are added to the Nav + Scroll parent or there's some weirdness with the scroll view offset.
    func setupNavBarAndScrollingContent() {
        view.addSubview(scrollView)

        scrollView.delegate = self
        scrollView.edgesToSuperview()

        view.addSubview(navBar)

        navBar.edgesToSuperview(excluding: .bottom)
        updateNavBarHeightIfNeeded()
        navBar.heightConstraint = navBar.height(navBarHeight)

        setupContentView(in: scrollView)
    }

    private func setupContentView(in scrollView: UIScrollView) {
        let contentView = UIView(withAutoLayout: false)
        scrollView.addSubview(contentView)

        contentView.edgesToSuperview()
        contentView.width(to: scrollView)

        addScrollableContent(to: contentView)
    }

    func updateNavBarHeightIfNeeded() {
        guard navBarHeight != navBarTargetHeight else { /* we're good */ return }

        guard
            let heightConstraint = navBar.heightConstraint,
            heightConstraint.constant != navBarTargetHeight
            else { return }

        navBarHeight = navBarTargetHeight
        heightConstraint.constant = navBarHeight
    }

    /// Updates the state of the nav bar based on where the target views are in relation to the bottom of the nav bar.
    /// NOTE: This should generally be called from `scrollViewDidScroll`.
    func updateNavBar() {
        guard disappearingEnabled else { return }
        guard !scrollView.frame.equalTo(.zero) else { /* View hasn't been set up yet. */ return }

        updateBackgroundAlpha()
        updateTitleAlpha()
    }

    private func updateBackgroundAlpha() {
        let targetInParentBounds = backgroundTriggerView.convert(backgroundTriggerView.bounds, to: view)
        let topOfTarget = targetInParentBounds.minY
        let centerOfTarget = targetInParentBounds.midY

        let differenceFromTop = navBarHeight - topOfTarget
        let differenceFromCenter = navBarHeight - centerOfTarget

        if differenceFromCenter > 0 {
            navBar.setBackgroundAlpha(1)
        } else if differenceFromTop < 0 {
            navBar.setBackgroundAlpha(0)
        } else {
            let betweenTopAndCenter = centerOfTarget - topOfTarget
            let percentage = differenceFromTop / betweenTopAndCenter
            navBar.setBackgroundAlpha(percentage)
        }
    }

    private func updateTitleAlpha() {
        let targetInParentBounds = titleTriggerView.convert(titleTriggerView.bounds, to: view)
        let centerOfTarget = targetInParentBounds.midY
        let bottomOfTarget = targetInParentBounds.maxY
        let threeQuartersOfTarget = (centerOfTarget + bottomOfTarget) / 2

        let differenceFromThreeQuarters = navBarHeight - threeQuartersOfTarget
        let differenceFromBottom = navBarHeight - bottomOfTarget

        if differenceFromBottom > 0 {
            navBar.setTitleAlpha(1)
            navBar.setTitleOffsetPercentage(from: 1)
        } else if differenceFromThreeQuarters < 0 {
            navBar.setTitleAlpha(0)
            navBar.setTitleOffsetPercentage(from: 0)
        } else {
            let betweenThreeQuartersAndBottom = bottomOfTarget - threeQuartersOfTarget
            let percentageComplete = differenceFromThreeQuarters / betweenThreeQuartersAndBottom
            navBar.setTitleAlpha(percentageComplete)
            navBar.setTitleOffsetPercentage(from: percentageComplete)
        }
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

    /// Called when scrollable content should be programmatically added to the given container view.
    /// The size of the views added to the container will determine the scrollable area of the scroll view.
    ///
    /// - Parameter contentView: The content view to add scrollable content to.
    func addScrollableContent(to contentView: UIView) {
        assertionFailure("Subclasses must override and not call super")
    }

    // MARK: - Disappearing Background Nav Bar Delegate
    //Note: These are in the main class so they can be overridden

    func didTapRightButton(in navBar: DisappearingBackgroundNavBar) {
        assertionFailure("If you want this to do something, override it in the subclass")
    }

    func didTapLeftButton(in navBar: DisappearingBackgroundNavBar) {
        assertionFailure("If you want this to do something, override it in the subclass")
    }
}

// MARK: - Scroll View Delegate

extension DisappearingBackgroundNavBarViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavBar()
    }
}

// MARK: - Gesture Recognizer Delegate

extension DisappearingBackgroundNavBarViewController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // This is overridden to allow the pop gesture to be recognized.
        return true
    }
}
