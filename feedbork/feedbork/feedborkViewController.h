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

@class feedborkOSC;
@class UIToggleButton;
#define IP_ADD @"192.168.188.26"
#define PORT 9999

@interface feedborkViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *previewLayer;
    UIImageView *imageView;
    UIView *maskView;
    feedborkOSC *osc;
    
    // color picker stuff
    UIColor * myColor;
    UIColor * myFriendsColor;
    IBOutlet UIView * myColorPicker;
    IBOutlet UIView * myFriendsColorPicker;
    
    // menu stuff
    IBOutlet UIView *menuView;
    IBOutlet UITextField *IPTextField;
    IBOutlet UISlider *borderSlider;
    IBOutlet UIToggleButton * exposureLockButton;
}

@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain) UIImageView *imageView;

- (void)initCapture;
- (void)initMenu;
- (AVCaptureDevice *)frontFacingCameraIfAvailable;
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image;
- (UIImage *)UIImageFromIplImage:(IplImage *)image;

// color picker functions
- (IBAction)chooseMyColor:(UIButton*)sender;
- (IBAction)chooseMyFriendsColor:(UIButton*)sender;

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
