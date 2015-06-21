//
//  SBNotificationCenterController.m
//  Lamo
//
//  Created by Ethan Arbuckle on 6/9/15.
//  Copyright © 2015 CortexDevTeam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Lamo.h"
#import "CDTLamo.h"
#import "ZKSwizzle.h"

ZKSwizzleInterface($_Lamo_SBNotificationCenterController, SBNotificationCenterController, NSObject);

@implementation $_Lamo_SBNotificationCenterController

- (void)_showNotificationCenterGestureBeganWithGestureRecognizer:(id)arg1 {
   
    CGPoint location = [arg1 locationInView:[[CDTLamo sharedInstance] springboardWindow]];
    
    if (location.x <= 100 && [[UIApplication sharedApplication] _accessibilityFrontMostApplication] && [[CDTLamoSettings sharedSettings] isEnabled]) {
        
        //we've started tracking the wrapper view
        [[CDTLamo sharedInstance] setWrapperViewIsTracking:YES];
        
        //create wrapper view
        [[CDTLamo sharedInstance] updateWrapperView];
        
        //add bar to scaling wrapper view
        [[CDTLamo sharedInstance] addTopBarToWrapperWindow];
        
        //make sure homescreen is visible in background
        [[CDTLamo sharedInstance] beginShowingHomescreen];
        
        return;
    }
    
    //getting pissed off at notification center stealing my window pans
    if ([[CDTLamo sharedInstance] shouldBlockNotificationCenter]) {
        
        [self _showNotificationsGestureCancelled];
        return;
    }
    
    ZKOrig(void, arg1);

}

- (void)_showNotificationsGestureCancelled {
    ZKOrig(void);
}

- (void)_showNotificationCenterGestureChangedWithGestureRecognizer:(id)arg1 duration:(double)arg2 {
    
    CGPoint location = [arg1 locationInView:[[CDTLamo sharedInstance] springboardWindow]];
    
    //stop our touches from getting jacked
    if ([[CDTLamo sharedInstance] shouldBlockNotificationCenter]) {
        
        //[self _showNotificationsGestureCancelled];
        return;
    }
    
    //if we're tracking
    if ([[CDTLamo sharedInstance] wrapperViewIsTracking] && [[CDTLamo sharedInstance] sharedScalingWrapperView] && location.y <= 100 && [[CDTLamoSettings sharedSettings] isEnabled]) {
        
        //100 point tracking zone, with min final transform being .6
        CGFloat base = .4 / 100;
        CGFloat offset = base * location.y;
        
        //update wrapper view transform
        [[[CDTLamo sharedInstance] sharedScalingWrapperView] setTransform:CGAffineTransformMakeScale(1 - offset, 1 - offset)];
        
        return;
    }
    
    ZKOrig(void, arg1, arg2);
    
}

- (void)_showNotificationCenterGestureEndedWithGestureRecognizer:(id)arg1 {
    
    CGPoint location = [arg1 locationInView:[[CDTLamo sharedInstance] springboardWindow]];
    
    //touch ended and we were tracking
    if ([[CDTLamo sharedInstance] wrapperViewIsTracking] && [[CDTLamo sharedInstance] sharedScalingWrapperView] && [[CDTLamoSettings sharedSettings] isEnabled]) {
        
        //stop tracking
        [[CDTLamo sharedInstance] setWrapperViewIsTracking:NO];
        
        //if we need to window the app
        if (location.y >= 80) {
            
            //start window mode for app
            [[CDTLamo sharedInstance] beginWindowModeForTopApplication];
            
        }
        
        //or restore it to normal
        else {
            
            [UIView animateWithDuration:0.3 animations:^{
                
                [[[CDTLamo sharedInstance] sharedScalingWrapperView] setTransform:CGAffineTransformIdentity];
                
            }];
            
        }
        
        //nil out wrapper view
        [[CDTLamo sharedInstance] setSharedScalingWrapperView:nil];
        
        return;
    }
    
    ZKOrig(void, arg1);
    
}

@end