//
//  feedborkDoodads.mm
//  feedbork
//
//  Created by Nick Kruge on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "feedborkDoodad.h"
#import <QuartzCore/QuartzCore.h>

@implementation feedborkDoodad
@synthesize delegate;

- (UIImage*)createParticle:(UIImage*)maskImage withColor:(UIColor*)_color
{

    [self setBackgroundColor:_color];
    UIGraphicsBeginImageContext(self.bounds.size);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self setBackgroundColor:[UIColor clearColor]];
        
    CGImageRef maskRef = maskImage.CGImage;
    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask([viewImage CGImage], mask);
    CGImageRelease(mask);
    UIImage* retImage= [UIImage imageWithCGImage:masked];
    CGImageRelease(masked);
    return retImage;

}

// override init to include setting the IP and port for OSC
- (id)initWithImageNamed:(NSString*)_imageName superview:(UIView*)sview center:(CGPoint)_center size:(CGSize)_size color:(UIColor*)_color delegate:(id)_delegate
{
    if ( (self = [super init]) )
    {
        self.frame = CGRectMake(10.0, 10.0, _size.width, _size.height);
        self.image = [self createParticle:[UIImage imageNamed:_imageName] withColor:_color];
        [sview addSubview:self];
        self.center = _center;
        [self animateMe:_center];
        delegate = _delegate;
    }
    
    return self;
}



- (void) animateMe:(CGPoint) originalCenter
{
    self.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration:0.03
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{ 
                         self.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(5.5, 5.5),CGAffineTransformMakeRotation((rand()%10 - 5)*360.0));
                         self.alpha = 1.0;
                         
                     } 
                     completion:^(BOOL finished){
                         [UIView animateWithDuration:1.0
                                               delay:0.0
                                             options:UIViewAnimationOptionAllowUserInteraction
                                          animations:^{ 
                                              self.transform = CGAffineTransformMakeScale(0.1, 0.1);
                                              self.alpha = 0.0;
                                          } 
                                          completion:^(BOOL finished){
                                              [self.delegate killMe:self];
                                          }];
                     }];
}

@end
