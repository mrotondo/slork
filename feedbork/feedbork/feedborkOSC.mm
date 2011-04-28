//
//  feedborkOSC.mm
//  feedbork
//
//  Created by Nick Kruge on 4/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "feedborkOSC.h"
#import "mo_net.h"
#import "feedborkAppDelegate.h"
#import "feedborkViewController.h"

@implementation feedborkOSC
@synthesize delegate;
// entry point for OSC source message callback
void drum_callback( osc::ReceivedMessageArgumentStream & oscin, void * data );

// override init to include setting the IP and port for OSC
- (id)initWithIP:(NSString*)_IP portOut:(int)_porto portIn:(int)_porti
{
    if ( (self = [super init]) )
    {
        IP = [_IP copy];
        port = _porto;
        // set mo_net to receive
        MoNet::addAddressCallback( "/drum", drum_callback, self );
        // set the incoming port
        MoNet::setListeningPort( _porti );
        // start the listener
        MoNet::startListening();
        
        [self broadcastIP];
        
        [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateColor:) userInfo:nil repeats:YES];
    }
    
    return self;
}

// change the IP if necessary
- (void)changeIP:(NSString*)_IP
{
    IP = _IP;
    [self broadcastIP];
}

// send a single float to the waiting, friendly computer
- (void)sendValue:(float)value withKey:(NSString*)key
{
    static char types[1] = {'f'};
    
    NSString *keyWithSlash = [NSString stringWithFormat:@"/%@",key];
    
    MoNet::sendMessage([IP UTF8String],
                       port, [keyWithSlash UTF8String], types, 1, value);
}

- (void)sendPoint:(CGPoint)point withKey:(NSString*)key
{
    static char types[2] = {'f','f'};
    
    NSString *keyWithSlash = [NSString stringWithFormat:@"/%@",key];
    
    MoNet::sendMessage([IP UTF8String],
                       port, [keyWithSlash UTF8String], types, 2, point.x, point.y);
}

- (void)sendDrumControlX:(float)xval Y:(float)yval withKey:(NSString*)key;
{
    static char types[3] = {'s','f','f'};
    
    NSString *keyWithSlash = [NSString stringWithFormat:@"/drumcontrol",key];
    
    MoNet::sendMessage([IP UTF8String],
                       port, [keyWithSlash UTF8String], types, 3, [key UTF8String], xval, yval);
}
     
- (void)broadcastIP
{

    static char types[1] = {'s'};
    NSString *key = @"/IP";
    std::string myIP = MoNet::getMyIPaddress();
    
    const char * ip = myIP.c_str();
    
    NSLog(@"myip: %s", ip);
    
    MoNet::sendMessage([IP UTF8String],
                       port, [key UTF8String], types, 1, ip);
 
}

float r = 0.0;
float g = 0.0;
float b = 1.0;

void drum_callback( osc::ReceivedMessageArgumentStream & oscin, void * data )
{
    feedborkOSC * me = (feedborkOSC*)data;
    
    //me = NULL; // just to stop warnings
    
    const char* drumname;
    float vel;
    oscin >> drumname >> vel;
    //NSLog(@"vel: %s %f",drumname, vel);
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSString * dname = [NSString stringWithCString:drumname encoding:NSStringEncodingConversionAllowLossy];
    if ( [dname isEqualToString:@"kick"] )
        [me.delegate makeDoodad:CGPointMake(518.0, 300.0) size:vel image:@"flare3.png" color:[UIColor colorWithRed:r green:g blue:b/5.0 alpha:1.0]];
    else if ( [dname isEqualToString:@"snare"] )
        [me.delegate makeDoodad:CGPointMake(250.0, 300.0) size:vel image:@"flare3.png" color:[UIColor colorWithRed:r green:g blue:2*b/5.0 alpha:1.0]];
    else if ( [dname isEqualToString:@"hihat"] )
        [me.delegate makeDoodad:CGPointMake(518.0, 824.0) size:vel image:@"flare3.png" color:[UIColor colorWithRed:r green:g blue:3*b/5.0 alpha:1.0]];
    else if ( [dname isEqualToString:@"kickhard"] )
        [me.delegate makeDoodad:CGPointMake(250.0, 824.0) size:vel image:@"flare3.png" color:[UIColor colorWithRed:r green:g blue:4*b/5.0 alpha:1.0]];
    else if ( [dname isEqualToString:@"snarehard"] )
        [me.delegate makeDoodad:CGPointMake(384.0, 562.0) size:vel image:@"flare3.png" color:[UIColor colorWithRed:r green:g blue:1.0 alpha:1.0]];
//    else if ( [dname isEqualToString:@"cym1"] )
//        [me.delegate makeDoodad:CGPointMake(150.0, 800.0) size:vel image:@"shine1.png" color:[UIColor lightGrayColor]];
//    else if ( [dname isEqualToString:@"cym2"] )
//        [me.delegate makeDoodad:CGPointMake(300.0, 800.0) size:vel image:@"shine2.png" color:[UIColor cyanColor]];
//    else if ( [dname isEqualToString:@"cym3"] )
//        [me.delegate makeDoodad:CGPointMake(450.0, 800.0) size:vel image:@"shine1.png" color:[UIColor magentaColor]];
//    else if ( [dname isEqualToString:@"cym4"] )
//        [me.delegate makeDoodad:CGPointMake(600.0, 800.0) size:vel image:@"shine2.png" color:[UIColor brownColor]];
    else if ( [dname isEqualToString:@"circle"] )
    {
        feedborkAppDelegate * app = (feedborkAppDelegate*)[[UIApplication sharedApplication] delegate];
        [app.viewController performSelectorOnMainThread:@selector(circle:) withObject:nil waitUntilDone:NO];
    }
    else if ( [dname isEqualToString:@"fade"] )
    {
        NSLog(@"fade out");
        feedborkAppDelegate * app = (feedborkAppDelegate*)[[UIApplication sharedApplication] delegate];
        [app.viewController performSelectorOnMainThread:@selector(fadeBackground) withObject:nil waitUntilDone:NO];
    }
    [pool drain];
}

- (void)updateColor:(NSTimer*)timer
{
    r += 0.01;
    g += 0.00052;
    
    if ( r > 1.0 ) r = 0.0;
    if ( g > 0.1 ) g = 0.0;
}

- (void)dealloc
{
    [IP release];
    [super dealloc];
}
@end
