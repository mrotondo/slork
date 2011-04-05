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

@interface feedborkViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *previewLayer;
    UIImageView *imageView;
}

@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain) UIImageView *imageView;

- (void)initCapture;
- (AVCaptureDevice *)frontFacingCameraIfAvailable;
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image;
- (UIImage *)UIImageFromIplImage:(IplImage *)image;

@end
