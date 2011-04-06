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

// override init to include setting the IP and port for OSC
- (id)initWithIP:(NSString*)_IP port:(int)_port
{
    if ( (self = [super init]) )
    {
        IP = [_IP copy];
        port = _port;
    }
    
    return self;
}

// change the IP if necessary
- (void)changeIP:(NSString*)_IP
{
    IP = _IP;
}

// send a single float to the waiting, friendly computer
- (void)sendValue:(float)value withKey:(NSString*)key
{
    static char types[1] = {'f'};
    
    NSString *keyWithSlash = [NSString stringWithFormat:@"/%@",key];
    
    MoNet::sendMessage([IP UTF8String],
                       port, [keyWithSlash UTF8String], types, 1, value);
}

- (void)dealloc
{
    [IP release];
    [super dealloc];
}
@end
