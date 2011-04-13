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
// entry point for OSC source message callback
void osc_callback( osc::ReceivedMessageArgumentStream & oscin, void * data );

// override init to include setting the IP and port for OSC
- (id)initWithIP:(NSString*)_IP portOut:(int)_porto portIn:(int)_porti
{
    if ( (self = [super init]) )
    {
        IP = [_IP copy];
        port = _porto;
        // set mo_net to receive
        MoNet::addAddressCallback( "/test", osc_callback, self );
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

void osc_callback( osc::ReceivedMessageArgumentStream & oscin, void * data )
{
    feedborkOSC * me = (feedborkOSC*)data;
    
    me = NULL; // just to stop warnings
    
    float test;
    oscin >> test;
    NSLog(@"test: %f",test);
}

- (void)dealloc
{
    [IP release];
    [super dealloc];
}
@end
