//
//  feedborkDoodads.mm
//  feedbork
//
//  Created by Nick Kruge on 4/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "feedborkDoodad.h"


@implementation feedborkDoodad
@synthesize delegate;

- (void) animateMe:(CGPoint) originalCenter
{
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{ 
                         CGPoint center = self.center;
                         center.y += 60;
                         self.center = center;
                     } 
                     completion:^(BOOL finished){
                         
                         [UIView animateWithDuration:1.0
                                               delay:0.0
                                             options:UIViewAnimationOptionAllowUserInteraction
                                          animations:^{ 
                                              self.center = originalCenter;
                                          } 
                                          completion:^(BOOL finished){
                                              [self.delegate killMe:self];
                                          }];
                         
                     }];
}

@end
