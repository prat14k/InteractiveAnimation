//
//  AnimationViewController.swift
//  InteractiveAnimation
//
//  Created by Prateek Sharma on 6/11/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit


class AnimationViewController: UIViewController {
    
    private let duration: TimeInterval = 1
    var closedDrawerTitleScale: CGFloat!
    var closedDrawerTitleTranslation: CGFloat!
    
    private var viewPropertyAnimator: UIViewPropertyAnimator?
    private var progressWhenInterrupted: CGFloat!
    private var blurEffect: UIVisualEffect?
    private var state: DrawerState = .collapsed
    
    
    @IBOutlet private weak var controlTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var closedTitleLabel: UILabel!
    @IBOutlet private weak var openTitleLabel: UILabel! {
        didSet {
            openTitleLabel.alpha = 0
        }
    }
    @IBOutlet private weak var blurEffectView: UIVisualEffectView! {
        didSet {
            blurEffect = blurEffectView.effect
            blurEffectView.effect = nil
        }
    }
    @IBOutlet private weak var drawer: UIView! {
        didSet {
            drawer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            drawer.layer.cornerRadius = 0
            drawer.layer.masksToBounds = true
        }
    }
    
    
    lazy private var expandedControlTopMargin: CGFloat = {
        return drawer.bounds.height
    }()
    private let collapsedControlTopMargin: CGFloat = 50
    
}

    
extension AnimationViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        calculationForTitleReshaping()
        setOpenDrawerTitleInitialState()
    }
    
    
    func setOpenDrawerTitleInitialState(){
        openTitleLabel.transform = CGAffineTransform(scaleX: closedDrawerTitleScale, y: closedDrawerTitleScale).concatenating(CGAffineTransform(translationX: 0, y: -closedDrawerTitleTranslation))
    }
    
    
    func calculationForTitleReshaping() {
        closedDrawerTitleScale = closedTitleLabel.bounds.height / openTitleLabel.bounds.height
        closedDrawerTitleTranslation = (openTitleLabel.frame.origin.y - (closedTitleLabel.frame.origin.y - ((openTitleLabel.bounds.height - closedTitleLabel.bounds.height) / 2)))
    }
    
}

extension AnimationViewController {
    
    @IBAction private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: !state, duration: duration)
        case .changed:
            let translation = recognizer.translation(in: view)
            updateInteractiveTransition(distanceTraveled: translation.y)
        case .cancelled, .failed:
            continueInteractiveTransition(cancel: true)
        case .ended:
            continueInteractiveTransition(cancel: false)
        default: break
        }
    }
    
    private func startInteractiveTransition(state: DrawerState, duration: TimeInterval) {
        animateTransitionIfNeeded(state: state, duration: duration)
        guard let animator = viewPropertyAnimator  else { return }
        animator.pauseAnimation()
        progressWhenInterrupted = animator.fractionComplete
    }
    
    private func animateTransitionIfNeeded(state: DrawerState, duration: TimeInterval) {
        if viewPropertyAnimator == nil {
            self.state = state
            let transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1)
            setAnimationsAndCompletion(to: transitionAnimator) { [weak self] in
                guard let weakSelf = self  else { return }
                weakSelf.updateConstraints(for: weakSelf.state)
                weakSelf.updateBlurView(for: weakSelf.state)
                weakSelf.updateLabel(for: weakSelf.state)
                weakSelf.updateCornerRadius(for: weakSelf.state)
            }
        }
    }
    
    
    private func setAnimationsAndCompletion(to animator: UIViewPropertyAnimator, animation: @escaping () -> Void) {
        animator.addAnimations {
            animation()
        }
        animator.addCompletion { [weak self] _ in
            self?.viewPropertyAnimator = nil
            animation()
        }
        
        animator.startAnimation()
        viewPropertyAnimator = animator
    }
    
    
    private func updateInteractiveTransition(distanceTraveled: CGFloat) {
        guard let animator = viewPropertyAnimator, let progressWhenInterrupted = progressWhenInterrupted  else { return }
        let totalAnimationDistance = expandedControlTopMargin - collapsedControlTopMargin
        let fractionComplete = distanceTraveled / totalAnimationDistance
        let relativeFractionComplete = fractionComplete + progressWhenInterrupted
        
        if (state == .expanded && relativeFractionComplete > 0) || (state == .collapsed && relativeFractionComplete < 0) {
            animator.fractionComplete = 0
        } else if (state == .expanded && relativeFractionComplete < -1) || (state == .collapsed && relativeFractionComplete > 1) {
            animator.fractionComplete = 1
        } else {
            animator.fractionComplete = abs(fractionComplete) + progressWhenInterrupted
        }
    }
    
    private func continueInteractiveTransition(cancel: Bool) {
        cancel ? reverseRunningAnimations() : ()
        guard let animator = viewPropertyAnimator  else { return }
        let timing = UICubicTimingParameters(animationCurve: .easeOut)
        animator.continueAnimation(withTimingParameters: timing, durationFactor: 0)
    }

}


extension AnimationViewController {

    @IBAction private func handleTap(_ recognizer: UITapGestureRecognizer) {
        animateOrReverseRunningTransition(state: !state, duration: duration)
    }
    
    private func animateOrReverseRunningTransition(state: DrawerState, duration: TimeInterval) {
        if viewPropertyAnimator == nil {
            animateTransitionIfNeeded(state: state, duration: duration)
        } else {
            reverseRunningAnimations()
        }
    }
    
    private func reverseRunningAnimations() {
        if let animator = viewPropertyAnimator {
            animator.isReversed = !animator.isReversed
        }
        state = !state
    }
}


extension AnimationViewController {
    
    private func updateLabel(for state: DrawerState) {
        updateLabelTransition(for: state)
        (closedTitleLabel.alpha, openTitleLabel.alpha) = state == .collapsed ? (1, 0) : (0, 1)
    }
    
    private func updateLabelTransition(for state: DrawerState) {
        switch state {
        case .collapsed:
            closedTitleLabel.transform = .identity
            openTitleLabel.transform = CGAffineTransform(scaleX: closedDrawerTitleScale, y: closedDrawerTitleScale).concatenating(CGAffineTransform(translationX: 0, y: -closedDrawerTitleTranslation))
        case .expanded:
            closedTitleLabel.transform = CGAffineTransform(scaleX: 1/closedDrawerTitleScale, y: 1/closedDrawerTitleScale).concatenating(CGAffineTransform(translationX: 0, y: closedDrawerTitleTranslation))
            openTitleLabel.transform = .identity
        }
    }
    
    private func updateConstraints(for state: DrawerState) {
        controlTopConstraint.constant = state == .collapsed ? collapsedControlTopMargin : expandedControlTopMargin
        view.layoutIfNeeded()
    }
    
    private func updateCornerRadius(for state: DrawerState) {
        drawer.layer.cornerRadius = state.cornerRadius
    }

    
    private func updateBlurView(for state: DrawerState) {
        blurEffectView.effect = state == .collapsed ? nil : blurEffect
    }
    
}
