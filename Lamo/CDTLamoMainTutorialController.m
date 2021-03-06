//
//  CDTLamoMainTutorialController.m
//  Lamo
//
//  Created by Ethan Arbuckle on 6/27/15.
//  Copyright © 2015 CortexDevTeam. All rights reserved.
//

#import "CDTLamoMainTutorialController.h"

@interface CDTLamoMainTutorialController ()

@end

@implementation CDTLamoMainTutorialController

- (id)init {
    
    if (self = [super init]) {
        
        [[self view] setBackgroundColor:[UIColor clearColor]];
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
        
        //create blur
        //_UIBackdropView *blur = [(_UIBackdropView *)[NSClassFromString(@"_UIBackdropView") alloc] initWithStyle:1];
       // [[self view] addSubview:blur];
        
        
        //create instruction label
        UILabel *instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, kScreenWidth - 20, 100)];
        [instructionLabel setTextColor:[UIColor whiteColor]];
        [instructionLabel setTextAlignment:NSTextAlignmentCenter];
        [instructionLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:20]];
        [instructionLabel setNumberOfLines:0];
        [instructionLabel setText:@"Drag down and release from the top left corner to invoke a window"];
        [[self view] addSubview:instructionLabel];
        
        //create homescreen preview + gesture holding view
        SBHomeScreenPreviewView *homePreview = [NSClassFromString(@"SBHomeScreenPreviewView") preview];
        UIView *gestureView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 20)];
        [homePreview addSubview:gestureView];
        [gestureView setBackgroundColor:[UIColor lightGrayColor]];
        [gestureView setAlpha:0.1];
        [gestureView setUserInteractionEnabled:YES];
        [homePreview setTransform:CGAffineTransformMakeScale(.8, .8)];
        [homePreview setFrame:CGRectMake((kScreenWidth / 2) - ((kScreenWidth * .8) / 2), 200, kScreenWidth, kScreenHeight)];
        [[homePreview subviews][1] removeFromSuperview];
        [homePreview setClipsToBounds:YES];
        [[self view] addSubview:homePreview];
        
        //create preview window
        _windowPreview = [[CDTLamoWindow alloc] init];
        [_windowPreview setFrame:CGRectMake(0, -20, kScreenWidth, kScreenHeight + 20)];
        [_windowPreview setBackgroundColor:[UIColor darkGrayColor]];
        [_windowPreview setUserInteractionEnabled:YES];
        
        //add it behind status bar of homescreenview
        [homePreview insertSubview:_windowPreview atIndex:1];
        
        //remove statusbar
        [[homePreview subviews][2] removeFromSuperview];
        
        //create bar view
        CDTLamoBarView *bar = [[CDTLamoBarView alloc] init];
        [bar setFrame:CGRectMake(0, 0, kScreenWidth, 20)];
        if (NEED_IPAD_HAX) {
            [bar setTitle:@"Maps"];
        }
        else {
            [bar setTitle:@"Weather"];
        }
        [(CDTLamoWindow *)_windowPreview setBarView:bar];
        [_windowPreview addSubview:bar];
        
        //create weather context view
        _contextProvider = [[CDTContextHostProvider alloc] init];
        UIView *contextView;
        if (NEED_IPAD_HAX) {
            contextView = [_contextProvider hostViewForApplicationWithBundleID:@"com.apple.Maps"];
            [_contextProvider setStatusBarHidden:@(1) onApplicationWithBundleID:@"com.apple.Maps"];
        }
        else {
            contextView = [_contextProvider hostViewForApplicationWithBundleID:@"com.apple.weather"];
            [_contextProvider setStatusBarHidden:@(1) onApplicationWithBundleID:@"com.apple.weather"];
        }
        [contextView setFrame:CGRectMake(0, 20, kScreenWidth, kScreenHeight)];
        [_windowPreview addSubview:contextView];
        
        //create pan gesture
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [gestureView addGestureRecognizer:panGesture];
        
        //create animating view
        _animatingView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 205, 40, 40)];
        [_animatingView setImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Lamo/Hand.png"]];
        [[self view] addSubview:_animatingView];
        
        //start animating
        [self animateHelperViewDown];
    }
    
    return self;
}

- (void)addBarButtons {
    
    //these need to be made outside of init so we have a navcontroller set
    //create close button
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(closeTutorial)];
    [[self navigationItem] setRightBarButtonItem:closeButton];
    [[self navigationItem] setHidesBackButton:YES];
}

- (void)closeTutorial {
    
    //animate it out
    [UIView animateWithDuration:0.3 animations:^{
        
        [[[CDTLamo sharedInstance] tutorialWindow] setAlpha:0];
        
    } completion:^(BOOL finished) {
        
        //remove it
        [[[self navigationController] view] removeFromSuperview];
        [[[CDTLamo sharedInstance] tutorialWindow] setHidden:YES];
        [[CDTLamo sharedInstance] setTutorialWindow:NULL];
        [_windowPreview setHidden:YES];
        _windowPreview = NULL;
        
    }];
    
    //stop hosting
    if (NEED_IPAD_HAX) {
        [_contextProvider stopHostingForBundleID:@"com.apple.Maps"];
    }
    else {
        [_contextProvider stopHostingForBundleID:@"com.apple.weather"];
    }
    
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    
    if ([gesture state] == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture locationInView:[[gesture view] superview]];
        if (translation.x <= 100 && translation.y <= 100 && translation.y >= 0) {
            
            CGFloat base = .4 / 100;
            CGFloat offset = 1 - (base * translation.y);
            
            //update scale of preview
            [_windowPreview setTransform:CGAffineTransformMakeScale(offset, offset)];

        }
    }
    
    if ([gesture state] == UIGestureRecognizerStateEnded) {
        
        //pass
        if ([gesture locationInView:[[gesture view] superview]].y >= 80) {
            
            //pass, push to next controller
            CDTLamoOverlayTutorialController *overlayTutorial = [[CDTLamoOverlayTutorialController alloc] init];
            [_windowPreview removeFromSuperview];
            [overlayTutorial addBarButtons];
            [overlayTutorial setLamoWindow:_windowPreview];
            [overlayTutorial setTitle:@"Mímir Tutorial"];
            [[[self navigationController] interactivePopGestureRecognizer] setEnabled:NO];
            [[overlayTutorial navigationItem] setHidesBackButton:YES];
            [[self navigationController] pushViewController:overlayTutorial animated:YES];
            
        }
        
        //or restore it to normal
        else {
            
            [UIView animateWithDuration:0.3 animations:^{
                
                [_windowPreview setTransform:CGAffineTransformIdentity];
                
            }];
            
        }
    }
}

- (void)animateHelperViewDown {
    
    //animate view down
    [UIView animateWithDuration:2 animations:^{
        
        [_animatingView setFrame:CGRectMake(5, 300, 40, 40)];
        
    } completion:^(BOOL finished) {
        
        //animate back up
        [self animateHelperViewUp];
    }];
}

- (void)animateHelperViewUp {
    
    //animate view up
    [UIView animateWithDuration:1 animations:^{
        
        [_animatingView setFrame:CGRectMake(5, 200, 40, 40)];
        
    } completion:^(BOOL finished) {
        
        //animate back down
        [self animateHelperViewDown];
    }];
}

@end
