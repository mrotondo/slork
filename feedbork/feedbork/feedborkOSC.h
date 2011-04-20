//
//  feedborkOSC.h
//  feedbork
//
//  Created by Nick Kruge on 4/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
class MoNet;
@protocol feedborkOSCdelegate 

- (void)makeDoodad:(CGPoint)_center size:(float)_size image:(NSString*)_image color:(UIColor*)_color;

@end

@interface feedborkOSC : NSObject {
    NSString *IP;
    int port;
    MoNet * recv;
}

@property(nonatomic,retain) id <feedborkOSCdelegate> delegate;

- (id)initWithIP:(NSString*)_IP portOut:(int)_porto portIn:(int)_porti;
- (void)changeIP:(NSString*)_IP;
- (void)sendValue:(float)value withKey:(NSString*)key;
- (void)sendDrumControlX:(float)xval Y:(float)yval withKey:(NSString*)key;
- (void)broadcastIP;

@end
