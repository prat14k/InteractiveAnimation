//
//  AnimationViewController.swift
//  InteractiveAnimation
//
//  Created by Prateek Sharma on 6/11/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit


private enum State {
    case expanded
    case collapsed
}

private prefix func !(_ state: State) -> State {
    return state == State.expanded ? .collapsed : .expanded
}

class AnimationViewController: UIViewController {
    
    @IBOutlet private weak var control: UIView!
    @IBOutlet private weak var closedTitleLabel: UILabel!
    @IBOutlet private weak var openTitleLabel: UILabel!
    @IBOutlet private weak var blurEffectView: UIVisualEffectView! {
        didSet {
            blurEffect = blurEffectView.effect
            blurEffectView.effect = nil
        }
    }
    @IBOutlet private weak var controlTopConstraint: NSLayoutConstraint!

    
    private var runningAnimators: UIViewPropertyAnimator?
    
    private var progressWhenInterrupted: CGFloat!
    
    
    private var blurEffect: UIVisualEffect?
    
    private var state: State = .collapsed
    
    lazy private var expandedControlTopMargin: CGFloat = {
        return self.view.bounds.height - 50
    }()
    private let collapsedControlTopMargin: CGFloat = 50
    private let duration: TimeInterval = 1
    

    
    
    @IBAction func handleTap(_ recognizer: UITapGestureRecognizer) {
        animateOrReverseRunningTransition(state: !state, duration: duration)
    }
    
    @IBAction func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: !state, duration: duration)
        case .changed:
            let translation = recognizer.translation(in: view)
            updateInteractiveTransition(distanceTraveled: translation.y)
        case .cancelled, .failed:
            continueInteractiveTransition(cancel: true)
        case .ended:
            let isCancelled = isGestureCancelled(recognizer)
            continueInteractiveTransition(cancel: isCancelled)
        default:
            break
        }
    }
    
    // MARK: - Private
    private func isGestureCancelled(_ recognizer: UIPanGestureRecognizer) -> Bool {
        let isCancelled: Bool
        
        let velocityY = recognizer.velocity(in: view).y
        if velocityY != 0 {
            let isPanningDown = velocityY > 0
            isCancelled = (state == .expanded && isPanningDown) ||
                (state == .collapsed && !isPanningDown)
        }
        else {
            isCancelled = false
        }
        
        return isCancelled
    }
    
    
    private func animateTransitionIfNeeded(state: State, duration: TimeInterval) {
        if runningAnimators == nil {
            self.state = state
            
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1)
            addToRunnningAnimators(frameAnimator) {
                self.updateFrame(for: self.state)
                self.updateBlurView(for: self.state)
                self.updateLabel(for: self.state)
            }
            
        }
        runningAnimators?.scrubsLinearly = false
    }

    private func updateLabelTranslation(for state: State) {
        switch state {
        case .collapsed:
            self.closedTitleLabel.transform = .identity
            self.openTitleLabel.transform = CGAffineTransform(scaleX: 0.65, y: 0.65).concatenating(CGAffineTransform(translationX: 0, y: -15))
        case .expanded:
            self.closedTitleLabel.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).concatenating(CGAffineTransform(translationX: 0, y: 15))
            self.openTitleLabel.transform = .identity
        }
    }


    private func animateOrReverseRunningTransition(state: State, duration: TimeInterval) {
        if runningAnimators == nil {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        else {
            reverseRunningAnimations()
        }
    }
    
    
    private func startInteractiveTransition(state: State, duration: TimeInterval) {
        animateTransitionIfNeeded(state: state, duration: duration)
        
        if let animator = runningAnimators {
            animator.pauseAnimation()
            progressWhenInterrupted = animator.fractionComplete
        }
    }
    
    
    func updateInteractiveTransition(distanceTraveled: CGFloat) {
        let totalAnimationDistance = expandedControlTopMargin - collapsedControlTopMargin
        let fractionComplete = distanceTraveled / totalAnimationDistance
        if let animator = runningAnimators {
            if let progressWhenInterrupted = progressWhenInterrupted {
                let relativeFractionComplete = fractionComplete + progressWhenInterrupted
                
                if (state == .expanded && relativeFractionComplete > 0) ||
                    (state == .collapsed && relativeFractionComplete < 0) {
                    animator.fractionComplete = 0
                }
                else if (state == .expanded && relativeFractionComplete < -1) ||
                    (state == .collapsed && relativeFractionComplete > 1) {
                    animator.fractionComplete = 1
                }
                else {
                    animator.fractionComplete = abs(fractionComplete) + progressWhenInterrupted
                }
            }
        }
    }
    
    
    func continueInteractiveTransition(cancel: Bool) {
        if cancel {
            reverseRunningAnimations()
        }
        
        let timing = UICubicTimingParameters(animationCurve: .easeOut)
        if let animator = runningAnimators {
            animator.continueAnimation(withTimingParameters: timing, durationFactor: 0)
        }
    }
    
    
    
    private func updateFrame(for state: State) {
        switch state {
        case .collapsed:
            controlTopConstraint.constant = collapsedControlTopMargin
        case .expanded:
            controlTopConstraint.constant = expandedControlTopMargin
        }
        
        view.layoutIfNeeded()
    }

    private func updateLabel(for state: State) {
        updateLabelTranslation(for: state)
        switch state {
        case .collapsed:
            self.closedTitleLabel.alpha = 1
            self.openTitleLabel.alpha = 0
        case .expanded:
            self.closedTitleLabel.alpha = 0
            self.openTitleLabel.alpha = 1
        }
    }
    
    
    
    private func updateBlurView(for state: State) {
        switch state {
        case .collapsed:
            blurEffectView.effect = nil
        case .expanded:
            blurEffectView.effect = blurEffect
        }
    }
    
    private func addToRunnningAnimators(_ animator: UIViewPropertyAnimator,
                                        animation: @escaping () -> Void) {
        animator.addAnimations {
            animation()
        }
        animator.addCompletion {
            _ in
            self.runningAnimators = nil
            
            animation()
        }
        
        animator.startAnimation()
        runningAnimators = animator
    }
    
    private func reverseRunningAnimations() {
        if let animator = runningAnimators {
            animator.isReversed = !animator.isReversed
        }
        
        state = !state
    }
}
