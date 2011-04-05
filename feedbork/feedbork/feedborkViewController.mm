//
//  feedborkViewController.m
//  feedbork
//
//  Created by Michael Rotondo on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "feedborkViewController.h"

@implementation feedborkViewController
@synthesize captureSession, previewLayer, imageView;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initCapture];
}

- (AVCaptureDevice *)frontFacingCameraIfAvailable
{
    //  look at all the video devices and get the first one that's on the front
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionFront)
        {
            captureDevice = device;
            break;
        }
    }
    
    //  couldn't find one on the front, so just get the default video device.
    if ( ! captureDevice)
    {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return captureDevice;
}

- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
	CGImageRef imageRef = image.CGImage;
    
    //NSLog(@"Got a UIImage (%f, %f)", image.size.width, image.size.height);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
    CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
													iplimage->depth, iplimage->widthStep,
													colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
    
    
//    // Try to account for the fact that the UIImage apparently is rotated?
//    CGContextTranslateCTM(contextRef, image.size.width / 2, image.size.height / 2);
//    CGContextRotateCTM(contextRef, -M_PI / 2);
//    CGContextTranslateCTM(contextRef, -image.size.width / 2, -image.size.height / 2);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);

	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
    
	IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplimage, ret, CV_RGBA2BGR);
	cvReleaseImage(&iplimage);
    
	return ret;
}

- (UIImage *)UIImageFromIplImage:(IplImage *)image {
	//NSLog(@"IplImage (%d, %d) %d bits by %d channels, %d bytes/row %s", image->width, image->height, image->depth, image->nChannels, image->widthStep, image->channelSeq);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return ret;
}


- (void)initCapture
{
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput 
										  deviceInputWithDevice:[self frontFacingCameraIfAvailable] 
										  error:nil];

    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES; 
    captureOutput.minFrameDuration = CMTimeMake(1, 10);

    dispatch_queue_t queue;
	queue = dispatch_queue_create("cameraQueue", NULL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
    
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey; 
	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]; 
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key]; 
	[captureOutput setVideoSettings:videoSettings]; 

    self.captureSession = [[AVCaptureSession alloc] init];
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:captureOutput];

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
	self.previewLayer.frame = self.view.bounds;
	self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer: self.previewLayer];

    self.imageView = [[UIImageView alloc] init];
	self.imageView.frame = CGRectMake(0, 0, 153, 204);
    [self.view addSubview:self.imageView];
    
	[self.captureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection 
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    CVPixelBufferLockBaseAddress(imageBuffer,0); 

    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer);  

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext); 

    CGContextRelease(newContext); 
    CGColorSpaceRelease(colorSpace);
    
    
    // TODO: Figure out why the camera feed is coming through rotated & transformed in these images.
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationLeftMirrored];
    IplImage *img_color = [self CreateIplImageFromUIImage:image];
    IplImage *img_greyscale = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
    cvCvtColor(img_color, img_greyscale, CV_BGR2GRAY);
    IplImage *img_binary = cvCreateImage(cvGetSize(img_greyscale), IPL_DEPTH_8U, 1);
    cvThreshold(img_greyscale, img_binary, 20, 255, CV_THRESH_BINARY);
    cvReleaseImage(&img_color);
    cvReleaseImage(&img_greyscale);
    
    CvMemStorage* storage = cvCreateMemStorage(0);
    CvSeq* contours;
    int numContours = cvFindContours( img_binary , storage, &contours, sizeof(CvContour),
                                     CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0) );
    
    NSLog(@"Got %d contours!", numContours);
    
    // Convert black and whilte to 24bit image then convert to UIImage to show
    IplImage *ipl_result = cvCreateImage(cvGetSize(img_binary), IPL_DEPTH_8U, 3);
    for(int y=0; y<img_binary->height; y++) {
        for(int x=0; x<img_binary->width; x++) {
            char *p = ipl_result->imageData + y * ipl_result->widthStep + x * 3;
            *p = *(p+1) = *(p+2) = img_binary->imageData[y * img_binary->widthStep + x];
        }
    }
    cvReleaseImage(&img_binary);
    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:[self UIImageFromIplImage:ipl_result] waitUntilDone:YES];
    
    cvReleaseImage(&ipl_result);    
    
//    cvSetErrMode(CV_ErrModeParent);
//    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationDown];
//    IplImage *img_color = [self CreateIplImageFromUIImage:image];
//    IplImage *img = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
//    cvCvtColor(img_color, img, CV_BGR2GRAY);
//    cvReleaseImage(&img_color);
//    
//    // Detect edge
//    IplImage *img2 = cvCreateImage(cvGetSize(img), IPL_DEPTH_8U, 1);
//    cvCanny(img, img2, 64, 128, 3);
//    cvReleaseImage(&img);
//    
//    // Convert black and whilte to 24bit image then convert to UIImage to show
//    IplImage *result = cvCreateImage(cvGetSize(img2), IPL_DEPTH_8U, 3);
//    for(int y=0; y<img2->height; y++) {
//        for(int x=0; x<img2->width; x++) {
//            char *p = result->imageData + y * result->widthStep + x * 3;
//            *p = *(p+1) = *(p+2) = img2->imageData[y * img2->widthStep + x];
//        }
//    }
//    cvReleaseImage(&img2);
//    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:[self UIImageFromIplImage:result] waitUntilDone:YES];
//    cvReleaseImage(&result);
    
    CGImageRelease(newImage);
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    [pool drain];
} 


- (void)viewDidUnload
{
    [super viewDidUnload];
    [self.previewLayer release];
}

- (void)dealloc {
	[self.captureSession release];
    [super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
