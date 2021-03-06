//
//  CDTLamoMinimizedWindowPane.h
//  Lamo
//
//  Created by Ethan Arbuckle on 6/26/15.
//  Copyright © 2015 CortexDevTeam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Lamo.h"
#import "CDTLamoWindow.h"
#import "CDTContextHostProvider.h"

@interface CDTLamoMinimizedWindowPane : UITableViewController

@property (nonatomic, retain) UIView *previewWindow;

- (void)handleSliderChanged:(UISlider *)slider;

@end
