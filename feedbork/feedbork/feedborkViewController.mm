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
    //captureOutput.minFrameDuration = CMTimeMake(1, 10);

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

    captureSession.sessionPreset = AVCaptureSessionPresetMedium;

    maskView = [[UIView alloc] initWithFrame:self.view.bounds];
    [maskView setBackgroundColor:[UIColor blackColor]];
    maskView.alpha = 0.0;
    [self.view addSubview:maskView];
    
    self.imageView = [[UIImageView alloc] init];
	self.imageView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width - borderSlider.value/2.0, self.view.bounds.size.height - borderSlider.value/2.0);
    self.imageView.center = self.view.center;
    [self.view addSubview:self.imageView];
    
    // bring menu to front again and then hide it
    [self.view bringSubviewToFront:menuView];
    menuView.transform = CGAffineTransformMakeTranslation(-1000.0, 0.0);
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession: self.captureSession];
	self.previewLayer.frame = CGRectMake(0, 0, 76, 102);
	self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[menuView.layer addSublayer: self.previewLayer];
    
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
    
    // setup colors
    colorThresh[0] = colorThresh[1] = colorThresh[2] = 128;
    myColor = 2;
    myFriendsColor = 1;
    
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

// color picker functions
- (IBAction)chooseMyColor:(UIButton*)sender
{
    myColor = sender.tag;
    [self.view setBackgroundColor:sender.backgroundColor];
    myColorPicker.center = sender.center;
}

- (IBAction)chooseMyFriendsColor:(UIButton*)sender
{
    myFriendsColor = sender.tag;
    myFriendsColorPicker.center = sender.center;
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

- (IBAction)changeColorThreshold:(UISlider*)slider
{
    //NSLog(@"moving slider: %d with value %f",slider.tag,slider.value);
    colorThresh[slider.tag] = slider.value;
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

    // find the current origin for the raw data
    //uint8_t *startingPoint = img_color->imageData;
    // iterate through the data in chunks of 4 (BGRA) discarding A
    for ( int i = 0; i < width * height * 4; i+=4 )
    {
        // Grab the raw memory addresses
        uint8_t *myPtr = (baseAddress + i + myColor);
        uint8_t *myFriendsPtr = (baseAddress + i + myFriendsColor);
        uint8_t *otherPtr = (baseAddress + i + 3 - (myColor + myFriendsColor));
        
        //*B = 0;
        //*G = 0;
        //*R = 0;
        //*A = 0;
       
        // Now change contents at that point in memory----
        // binary bin for each color channel (except alpha)
//        *R = ( *R > colorThresh[0]*255) ? 255 : 0;
//        *G = ( *G > colorThresh[1]*255) ? 255 : 0;
//        *B = ( *B > colorThresh[2]*255) ? 255 : 0;
        
//        *R = (char)((float)*R * colorThresh[0]);
//        *G = (char)((float)*G * colorThresh[1]);
//        *B = (char)((float)*B * colorThresh[2]);
        
        // exclusive or some stuff
//        if ( *R && *G ) { *R = *G = 0;}
//        if ( *R && *B ) { *R = *B = 0;}
//        if ( *B && *G ) { *B = *G = 0;}
        
        // target red
        // Now change contents at that point in memory----
        // binary bin for each color channel (except alpha)
        *myPtr = ( *myPtr > colorThresh[myColor]) ? 255 : 0;
        *myFriendsPtr = ( *myFriendsPtr > colorThresh[myFriendsColor]) ? 255 : 0;
        
        //        *R = (char)((float)*R * colorThresh[0]);
        //        *G = (char)((float)*G * colorThresh[1]);
        //        *B = (char)((float)*B * colorThresh[2]);
        
        //if ( i == 200) NSLog(@"%d %d %d", (uint8_t)*R, (uint8_t)*G, (uint8_t)*B);
        
        if (*myPtr == 255 && *myFriendsPtr == 255 ||
            *myPtr == 255 && *otherPtr > colorThresh[3 - (myColor + myFriendsColor)] ||
            *myFriendsPtr == 255 && *otherPtr > colorThresh[3 - (myColor + myFriendsColor)]
            ) {
            *myPtr = 0;
            *myFriendsPtr = 0;
        }
        *otherPtr = 0;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext); 
    
    CGContextRelease(newContext); 
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationUp];
    IplImage *img_color = [self CreateIplImageFromUIImage:image];
        
    IplImage *img_greyscale = cvCreateImage(cvGetSize(img_color), IPL_DEPTH_8U, 1);
    cvCvtColor(img_color, img_greyscale, CV_BGR2GRAY);
    IplImage *img_lines = cvCreateImage(cvGetSize(img_greyscale), IPL_DEPTH_8U, 1);
    cvCanny(img_greyscale, img_lines, 50, 100, 3);
    
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
        cvLine( img_color, line[0], line[1], CV_RGB(255,0,0), 3, 8 );
        
        angle = fmod(fabs(atan2f(p1.y - p2.y, p1.x - p2.x)), M_PI / 2.0);
        [osc sendValue:angle * 400 withKey:@"freq"];
        [osc sendValue:sqrt(max_line_length) / 2000 withKey:@"cutoff"];
    } else {
        [osc sendValue:0 withKey:@"freq"];
        [osc sendValue:0 withKey:@"cutoff"];
    }

    //IplImage *img_threshold = cvCreateImage(cvGetSize(img_greyscale), IPL_DEPTH_8U, 1);
    //cvThreshold(img_greyscale, img_threshold, 190, 255, CV_THRESH_BINARY);
//    
//    CvMemStorage* contour_storage = cvCreateMemStorage(0);
//    CvSeq* contours;
//    int numContours = cvFindContours( img_threshold , contour_storage, &contours, sizeof(CvContour),
//                                     CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE, cvPoint(0,0) );
//    //NSLog(@"Got %d contours!", numContours);
//    
//    //CvSeq* result;
//    int contour_index = 0;
//    //[osc sendValue:numContours * 10 withKey:@"test"];
//
//    while( contours )
//    {
//        //NSLog(@"Contour %d has a total of %d", contour_index, contours->total);
//        
//        if (contours->total > 20)
//        {
//            
//            CvPoint* p1;
//            CvPoint* p2;
//            for (int seq_index = 1; seq_index < contours->total; seq_index++) {
//                p1 = (CvPoint*)cvGetSeqElem( contours, seq_index );
//                p2 = (CvPoint*)cvGetSeqElem( contours, seq_index - 1 );
//            }
//        }
////        result = cvApproxPoly(contours, sizeof(CvContour), contour_storage,
////                              CV_POLY_APPROX_DP, cvContourPerimeter(contours)*0.02, 0 );
////
////        int i = 0;
////        
////        NSLog(@"Contour %d has a total of %d", contour_index, result->total);
////        NSLog(@"Contour %d has an area of %f", contour_index, fabs(cvContourArea(result,CV_WHOLE_SEQ)));
////        if (cvCheckContourConvexity(result)) {
////            NSLog(@"Contour %d is convex", contour_index);
////        } else {
////            NSLog(@"Contour %d is not convex", contour_index);
////        }
////        
////        if( result->total > 4 &&
////           fabs(cvContourArea(result,CV_WHOLE_SEQ)) > 300 &&
////           cvCheckContourConvexity(result) )
////        {
////            i++;            
////        }
////        
////        NSLog(@"Got some squares-ish: %d", i);
//        
//        // take the next contour
//        contour_index++;
//        contours = contours->h_next;
//    }
//    
////    if (num_angles > 0)
////        NSLog(@"Average angle is %f", angle_sum / num_angles);
////    else
////        NSLog(@"No sufficiently large contours found!");
//    
//    // Convert black and whilte to 24bit image then convert to UIImage to show
//    IplImage *ipl_result = cvCreateImage(cvGetSize(img_threshold), IPL_DEPTH_8U, 3);
//    for(int y = 0; y < img_threshold->height; y++) {
//        for(int x = 0; x < img_threshold->width; x++) {
//            char *p = ipl_result->imageData + y * ipl_result->widthStep + x * 3;
//            *p = *(p+1) = *(p+2) = img_threshold->imageData[y * img_threshold->widthStep + x];
//        }
//    }

    UIImage * rotatedImage = [self rotate:[self UIImageFromIplImage:img_color] to:UIImageOrientationRightMirrored];
    

    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:rotatedImage waitUntilDone:YES];

//    cvReleaseMemStorage(&contour_storage);
    cvReleaseMemStorage(&line_storage);
//    cvReleaseImage(&img_threshold);
    cvReleaseImage(&img_lines);
    cvReleaseImage(&img_color);
    cvReleaseImage(&img_greyscale);
//    cvReleaseImage(&ipl_result);   
    
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

@implementation UIToggleButton
@synthesize isOn;

- (id) initWithCoder:(NSCoder *)aDecoder
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
