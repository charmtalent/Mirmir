//
//  CDTLamoSensitivityPane.m
//  Lamo
//
//  Created by Ethan Arbuckle on 6/26/15.
//  Copyright © 2015 CortexDevTeam. All rights reserved.
//

#import "CDTLamoSensitivityPane.h"

@interface CDTLamoSensitivityPane ()

@end

@implementation CDTLamoSensitivityPane

- (id)init {
    
    if (self = [super init]) {
        
        //setup tableview
        (void)[[self tableView] initWithFrame:[[self tableView] frame] style:UITableViewStyleGrouped];
        [[self tableView] setScrollEnabled:NO];
    }
    
    return self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_previewWindow setHidden:YES];
    _previewWindow = NULL;
    
    //stop hosting
    if (NEED_IPAD_HAX) {
        [[CDTContextHostProvider new] stopHostingForBundleID:@"com.apple.Maps"];
    }
    else {
        [[CDTContextHostProvider new] stopHostingForBundleID:@"com.apple.weather"];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return @"set activation trigger radius";
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //set custom height for 2nd cell
    if ([indexPath row] == 0) {
        
        return 44;
    }
    
    else if ([indexPath row] == 1) {
        
        return (kScreenHeight * .7) + 40;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    if ([indexPath row] == 0) {
        
        //create slider
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(10, 12, kScreenWidth - 20, 20)];
        [slider setMinimumValue:10];
        [slider setMaximumValue:100];
        [slider setValue: 100 - [[CDTLamoSettings sharedSettings] activationTriggerRadius] animated:NO];
        [slider addTarget:self action:@selector(handleSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [cell addSubview:slider];
    }
    
    else if ([indexPath row] == 1) {
        
        //create homescreen layout
        SBHomeScreenPreviewView *preview = [NSClassFromString(@"SBHomeScreenPreviewView") preview];
        
        //remove icons
        [[preview subviews][1] removeFromSuperview];
        
        [preview setTransform:CGAffineTransformMakeScale(.9, .9)];
        [preview setFrame:CGRectMake((kScreenWidth / 2) - ((kScreenWidth * .9) / 2), 10, kScreenWidth, kScreenHeight)];
        [preview setClipsToBounds:YES];
        [preview setUserInteractionEnabled:NO];
        
        [cell addSubview:preview];
    
        //create fake lamo window
        _previewWindow = [[CDTLamoWindow alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
        [_previewWindow setBackgroundColor:[UIColor grayColor]];
        [_previewWindow setTransform:CGAffineTransformMakeScale(.6, .6)];
       
        //create app
        UIView *contextView;
        if (NEED_IPAD_HAX) {
            contextView = [[CDTContextHostProvider new]  hostViewForApplicationWithBundleID:@"com.apple.Maps"];
            [[CDTContextHostProvider new] setStatusBarHidden:@(1) onApplicationWithBundleID:@"com.apple.Maps"];
        }
        else {
            contextView = [[CDTContextHostProvider new]  hostViewForApplicationWithBundleID:@"com.apple.weather"];
            [[CDTContextHostProvider new]  setStatusBarHidden:@(1) onApplicationWithBundleID:@"com.apple.weather"];
        }
        
        [_previewWindow addSubview:contextView];
        
        //create zone overlay
        _activationZone = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, [[CDTLamoSettings sharedSettings] activationTriggerRadius])];
        [_activationZone setBackgroundColor:[UIColor redColor]];
        [_activationZone setAlpha:0.7];
        
        [preview addSubview:_previewWindow];
        [preview addSubview:_activationZone];
        
        //only show a portion of homescreen preview, let cell cut the rest
        [cell setClipsToBounds:YES];
    }
    
    return cell;
}

- (void)handleSliderChanged:(UISlider *)slider {
    
    //handle resizing our view
    [_activationZone setFrame:CGRectMake(0, 0, kScreenWidth, 100 - [slider value])];
    
    //update setting
    [[CDTLamoSettings sharedSettings] setActivationTriggerRadius: 100 - [slider value]];
}

@end

