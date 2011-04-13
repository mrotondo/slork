//
//  feedborkOSC.h
//  feedbork
//
//  Created by Nick Kruge on 4/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
class MoNet;

@interface feedborkOSC : NSObject {
    NSString *IP;
    int port;
    
    MoNet * recv;
}

- (id)initWithIP:(NSString*)_IP portOut:(int)_porto portIn:(int)_porti;
- (void)changeIP:(NSString*)_IP;
- (void)sendValue:(float)value withKey:(NSString*)key;
- (void)broadcastIP;

@end
