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
#define IP_ADD @"192.168.188.26"
#define PORT 9999

@interface feedborkViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *previewLayer;
    UIImageView *imageView;
    feedborkOSC *osc;
    
    // menu stuff
    IBOutlet UIView *menuView;
    IBOutlet UITextField *IPTextField;
}

@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain) UIImageView *imageView;

- (void)initCapture;
- (void)initMenu;
- (AVCaptureDevice *)frontFacingCameraIfAvailable;
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image;
- (UIImage *)UIImageFromIplImage:(IplImage *)image;

// menu functions
- (IBAction)closeMenu;
- (IBAction)changeIP:(UITextField*)sender;

@end
