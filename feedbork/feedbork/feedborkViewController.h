//
//  feedborkViewController.h
//  feedbork
//
//  Created by Michael Rotondo on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import "opencv/cv.h"
#import "feedborkDoodad.h"
#import "feedborkOSC.h"

@class UIToggleButton;
#define IP_ADD @"192.168.188.26"
#define PORT_OUT 9999
#define PORT_IN 9998

@interface feedborkViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate,
feedborkDoodadDelegate, feedborkOSCdelegate> {
    
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *previewLayer;
    UIImageView *imageView;
    UIView *maskView;
    feedborkOSC *osc;
    
    // menu stuff
    IBOutlet UIView *menuView;
    IBOutlet UITextField *IPTextField;
    IBOutlet UISlider *borderSlider;
    IBOutlet UIToggleButton * exposureLockButton;
    
    // quadrant stuff
    CGRect quadrant[4];
    int quadTouches[4];
    float sWidth, sHeight;
}

@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain) UIImageView *imageView;

- (void)initCapture;
- (void)initMenu;
- (void)initQuadrants;
- (AVCaptureDevice *)frontFacingCameraIfAvailable;
# if !TARGET_IPHONE_SIMULATOR
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image;
- (UIImage *)UIImageFromIplImage:(IplImage *)image;
- (void) findLinesInImage:(IplImage*)img_greyscale;
- (void) findCentroidAndAreaOfImage:(IplImage*)img_greyscale;
- (void) findContoursInImage:(IplImage*)img_greyscale;
#endif

// menu functions
- (IBAction)closeMenu;
- (IBAction)changeIP:(UITextField*)sender;
- (IBAction)lockExposure;
- (IBAction)changeAlpha:(UISlider*)slider;
- (IBAction)changeBorder:(UISlider*)slider;

@end

@interface UIToggleButton : UIButton
{
    UIImageView *indicator;
    bool isOn;
}

- (void)updateState;
- (void)turnOn;
- (void)turnOff;

@property (assign,readwrite) bool isOn;

@end
