#import "CDTLamoBarView.h"

@implementation CDTLamoBarView

- (id)init {

	if (self = [super init]) {

		//create the bar
		[self setFrame:CGRectMake(0, 0, kScreenWidth, [[CDTLamoSettings sharedSettings] windowBarHeight])];
		[self setBackgroundColor:[UIColor darkGrayColor]];
		[self setAlpha:0.9];
		[self setUserInteractionEnabled:YES];

		//add pangesture to make it movable
		CDTLamoPanGestureRecognizer *panTrack = [[CDTLamoPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [panTrack setDelegate:self];
		[self addGestureRecognizer:panTrack];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [tapGesture setDelegate:self];
        [self addGestureRecognizer:tapGesture];
        
    }

	return self;
}

- (void)setTitle:(NSString *)title {
    
    //create app name label
    _appNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 20)];
    [_appNameLabel setTextColor:[UIColor whiteColor]];
    [_appNameLabel setTextAlignment:NSTextAlignmentCenter];
    [_appNameLabel setCenter:[self center]];
    [_appNameLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Medium" size:16]];
    
    //so we can watermake builds. 'BUILD_OWNER' flag
    if ([[NSString stringWithFormat:@"%s", stringify(BUILD_OWNER)] length] > 0) {
        
        //if its present append it to title
        title = [NSString stringWithFormat:@"%@ - %s", title, stringify(BUILD_OWNER)];
        
        //add independent of user settings
        [self addSubview:_appNameLabel];
    }
    
    [_appNameLabel setText:title];
    
    if ([[CDTLamoSettings sharedSettings] showTitleText]) {
        
        [self addSubview:_appNameLabel];
    }
    
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    
    //check if we need to create or remove overlay
    if (_overlayView && [_overlayView superview]) {
        
        //remove it
        [UIView animateWithDuration:0.4f animations:^{
            
            [_overlayView setAlpha:0];
        } completion:^(BOOL finished) {
            
            _overlayView = nil;
        }];
    }
    
    else {
    
        //create overlay options. frame is in context of superview, cdtlamowindow
        _overlayView = [[CDTLamoAppOverlay alloc] initWithOrientation:[(CDTLamoWindow *)[self superview] activeOrientation]];
        
        //settings barview stays at 20
        if ([[(CDTLamoWindow *)[self superview] identifier] isEqualToString:@"com.cortexdevteam.lamosetting"])
            [_overlayView setFrame:CGRectMake(0, 20, kScreenWidth, kScreenHeight)];
        else
            [_overlayView setFrame:CGRectMake(0, [[CDTLamoSettings sharedSettings] windowBarHeight], kScreenWidth, kScreenHeight)];
        
        [_overlayView setBackgroundColor:[UIColor clearColor]];
        [_overlayView setAlpha:0];
        [[self superview] addSubview:_overlayView];
        
        [UIView animateWithDuration:0.4f animations:^{
            [_overlayView setAlpha:1];
        }];
    }
    
}

- (void)handlePan:(UIPanGestureRecognizer *)panGesture {

    if ([panGesture state] == UIGestureRecognizerStateEnded) {
        
        //check if we're primed to snap
        if (_isPrimedForSnapping) {
            
            //we're primed, execute the snapz
            _primedSnapAction();
            
            //and cancel it out so we dont double snapz
            _isPrimedForSnapping = NO;
            _primedSnapAction = nil;
            
        }
        
    }
    
    if ([panGesture state] == UIGestureRecognizerStateBegan) {
        
        _offset = [[[panGesture view] superview] frame].origin;
        
        //bring it to front
        if ([(UIWindow *)[self superview] windowLevel] < [[CDTLamo sharedInstance] stackedWindowLevel]) {
            
            NSInteger newLevel = [[CDTLamo sharedInstance] stackedWindowLevel] + 1;
            [[CDTLamo sharedInstance] setStackedWindowLevel:newLevel];
            [(UIWindow *)[self superview] setWindowLevel:newLevel];
        }
        
    } else
        
        if ([panGesture state] == UIGestureRecognizerStateChanged) {
            
            CGPoint translation = [panGesture translationInView:[[CDTLamo sharedInstance] fbRootWindow]];
            
            CGPoint snapLocation = [panGesture locationInView:[[CDTLamo sharedInstance] fbRootWindow]];
            
            if (snapLocation.x <= 5) { //left
                
                //this makes the window a bit clear, and sets up the snapping action block
                if (snapLocation.y <= kScreenHeight / 2) {
                    
                    [[CDTLamo sharedInstance] primeApplicationForSnapping:[(CDTLamoWindow *)[[panGesture view] superview] identifier] toPosition:CDTLamoSnapTopLeft];
                }
                else {
                    
                    [[CDTLamo sharedInstance] primeApplicationForSnapping:[(CDTLamoWindow *)[[panGesture view] superview] identifier] toPosition:CDTLamoSnapBottomLeft];
                }
            }
            
            else if (snapLocation.x >= kScreenWidth - 5) { //right
                
                //this makes the window a bit clear, and sets up the snapping action block
                if (snapLocation.y <= kScreenHeight / 2) {
                    
                    [[CDTLamo sharedInstance] primeApplicationForSnapping:[(CDTLamoWindow *)[[panGesture view] superview] identifier] toPosition:CDTLamoSnapTopRight];
                }
                else {
                    
                    [[CDTLamo sharedInstance] primeApplicationForSnapping:[(CDTLamoWindow *)[[panGesture view] superview] identifier] toPosition:CDTLamoSnapBottomRight];
                }
            }
            
            
            else if (snapLocation.y <= 5) { //top
                
                [[CDTLamo sharedInstance] primeApplicationForSnapping:[(CDTLamoWindow *)[[panGesture view] superview] identifier] toPosition:CDTLamoSnapTop];
            }
            
            else if (snapLocation.y >= kScreenHeight - ((kScreenHeight * [[CDTLamoSettings sharedSettings] defaultWindowSize]) / 2)) { //bottom
                
                [[CDTLamo sharedInstance] primeApplicationForSnapping:[(CDTLamoWindow *)[[panGesture view] superview] identifier] toPosition:CDTLamoSnapBottom];
            }
            
            else {
                
                //window is out of snap region, unprime the shit
                if (_isPrimedForSnapping) {
                    
                    _isPrimedForSnapping = NO;
                    
                    //restore alpha
                    [[[[CDTLamo sharedInstance] windows] valueForKey:[(CDTLamoWindow *)[[panGesture view] superview] identifier]] setAlpha:1];
                    
                    _primedSnapAction = nil;
                }
            }
            
            CGRect bounds = CGRectMake(_offset.x + translation.x, _offset.y + translation.y, [[panGesture view] superview].frame.size.width,[[panGesture view] superview].frame.size.height);
            
            CGFloat mainSize = [[CDTLamoSettings sharedSettings] defaultWindowSize];
            if (bounds.origin.x <= -((kScreenWidth * mainSize) / 2)) bounds.origin.x = -((kScreenWidth *mainSize) / 2);
            if (bounds.origin.y >= kScreenHeight - ((kScreenHeight * mainSize) / 2)) bounds.origin.y = kScreenHeight - ((kScreenHeight * mainSize) / 2);
            if (bounds.origin.y <= 0) bounds.origin.y = 0;
            if (bounds.origin.x >= kScreenWidth - ((kScreenWidth * mainSize) / 2)) bounds.origin.x = kScreenWidth - ((kScreenWidth * mainSize) / 2);
            
            [[[panGesture view] superview] setFrame:bounds];
            
        }
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end