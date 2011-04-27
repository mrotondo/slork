//
//  feedborkViewController.m
//  feedbork
//
//  Created by Michael Rotondo on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "feedborkViewController.h"
#import "QuartzCore/QuartzCore.h"

#define IPAD_WIDTH 768.0
#define IPAD_HEIGHT 1024.0
#define IPHONE_WIDTH 320.0
#define IPHONE_HEIGHT 480.0

#define CURRENT_MODE [instSeg selectedSegmentIndex]
#define BASS_MODE ([instSeg selectedSegmentIndex] == 0)
#define MELODY_AND_CHORDS_MODE ([instSeg selectedSegmentIndex] == 1)

@implementation feedborkViewController
@synthesize captureSession, previewLayer, imageView;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// stuff for the simulator to add a button
- (void)openMenu
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    if ( CGAffineTransformIsIdentity(menuView.transform) ) 
    {
        menuView.transform = CGAffineTransformMakeTranslation(1000.0, 0.0);        
        [IPTextField resignFirstResponder];
        
    }
    
    // center it if we're moved away already
    else
        menuView.transform = CGAffineTransformIdentity;
        
    [UIView commitAnimations];

}
- (void)createMenuAccess
{
    UIButton * tempMenu = [[UIButton alloc] initWithFrame:CGRectMake(768/2.0-50, 10, 100, 50)];
    [tempMenu setTitle:@"menu" forState:UIControlStateNormal];
    [tempMenu setBackgroundColor:[UIColor orangeColor]];
    [tempMenu addTarget:self action:@selector(openMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:tempMenu];
    [self.view setBackgroundColor:[UIColor blackColor]];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    # if !TARGET_IPHONE_SIMULATOR
    [self initCapture];
    # endif
    [self initMenu];
    [self initQuadrants];
    //[self initTapRecognizer];
    
    # if TARGET_IPHONE_SIMULATOR
    [self createMenuAccess];
    # endif
    
    // setup OSC
    osc = [[feedborkOSC alloc] initWithIP:IPTextField.text portOut:PORT_OUT portIn:PORT_IN];
    osc.delegate = self;
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

# if !TARGET_IPHONE_SIMULATOR
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
#endif

- (void)initCapture
{
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput 
										  deviceInputWithDevice:[self frontFacingCameraIfAvailable] 
										  error:nil];
    
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES; 
    captureOutput.minFrameDuration = CMTimeMake(1, 30);

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

    maskView = [[UIView alloc] initWithFrame:self.view.bounds];
    [maskView setBackgroundColor:[UIColor blackColor]];
    maskView.alpha = 0.0;
    [self.view addSubview:maskView];
    
    self.imageView = [[UIImageView alloc] init];
	self.imageView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width - borderSlider.value/2.0, self.view.bounds.size.height - borderSlider.value/2.0);
    self.imageView.center = self.view.center;
    //[self.view addSubview:self.imageView];
    
    // bring menu to front again and then hide it
    [self.view bringSubviewToFront:menuView];
    menuView.transform = CGAffineTransformMakeTranslation(-1000.0, 0.0);
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
	self.previewLayer.frame = self.view.bounds;//CGRectMake(0, 0, 76, 102);
    self.previewLayer.transform = CATransform3DMakeScale(0.9, 0.9, 1.0);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer: self.previewLayer];
    [self.view bringSubviewToFront: maskView];
    [self.view bringSubviewToFront:menuView];

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
    
    // set up current selected segment
    if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"instrument"] )
        [instSeg setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"instrument"]];
    
    menuView.transform = CGAffineTransformMakeTranslation(1000.0, 0.0);
    
    // Create a swipe gesture recognizer to recognize right swipes, three finger
    UISwipeGestureRecognizer *recognizer;
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setNumberOfTouchesRequired:5];
    recognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:recognizer];
    // once we add its properties we don't need it
    [recognizer release];
    // now create one for the left swipe, also three finger
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setNumberOfTouchesRequired:5];
    recognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:recognizer];
    [recognizer release];
}

- (void)initQuadrants
{
    // setup quadrants
    #ifdef UI_USER_INTERFACE_IDIOM
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        sWidth = IPAD_WIDTH;
        sHeight = IPAD_HEIGHT;
    }
    else
    {
        sWidth = IPHONE_WIDTH;
        sHeight = IPHONE_HEIGHT;
    }
    #endif
    quadrant[0] = CGRectMake(sWidth/2.0, 0.0,         sWidth/2.0, sHeight/2.0);
    quadrant[1] = CGRectMake(0.0,        0.0,         sWidth/2.0, sHeight/2.0);    
    quadrant[2] = CGRectMake(0.0,        sHeight/2.0, sWidth/2.0, sHeight/2.0);
    quadrant[3] = CGRectMake(sWidth/2.0, sHeight/2.0, sWidth/2.0, sHeight/2.0);
    quadTouches[0] = quadTouches[1] = quadTouches[2] = quadTouches[3] = 0;
}

- (void)initTapRecognizer
{
    // Create a tap gesture recognizer to recognize single-finger taps
    UISwipeGestureRecognizer *recognizer;
    recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.view addGestureRecognizer:recognizer];
    // once we add its properties we don't need it
    [recognizer release];
}

- (void)handleTapFrom:(UITapGestureRecognizer *)recognizer
{
    CGPoint loc = [recognizer locationInView:self.view];
    CGPoint tapPoint = CGPointMake(loc.x / self.view.bounds.size.width, 1 - (loc.y / self.view.bounds.size.height));
    if BASS_MODE [osc sendPoint:tapPoint withKey:@"tap"];
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

// menu functions
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

- (IBAction)changeSegment
{
    [[NSUserDefaults standardUserDefaults] setInteger:instSeg.selectedSegmentIndex forKey:@"instrument"];
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
        {
            inputDevice.device.exposureMode = (inputDevice.device.exposureMode == AVCaptureExposureModeLocked) ? 
            AVCaptureExposureModeContinuousAutoExposure : AVCaptureExposureModeLocked;
            [exposureLockButton updateState];
            [inputDevice.device unlockForConfiguration];
        }
    }

}

- (IBAction)changeAlpha:(UISlider*)slider
{
    maskView.alpha = 1.0 - slider.value;   
}

- (IBAction)changeBorder:(UISlider*)slider
{
    self.imageView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width - borderSlider.value/2.0, self.view.bounds.size.height - borderSlider.value/2.0);
    self.imageView.center = self.view.center;
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

# if !TARGET_IPHONE_SIMULATOR
- (void) findLinesInImage:(IplImage*)img_greyscale
{
    IplImage *img_lines = cvCreateImage(cvGetSize(img_greyscale), IPL_DEPTH_8U, 1);
    cvCanny(img_greyscale, img_lines, 50, 200, 3);
    
    CvMemStorage* line_storage = cvCreateMemStorage(0);
    CvSeq* lines = 0;
    lines = cvHoughLines2(img_lines,
                          line_storage,
                          CV_HOUGH_PROBABILISTIC,
                          1,
                          CV_PI/180,
                          80,
                          30,
                          10 );
    
    int max_line_index = 0;
    int max_line_length = 0;
    float dist;
    for( int line_index = 0; line_index < lines->total; line_index++ )
    {
        CvPoint* line = (CvPoint*)cvGetSeqElem(lines, line_index);
        CvPoint p1 = line[0];
        CvPoint p2 = line[1];
        
        dist = powf(p1.x - p2.x, 2) + powf(p1.y - p2.y, 2);
        if (dist > max_line_length) {
            max_line_length = dist;
            max_line_index = line_index;
        }
    }
    
    float angle;
    if (lines->total > 0) {
        CvPoint* line = (CvPoint*)cvGetSeqElem(lines, max_line_index);
        CvPoint p1 = line[0];
        CvPoint p2 = line[1];
        
        // To draw diagnostic output
        //cvLine( img_color, line[0], line[1], CV_RGB(255,0,0), 3, 8 );
        cvLine( img_greyscale, p1, p2, CV_RGB(255,0,0), 3, 8 );
        
        angle = fmod(fabs(atan2f(p1.y - p2.y, p1.x - p2.x)), M_PI / 2.0);
        [osc sendValue:angle withKey:@"line_angle"];
        [osc sendValue:sqrt(max_line_length) withKey:@"line_length"];
    } else {
        [osc sendValue:0 withKey:@"line_angle"];
        [osc sendValue:0 withKey:@"line_length"];
    }
    
    // Cleanup
    cvReleaseMemStorage(&line_storage);
    cvReleaseImage(&img_lines);
}

- (void) findCentroidAndAreaOfImage:(IplImage*)img_greyscale
{
    CvMoments* moments = (CvMoments*)malloc( sizeof(CvMoments) );
    cvMoments(img_greyscale, moments);
    
    double area = moments->m00;
    double m10 = moments->m10;
    double m01 = moments->m01;
    
    // Thanks, Wikipedia: http://en.wikipedia.org/wiki/Image_moment
    double x = m10 / area;
    double y = m01 / area;

    //NSLog(@"Area: %f", area);
    
    
    [osc sendValue:area withKey:@"brightness"];
    
    CvPoint centroid = cvPoint(x, y);
    cvCircle(img_greyscale, centroid, 20, CV_RGB(255, 255, 255));
    
    CvSize size = cvGetSize(img_greyscale);
    // Remap opencv's x and y to ours, and normalize to screen size
    [osc sendValue:y / size.height withKey:@"centroid_x"];
    [osc sendValue:1 - (x / size.width) withKey:@"centroid_y"];
    
    free(moments);
}

- (void) findContoursInImage:(IplImage*)img_greyscale
{
    IplImage *img_threshold = cvCreateImage(cvGetSize(img_greyscale), IPL_DEPTH_8U, 1);
    cvThreshold(img_greyscale, img_threshold, 160, 255, CV_THRESH_BINARY);
    CvMemStorage* contour_storage = cvCreateMemStorage(0);
    CvSeq* contours;
    int numContours = cvFindContours( img_threshold , contour_storage, &contours, sizeof(CvContour),
                                     CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0) );
    
    [osc sendValue:numContours withKey:@"num_contours"];
    
    cvReleaseMemStorage(&contour_storage);
    cvReleaseImage(&img_threshold);
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

    // Leaving this here in case we want to do something with raw pixels again later.
//    for ( int i = 0; i < width * height * 4; i+=4 )
//    {
//        // Grab the raw memory addresses
//        uint8_t *r = (baseAddress + i + 0);
//        uint8_t *g = (baseAddress + i + 1);
//        uint8_t *b = (baseAddress + i + 2);
//    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext); 
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationUp];
    IplImage *img_color = [self CreateIplImageFromUIImage:image];        
    IplImage *img_greyscale = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
    cvCvtColor(img_color, img_greyscale, CV_BGR2GRAY);
    
    // Extract features
    [self findCentroidAndAreaOfImage:img_greyscale];
    //[self findContoursInImage:img_greyscale];
    //[self findLinesInImage:img_greyscale];
    
//    // Convert black and whilte to 24bit image then convert to UIImage to show
//    IplImage *ipl_result = cvCreateImage(cvGetSize(img_greyscale), IPL_DEPTH_8U, 3);
//    for(int y = 0; y < img_greyscale->height; y++) {
//        for(int x = 0; x < img_greyscale->width; x++) {
//            char *p = ipl_result->imageData + y * ipl_result->widthStep + x * 3;
//            *p = *(p+1) = *(p+2) = img_greyscale->imageData[y * img_greyscale->widthStep + x];
//        }
//    }

    UIImage * rotatedImage = [self rotate:[self UIImageFromIplImage:img_color] to:UIImageOrientationRightMirrored];
    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:rotatedImage waitUntilDone:YES];

    cvReleaseImage(&img_color);
    cvReleaseImage(&img_greyscale);
//    cvReleaseImage(&ipl_result);
    
    CGImageRelease(newImage);
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    [pool drain];
} 
#endif

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
    if ( interfaceOrientation == UIInterfaceOrientationPortrait )
    {
        // set as CHORDS
    }
    
    else if ( interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown )
    {
        // set as MELODY
    }
    
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait && UIInterfaceOrientationPortraitUpsideDown);
}

#pragma  mark feedborkDoodads delegate methods
- (void)killMe:(feedborkDoodad*)doodad
{
    [doodad removeFromSuperview];
    [doodad release];
}

#pragma mark feedborkOSC delegate methods

- (void)makeDoodadMainThread:(NSArray*)stuff 
{
    CGPoint _center = [[stuff objectAtIndex:0] CGPointValue];
    float vel = 20.0 * [[stuff objectAtIndex:1] floatValue];
    [[feedborkDoodad alloc] initWithImageNamed:[stuff objectAtIndex:2] superview:self.view center:_center size:CGSizeMake(vel, vel) color:[stuff objectAtIndex:3] delegate:self];
}

- (void)makeDoodad:(CGPoint)_center size:(float)vel image:(NSString*)_image color:(UIColor*)_color;
{
    // jitter center a bit
    _center.x += rand()%3000/10.0 - 150.0;
    _center.y += rand()%3000/10.0 - 150.0;
    
    NSValue * val = [NSValue valueWithCGPoint:_center];
    NSArray * stuff = [NSArray arrayWithObjects:val,[NSNumber numberWithFloat:vel],_image,_color,nil];
    
    [self performSelectorOnMainThread:@selector(makeDoodadMainThread:) withObject:stuff waitUntilDone:NO];
    
}

#pragma mark Touch Methods

- (bool)point:(CGPoint)thisPoint isInside:(CGRect)thisRect
{
    return ( thisPoint.x > thisRect.origin.x &&
             thisPoint.x < thisRect.origin.x + thisRect.size.width &&
             thisPoint.y > thisRect.origin.y &&
             thisPoint.y < thisRect.origin.y + thisRect.size.height);
}

CGPoint prevTouch;

- (bool)didCross:(float)cross with:(CGPoint)touch
{
    return ( (prevTouch.x >= cross && touch.x <= cross) ||
            (prevTouch.x <= cross && touch.x >= cross) );
}

- (void)processStrings:(CGPoint)touch
{
    for ( int i = 0; i < 28; i++ )
        if ( [self didCross:i*25 with:touch] ) [osc sendPoint:CGPointMake(i*1.0, touch.y/1024.0) withKey:@"string"];
    prevTouch = touch;
}

const float thresh = 50.0;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{    
    int prevTotal = totaltouches;
    // reset touches
    quadTouches[0] = quadTouches[1] = quadTouches[2] = quadTouches[3] = 0;
    
    // this will count all touches on screen (as opposed to touch in touches which only counts new ones)
    for ( UITouch * touch in [event allTouches] )
    {
        CGPoint thisPoint = [touch locationInView:self.view];
        if ( [self point:thisPoint isInside: quadrant[0]] ) 
            quadTouches[0]++;
        else if ( [self point:thisPoint isInside: quadrant[1]] ) 
            quadTouches[1]++;
        else if ( [self point:thisPoint isInside: quadrant[2]] ) 
            quadTouches[2]++;
        else if ( [self point:thisPoint isInside: quadrant[3]] )
            quadTouches[3]++;
    }
    
    totaltouches = quadTouches[0] + quadTouches[1] + quadTouches[2] + quadTouches[3];
    
    // drum control
    // this will just count new touches to the screen
    for ( UITouch * touch in touches )
    {
        CGPoint thisPoint = [touch locationInView:self.view];
        if ( [touches count] > 1 ) [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:thisPoint size:CGSizeMake(25.0,25.0) color:[UIColor yellowColor] delegate:self];
        if ( [self point:thisPoint isInside: quadrant[0]] ) 
        {
            if ( thisPoint.x > IPAD_WIDTH - thresh ) [osc sendDrumControlX:thisPoint.y/11.0 Y:thisPoint.x/8.0 withKey:@"random"];
        }
        else if ( [self point:thisPoint isInside: quadrant[1]] ) 
        {
            if ( thisPoint.x < thresh ) [osc sendDrumControlX:thisPoint.y/11.0 Y:thisPoint.x/8.0 withKey:@"density"];
        }
        else if ( [self point:thisPoint isInside: quadrant[2]] ) 
        {
            if ( thisPoint.x < thresh ) [osc sendDrumControlX:thisPoint.y/11.0 Y:thisPoint.x/8.0 withKey:@"density"];
        }
        else if ( [self point:thisPoint isInside: quadrant[3]] ) 
        {
            if ( thisPoint.x > IPAD_WIDTH - thresh ) [osc sendDrumControlX:thisPoint.y/11.0 Y:thisPoint.x/8.0 withKey:@"random"];
        }
    } 
    
    if MELODY_AND_CHORDS_MODE
    {
        // this will just count new touches to the screen
        for ( UITouch * touch in touches )
        {
            CGPoint thisPoint = [touch locationInView:self.view];
            if ( [self point:thisPoint isInside: quadrant[2]] ) 
            {
                if ( [touches count] == 1 ) 
                {
                    [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:thisPoint size:CGSizeMake(100.0,100.0) color:[UIColor greenColor] delegate:self];
                    [osc sendValue:2.0 withKey:@"chord"];
                }
                
            }
            else if ( [self point:thisPoint isInside: quadrant[3]] ) 
            {
                if ( [touches count] == 1 ) 
                {
                    [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:thisPoint size:CGSizeMake(100.0,100.0) color:[UIColor greenColor] delegate:self];
                    [osc sendValue:3.0 withKey:@"chord"];
                }
            }
        }    
    }
    else // BASS_MODE
    {
        float xtouch = 0; float ytouch = 0;
        for ( UITouch * touch in [event allTouches] )
        {
            CGPoint thisPoint = [touch locationInView:self.view];
            xtouch += thisPoint.x; ytouch += thisPoint.y;
            [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:thisPoint size:CGSizeMake(10.0,10.0) color:[UIColor yellowColor] delegate:self];
        }
        xtouch /= [[event allTouches] count]; ytouch /= [[event allTouches] count];
        CGPoint tapPoint = CGPointMake(xtouch / self.view.bounds.size.width, 1 - (ytouch / self.view.bounds.size.height));
        if ( prevTotal == 0 && totaltouches == 1)
        {
            [osc sendPoint:tapPoint withKey:@"bassTouchBegan"];
        }
        [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:CGPointMake(xtouch, ytouch) size:CGSizeMake(70.0,70.0) color:[UIColor orangeColor] delegate:self];

    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    quadTouches[0] = quadTouches[1] = quadTouches[2] = quadTouches[3] = 0;
    for ( UITouch * touch in [event allTouches] )
    {
        CGPoint thisPoint = [touch locationInView:self.view];
        if ( [self point:thisPoint isInside: quadrant[0]] ) 
            quadTouches[0]++;
        else if ( [self point:thisPoint isInside: quadrant[1]] ) 
            quadTouches[1]++;
        else if ( [self point:thisPoint isInside: quadrant[2]] ) 
            quadTouches[2]++;
        else if ( [self point:thisPoint isInside: quadrant[3]] ) 
            quadTouches[3]++;
    }
    
    totaltouches = quadTouches[0] + quadTouches[1] + quadTouches[2] + quadTouches[3];

    // control drums
    if ( [touches count] < 3 )
    {
        for ( UITouch * touch in touches )
        {
            CGPoint thisPoint = [touch locationInView:self.view];
            [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:thisPoint size:CGSizeMake(10.0,10.0) color:[UIColor yellowColor] delegate:self];
            if ( [self point:thisPoint isInside: quadrant[0]] ) 
            {
                if ( thisPoint.x > IPAD_WIDTH - thresh ) [osc sendDrumControlX:thisPoint.y/11.0 Y:thisPoint.x/8.0 withKey:@"random"];
            }
            else if ( [self point:thisPoint isInside: quadrant[1]] ) 
            {
                if ( thisPoint.x < thresh ) [osc sendDrumControlX:thisPoint.y/11.0 Y:thisPoint.x/8.0 withKey:@"density"];
            }
            else if ( [self point:thisPoint isInside: quadrant[2]] ) 
            {
                if ( thisPoint.x < thresh ) [osc sendDrumControlX:thisPoint.y/11.0 Y:thisPoint.x/8.0 withKey:@"density"];
            }
            else if ( [self point:thisPoint isInside: quadrant[3]] ) 
            {
                if ( thisPoint.x > IPAD_WIDTH - thresh ) [osc sendDrumControlX:thisPoint.y/11.0 Y:thisPoint.x/8.0 withKey:@"random"];
            }
        } 
    }
    if ( [[event allTouches] count] == 4 )
    {
        float xtouch = 0; float ytouch = 0;
        for ( UITouch * touch in [event allTouches] )
        {
            CGPoint thisPoint = [touch locationInView:self.view];
            xtouch += thisPoint.x; ytouch += thisPoint.y;
            [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:thisPoint size:CGSizeMake(10.0,10.0) color:[UIColor yellowColor] delegate:self];
        }
        xtouch *= 0.25; ytouch *= 0.25;
        [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:CGPointMake(xtouch, ytouch) size:CGSizeMake(10.0,10.0) color:[UIColor greenColor] delegate:self];
        [osc sendDrumControlX:ytouch/11.0 Y:xtouch/8.0 withKey:@"glitch"];
    }
    if ( [[event allTouches] count] == 3 )
    {
        float xtouch = 0; float ytouch = 0;
        for ( UITouch * touch in [event allTouches] )
        {
            CGPoint thisPoint = [touch locationInView:self.view];
            xtouch += thisPoint.x; ytouch += thisPoint.y;
            [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:thisPoint size:CGSizeMake(10.0,10.0) color:[UIColor yellowColor] delegate:self];
        }
        xtouch *= 0.3333; ytouch *= 0.3333;
        [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:CGPointMake(xtouch, ytouch) size:CGSizeMake(10.0,10.0) color:[UIColor greenColor] delegate:self];
        [osc sendDrumControlX:ytouch/11.0 Y:xtouch/8.0 withKey:@"stutter"];
    }
    
    if MELODY_AND_CHORDS_MODE
    {
        if ( [touches count] == 1 )
        {
            [self processStrings:[[touches anyObject] locationInView:self.view]];
        }
        
    }
    else // BASS_MODE
    {
        float xtouch = 0; float ytouch = 0;
        for ( UITouch * touch in [event allTouches] )
        {
            CGPoint thisPoint = [touch locationInView:self.view];
            xtouch += thisPoint.x; ytouch += thisPoint.y;
            //[[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:thisPoint size:CGSizeMake(10.0,10.0) color:[UIColor yellowColor] delegate:self];
        }
        xtouch /= [[event allTouches] count]; ytouch /= [[event allTouches] count];
        CGPoint tapPoint = CGPointMake(xtouch / self.view.bounds.size.width, 1 - (ytouch / self.view.bounds.size.height));
        [osc sendPoint:tapPoint withKey:@"bassTouchMoved"];

        [[feedborkDoodad alloc] initWithImageNamed:@"particle.png" superview:self.view center:CGPointMake(xtouch, ytouch) size:CGSizeMake(10.0,10.0) color:[UIColor orangeColor] delegate:self];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    for ( UITouch * touch in touches )
    {
        CGPoint thisPoint = [touch locationInView:self.view];
        if ( [self point:thisPoint isInside: quadrant[0]] ) 
            quadTouches[0]--;
        else if ( [self point:thisPoint isInside: quadrant[1]] ) 
            quadTouches[1]--;
        else if ( [self point:thisPoint isInside: quadrant[2]] ) 
            quadTouches[2]--;
        else if ( [self point:thisPoint isInside: quadrant[3]] ) 
            quadTouches[3]--;
    }
    
    totaltouches = quadTouches[0] + quadTouches[1] + quadTouches[2] + quadTouches[3];
    
    // control drums
    // see if we've lifted fingers off
    if ( [[event allTouches] count] != 4 || [touches count] == 4 )
    {
        [osc sendDrumControlX:-10.0 Y:0.0 withKey:@"glitch"];
    }
    if ( [[event allTouches] count] != 3 || [touches count] == 3 )
    {
        [osc sendDrumControlX:-10.0 Y:0.0 withKey:@"stutter"];
    }
    
    if MELODY_AND_CHORDS_MODE
    {
        [osc sendPoint:CGPointMake(-1.0, 0.0) withKey:@"string"];
    }
    else // BASS_MODE
    {
        if ( totaltouches == 0 ) 
        {
            [osc sendPoint:CGPointMake(0.0, 0.0) withKey:@"bassTouchEnded"];
        }

    }
}

@end

@implementation UIToggleButton
@synthesize isOn;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( (self = [super initWithCoder:aDecoder]) )
    {
        indicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"switchUp.png"]];
        indicator.frame = CGRectMake(0.0, 0.0, self.frame.size.height/2.5, self.frame.size.height/2.5);
        indicator.center = CGPointMake(indicator.frame.size.width, self.frame.size.height/2.0);
        [self addSubview:indicator];
        isOn = NO;
    }
    return self;
}

- (void)turnOn
{
    indicator.image = [UIImage imageNamed:@"switchDown.png"];
    isOn = YES;
}

- (void)turnOff
{
    indicator.image = [UIImage imageNamed:@"switchUp.png"];
    isOn = NO;
}

- (void)updateState
{
    if (isOn) [self turnOff];
    else [self turnOn];
}

- (void)dealloc
{
    [indicator release];
    [super dealloc];
}
@end
