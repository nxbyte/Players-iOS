/*
 Developer : Warren Seto
 Classes   : SlideUpTransition
 Project   : Players App (v2)
 */

import UIKit

final class SlideUpTransition: UIPresentationController, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    
    internal var dimmingView: UIView?,
                    presentationWrappingView: UIView?
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?)
    {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        presentedViewController.modalPresentationStyle = .custom
    }
    
    override var presentedView : UIView? {
        return self.presentationWrappingView
    }
    
    override func presentationTransitionWillBegin() {
        
        presentationWrappingView = {
            $0.layer.shadowOpacity = 0.6
            $0.layer.shadowRadius = 10.0
            $0.layer.shadowOffset = CGSize(width: 0, height: -6.0)
            return $0
        } (UIView(frame: self.frameOfPresentedViewInContainerView))
        
        let roundedView : UIView = {
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            $0.layer.cornerRadius = 8
            $0.layer.masksToBounds = true
            return $0
        } (UIView(frame: UIEdgeInsetsInsetRect(presentationWrappingView!.bounds, UIEdgeInsets(top: 0, left: 0, bottom: -8, right: 0))))
        
        
        let wrapView : UIView = {
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return $0
        } (UIView(frame: UIEdgeInsetsInsetRect(roundedView.bounds, UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0))))
        
        
        let presentedViewControllerView = super.presentedView!
        presentedViewControllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentedViewControllerView.frame = wrapView.bounds
        wrapView.addSubview(presentedViewControllerView)
        
        roundedView.addSubview(wrapView)
        
        presentationWrappingView!.addSubview(roundedView)
        
        let dimView:UIView = {
            $0.backgroundColor = .darkText
            $0.isOpaque = false
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped(_:))))
            return $0
        } (UIView(frame: self.containerView?.bounds ?? CGRect()))
        
        self.dimmingView = dimView
        self.containerView?.addSubview(dimView)
        self.dimmingView?.alpha = 0.0
        
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            
            self.dimmingView?.alpha = 0.4
            
        }, completion: nil)
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            self.presentationWrappingView = nil
            self.dimmingView = nil
        }
    }
    
    override func dismissalTransitionWillBegin() {
        
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { context in
            
            self.dimmingView?.alpha = 0.0
            
        }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        
        if completed {
            self.presentationWrappingView = nil
            self.dimmingView = nil
        }
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        if container === self.presentedViewController {
            self.containerView?.setNeedsLayout()
        }
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        if container === self.presentedViewController {
            return (container as! UIViewController).preferredContentSize
        } else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
    }
    
    override var frameOfPresentedViewInContainerView : CGRect {
        let containerViewBounds = self.containerView?.bounds ?? CGRect()
        
        let presentedViewContentSize = self.size(forChildContentContainer: self.presentedViewController, withParentContainerSize: containerViewBounds.size)
        
        var presentedViewControllerFrame = containerViewBounds
        presentedViewControllerFrame.size.height = presentedViewContentSize.height
        presentedViewControllerFrame.origin.y = containerViewBounds.maxY - presentedViewContentSize.height
        
        return presentedViewControllerFrame
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        
        self.dimmingView?.frame = self.containerView?.bounds ?? CGRect()
        self.presentationWrappingView?.frame = self.frameOfPresentedViewInContainerView
    }
    
    @objc func dimmingViewTapped(_ sender: UITapGestureRecognizer) {
        self.presentingViewController.dismiss(animated: true, completion: nil)
    }
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionContext?.isAnimated ?? false ? 0.4 : 0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let startVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        var startVCFinalFrame = transitionContext.finalFrame(for: startVC)
        
        let endVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!,
        endVCFinalFrame = transitionContext.finalFrame(for: endVC)
        
        let toView = transitionContext.view(forKey: UITransitionContextViewKey.to),
        fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
        containerView = transitionContext.containerView,
        isPresenting = (startVC === self.presentingViewController)
        
        if (toView != nil)
        {
            containerView.addSubview(toView!)
        }
        
        if isPresenting {
            
            var toViewInitialFrame = transitionContext.initialFrame(for: endVC)
            toViewInitialFrame.origin = CGPoint(x: containerView.bounds.minX, y: containerView.bounds.maxY)
            toViewInitialFrame.size = endVCFinalFrame.size
            
            toView?.frame = toViewInitialFrame
        }
        else {
            startVCFinalFrame = (fromView?.frame ?? CGRect()).offsetBy(dx: 0, dy: (fromView?.frame ?? CGRect()).height)
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: isPresenting ? 7.0 : 0.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            if isPresenting {
                toView?.frame = endVCFinalFrame
            } else {
                fromView?.frame = startVCFinalFrame
            }
            
        }, completion: { finished in
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        assert(self.presentedViewController === presented, "You didn't initialize \(self) with the correct presentedViewController.  Expected \(presented), got \(self.presentedViewController).")
        
        return self
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}
