//
//  DismissBlurAnimator.m
//  xFonts
//
//  Created by manolo on 1/26/17.
//  Copyright © 2017 manolo. All rights reserved.
//

#import "DismissBlurAnimator.h"
#import "HelpViewController.h"

@implementation DismissBlurAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
	return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	UIViewController *fromController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIView *container = [transitionContext containerView];
	
	UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
	[container addSubview:toView];
	
	[UIView animateWithDuration:0.3 animations:^{
		((HelpViewController*)fromController).blurView.effect = nil;
	} completion:^(BOOL finished) {
		[transitionContext completeTransition:finished];
	}];
}

@end
