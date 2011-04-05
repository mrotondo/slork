//
//  feedborkOSC.h
//  feedbork
//
//  Created by Nick Kruge on 4/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface feedborkOSC : NSObject {
    NSString *IP;
    int port;
}

- (id)initWithIP:(NSString*)_IP port:(int)_port;
- (void)changeIP:(NSString*)_IP;
- (void)sendValue:(float)value withKey:(NSString*)key;

@end
