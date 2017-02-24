//
//  PresentationBlurAnimator.m
//  xFonts
//
//  Created by manolo on 1/26/17.
//  Copyright © 2017 manolo. All rights reserved.
//

#import "PresentationBlurAnimator.h"
#import "HelpViewController.h"

@implementation PresentationBlurAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
	return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	UIViewController *toController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	UIView *container = [transitionContext containerView];
	
	[container addSubview:toController.view];
	
	((HelpViewController*)toController).blurView.effect = nil;
	
	[UIView animateWithDuration:0.3 animations:^{
		((HelpViewController*)toController).blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	} completion:^(BOOL finished) {
		[transitionContext completeTransition:finished];
	}];
}

@end
