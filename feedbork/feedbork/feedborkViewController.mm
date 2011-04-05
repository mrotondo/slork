//
//  feedborkViewController.m
//  feedbork
//
//  Created by Michael Rotondo on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "feedborkViewController.h"
#import "feedborkOSC.h"

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
    [self initMenu];
    osc = [[feedborkOSC alloc] initWithIP:IPTextField.text port:PORT];
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
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);

	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
    
	return iplimage;
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
    
    captureSession.sessionPreset = AVCaptureSessionPresetPhoto;

    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
	self.previewLayer.frame = self.view.bounds;
	self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer: self.previewLayer];

    self.imageView = [[UIImageView alloc] init];
	self.imageView.frame = self.view.bounds;//CGRectMake(0, 0, 153, 204);
    [self.view addSubview:self.imageView];
    // bring menu to front again and then hide it
    [self.view bringSubviewToFront:menuView];
    menuView.transform = CGAffineTransformMakeTranslation(-1000.0, 0.0);
    
	[self.captureSession startRunning];
}

- (void)initMenu
{
    // set up the IP Text Field stuff
    if ( [[NSUserDefaults standardUserDefaults] stringForKey:@"IP"] )
        [IPTextField setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"IP"]];
    else
    {
        [IPTextField setText:IP_ADD];
        [[NSUserDefaults standardUserDefaults] setObject:IPTextField.text forKey:@"IP"];
    }
    
    // Create a swipe gesture recognizer to recognize right swipes, three finger
    UISwipeGestureRecognizer *recognizer;
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setNumberOfTouchesRequired:3];
    recognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:recognizer];
    // once we add its properties we don't need it
    [recognizer release];
    // now create one for the left swipe, also three finger
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setNumberOfTouchesRequired:3];
    recognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:recognizer];
    [recognizer release];
}

// handle received swipe gestures 
- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer 
{    
    // move it away if we're centered already
    if ( CGAffineTransformIsIdentity(menuView.transform) ) 
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        if ( recognizer.direction == UISwipeGestureRecognizerDirectionRight )
            menuView.transform = CGAffineTransformMakeTranslation(1000.0, 0.0);
        else
            menuView.transform = CGAffineTransformMakeTranslation(-1000.0, 0.0);
        [UIView commitAnimations];
        
        [IPTextField resignFirstResponder];
        
    }
    
    // center it if we're moved away already
    else
    {
        if ( recognizer.direction == UISwipeGestureRecognizerDirectionRight )
            menuView.transform = CGAffineTransformMakeTranslation(-1000.0, 0.0);
        else
            menuView.transform = CGAffineTransformMakeTranslation(1000.0, 0.0);
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        menuView.transform = CGAffineTransformIdentity;
        [UIView commitAnimations];
    }
}

- (IBAction)closeMenu
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    menuView.transform = CGAffineTransformMakeTranslation(-1000.0, 0.0);
    [UIView commitAnimations];
    
    [IPTextField resignFirstResponder];
}

- (IBAction)changeIP:(UITextField*)sender
{
    [IPTextField resignFirstResponder];
    [osc changeIP:IPTextField.text];
    
    [[NSUserDefaults standardUserDefaults] setObject:IPTextField.text forKey:@"IP"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)lockExposure
{
    // grab all inputs
    NSArray * inputs = captureSession.inputs;
    // if inputs exist, we'll proceed to try locking
    if ( [inputs count] ) 
    {
        AVCaptureDeviceInput * inputDevice = [inputs objectAtIndex:0];

        NSError * outError;
        // attempt to lock camera for config
        if ( [inputDevice.device lockForConfiguration:&outError] )
            inputDevice.device.exposureMode = (inputDevice.device.exposureMode == AVCaptureExposureModeLocked) ? 
            AVCaptureExposureModeContinuousAutoExposure : AVCaptureExposureModeLocked;
    }

}

// rotation helper function
static CGRect swapWidthAndHeight(CGRect rect)
{
    CGFloat  swap = rect.size.width;
    
    rect.size.width  = rect.size.height;
    rect.size.height = swap;
    
    return rect;
}

// rotate image to new orientation programmatically
-(UIImage*)rotate:(UIImage*)imageIn to:(UIImageOrientation)orient
{
    CGRect             bnds = CGRectZero;
    UIImage*           copy = nil;
    CGContextRef       ctxt = nil;
    CGImageRef         imag = imageIn.CGImage;
    CGRect             rect = CGRectZero;
    CGAffineTransform  tran = CGAffineTransformIdentity;
    
    rect.size.width  = CGImageGetWidth(imag);
    rect.size.height = CGImageGetHeight(imag);
    
    bnds = rect;
    
    switch (orient)
    {
        case UIImageOrientationUp:
            // would get you an exact copy of the original
            assert(false);
            return nil;
            
        case UIImageOrientationUpMirrored:
            tran = CGAffineTransformMakeTranslation(rect.size.width, 0.0);
            tran = CGAffineTransformScale(tran, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown:
            tran = CGAffineTransformMakeTranslation(rect.size.width,
                                                    rect.size.height);
            tran = CGAffineTransformRotate(tran, M_PI);
            break;
            
        case UIImageOrientationDownMirrored:
            tran = CGAffineTransformMakeTranslation(0.0, rect.size.height);
            tran = CGAffineTransformScale(tran, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeft:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(0.0, rect.size.width);
            tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeftMirrored:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(rect.size.height,
                                                    rect.size.width);
            tran = CGAffineTransformScale(tran, -1.0, 1.0);
            tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRight:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(rect.size.height, 0.0);
            tran = CGAffineTransformRotate(tran, M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeScale(-1.0, 1.0);
            tran = CGAffineTransformRotate(tran, M_PI / 2.0);
            break;
            
        default:
            // orientation value supplied is invalid
            assert(false);
            return nil;
    }
    
    UIGraphicsBeginImageContext(bnds.size);
    ctxt = UIGraphicsGetCurrentContext();
    
    switch (orient)
    {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextScaleCTM(ctxt, -1.0, 1.0);
            CGContextTranslateCTM(ctxt, -rect.size.height, 0.0);
            break;
            
        default:
            CGContextScaleCTM(ctxt, 1.0, -1.0);
            CGContextTranslateCTM(ctxt, 0.0, -rect.size.height);
            break;
    }
    
    CGContextConcatCTM(ctxt, tran);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, imag);
    
    copy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return copy;
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
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationUp];
    IplImage *img_color = [self CreateIplImageFromUIImage:image];
    IplImage *img_greyscale = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
    cvCvtColor(img_color, img_greyscale, CV_BGR2GRAY);
    IplImage *img_binary = cvCreateImage(cvGetSize(img_greyscale), IPL_DEPTH_8U, 1);

    cvThreshold(img_greyscale, img_binary, 20, 255, CV_THRESH_TOZERO);
    
    CvMemStorage* storage = cvCreateMemStorage(0);
    CvSeq* contours;
    int numContours = cvFindContours( img_binary , storage, &contours, sizeof(CvContour),
                                     CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0) );
    NSLog(@"Got %d contours!", numContours);
    
    [osc sendValue:numContours * 10 withKey:@"test"];

    
    while( contours )
    {
        // take the next contour
        contours = contours->h_next;
    }
    
    // Convert black and whilte to 24bit image then convert to UIImage to show
    IplImage *ipl_result = cvCreateImage(cvGetSize(img_binary), IPL_DEPTH_8U, 3);
    for(int y=0; y<img_binary->height; y++) {
        for(int x=0; x<img_binary->width; x++) {
            char *p = ipl_result->imageData + y * ipl_result->widthStep + x * 3;
            *p = *(p+1) = *(p+2) = img_binary->imageData[y * img_binary->widthStep + x];
        }
    }
    
    //ipl_result
    UIImage * rotatedImage = [self rotate:[self UIImageFromIplImage:ipl_result] to:UIImageOrientationRightMirrored];
    

    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:rotatedImage waitUntilDone:YES];
    
    cvReleaseImage(&img_binary);
    cvReleaseImage(&img_color);
    cvReleaseImage(&img_greyscale);
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
    [osc release];
    [super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end