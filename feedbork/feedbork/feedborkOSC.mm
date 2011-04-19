//
//  feedborkOSC.mm
//  feedbork
//
//  Created by Nick Kruge on 4/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "feedborkOSC.h"
#import "mo_net.h"

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

// send a single float to the waiting, friendly computer
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

void drum_callback( osc::ReceivedMessageArgumentStream & oscin, void * data )
{
    feedborkOSC * me = (feedborkOSC*)data;
    
    //me = NULL; // just to stop warnings
    
    const char* drumname;
    float vel;
    oscin >> drumname >> vel;
    //NSLog(@"test: %s %f",drumname, test);
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSString * dname = [NSString stringWithCString:drumname encoding:NSStringEncodingConversionAllowLossy];
    if ( [dname isEqualToString:@"kick"] )
        [me.delegate makeDoodad:CGPointMake(518.0, 300.0) size:vel image:@"flare3.png" color:[UIColor blueColor]];
    else if ( [dname isEqualToString:@"snare"] )
        [me.delegate makeDoodad:CGPointMake(250.0, 300.0) size:vel image:@"flare3.png" color:[UIColor redColor]];
    else if ( [dname isEqualToString:@"hihat"] )
        [me.delegate makeDoodad:CGPointMake(518.0, 824.0) size:vel image:@"flare3.png" color:[UIColor yellowColor]];
    else if ( [dname isEqualToString:@"kickhard"] )
        [me.delegate makeDoodad:CGPointMake(250.0, 824.0) size:vel image:@"flare3.png" color:[UIColor greenColor]];
    else if ( [dname isEqualToString:@"snarehard"] )
        [me.delegate makeDoodad:CGPointMake(384.0, 562.0) size:vel image:@"flare3.png" color:[UIColor purpleColor]];
    else if ( [dname isEqualToString:@"cym1"] )
        [me.delegate makeDoodad:CGPointMake(150.0, 800.0) size:vel image:@"shine1.png" color:[UIColor lightGrayColor]];
    else if ( [dname isEqualToString:@"cym2"] )
        [me.delegate makeDoodad:CGPointMake(300.0, 800.0) size:vel image:@"shine2.png" color:[UIColor cyanColor]];
    else if ( [dname isEqualToString:@"cym3"] )
        [me.delegate makeDoodad:CGPointMake(450.0, 800.0) size:vel image:@"shine1.png" color:[UIColor magentaColor]];
    else if ( [dname isEqualToString:@"cym4"] )
        [me.delegate makeDoodad:CGPointMake(600.0, 800.0) size:vel image:@"shine2.png" color:[UIColor brownColor]];
    [pool drain];
}

- (void)dealloc
{
    [IP release];
    [super dealloc];
}
@end
